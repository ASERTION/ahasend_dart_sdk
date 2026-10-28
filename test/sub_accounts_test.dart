import 'package:ahasend/ahasend.dart';
import 'package:test/test.dart';

import 'api_keys_test.dart' show apiKeyJson;
import 'domains_test.dart' show domainJson;
import 'helpers.dart';

const subId = '2f3c5d2a-9ef8-4c91-a5f4-79990c8c1d3a';

Map<String, Object?> subAccountJson({
  String id = subId,
  String status = 'active',
}) => {
  'object': 'sub_account',
  'id': id,
  'parent_account_id': testAccountId,
  'name': 'Acme Subsidiary',
  'website': 'acme.example.com',
  'status': status,
  'monthly_credit': 0,
  'created_at': '2024-01-01T00:00:00Z',
  'domain_count': 2,
  'member_count': 3,
  'last_activity_at': '2024-01-15T12:00:00Z',
};

String subPath(String rest) => accountPath('/sub-accounts/$subId$rest');

void main() {
  group('subAccounts', () {
    test('list decodes sub-accounts', () async {
      final api = FakeApi([
        FakeResponse(200, pageBody([subAccountJson()])),
      ]);
      final page = await api.client().subAccounts.list(limit: 50);
      expect(api.last.method, 'GET');
      expect(api.last.url.path, accountPath('/sub-accounts'));
      expect(api.last.url.queryParameters, {'limit': '50'});
      final sub = page.data.single;
      expect(sub.name, 'Acme Subsidiary');
      expect(sub.status, SubAccountStatus.active);
      expect(sub.domainCount, 2);
      expect(sub.memberCount, 3);
      expect(sub.lastActivityAt, DateTime.utc(2024, 1, 15, 12));
    });

    test('listAll follows cursors', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          pageBody([subAccountJson(id: '1')], hasMore: true, nextCursor: 'c2'),
        ),
        FakeResponse(200, pageBody([subAccountJson(id: '2')])),
      ]);
      final ids = await api
          .client()
          .subAccounts
          .listAll()
          .map((s) => s.id)
          .toList();
      expect(ids, ['1', '2']);
    });

    test('create is idempotent', () async {
      final api = FakeApi([FakeResponse(201, subAccountJson())]);
      await api.client().subAccounts.create(
        const CreateSubAccountRequest(
          name: 'Acme Subsidiary',
          website: 'acme.example.com',
          monthlyCredit: 0,
        ),
      );
      expect(api.last.method, 'POST');
      expect(api.last.url.path, accountPath('/sub-accounts'));
      expect(api.last.headers['Idempotency-Key'], isNotEmpty);
      expect(api.lastJson, {
        'name': 'Acme Subsidiary',
        'website': 'acme.example.com',
        'monthly_credit': 0,
      });
    });

    test('get, update and delete use the sub-account path', () async {
      final api = FakeApi([
        FakeResponse(200, subAccountJson()),
        FakeResponse(200, subAccountJson()),
        FakeResponse(200, {'message': 'deleted'}),
      ]);
      final client = api.client();

      final sub = await client.subAccounts.get(subId);
      expect(api.last.method, 'GET');
      expect(api.last.url.path, subPath(''));
      expect(sub.toJson()['object'], 'sub_account');

      await client.subAccounts.update(
        subId,
        const UpdateSubAccountRequest(monthlyCredit: 50000),
      );
      expect(api.last.method, 'PUT');
      expect(api.last.url.path, subPath(''));
      expect(api.last.headers['Idempotency-Key'], isNull);
      expect(api.lastJson, {'monthly_credit': 50000});

      final result = await client.subAccounts.delete(subId);
      expect(api.last.method, 'DELETE');
      expect(api.last.url.path, subPath(''));
      expect(result.message, 'deleted');
    });

    test('suspend and unsuspend', () async {
      final api = FakeApi([
        FakeResponse(200, subAccountJson(status: 'suspended')),
        FakeResponse(200, subAccountJson()),
      ]);
      final client = api.client();
      final suspended = await client.subAccounts.suspend(
        subId,
        const SuspendSubAccountRequest(
          reason: 'Customer requested temporary pause',
        ),
      );
      expect(api.last.method, 'POST');
      expect(api.last.url.path, subPath('/suspend'));
      expect(api.last.headers['Idempotency-Key'], isNull);
      expect(api.lastJson, {'reason': 'Customer requested temporary pause'});
      expect(suspended.status, SubAccountStatus.suspended);

      await client.subAccounts.unsuspend(subId);
      expect(api.last.method, 'POST');
      expect(api.last.url.path, subPath('/unsuspend'));
      expect(api.last.body, isEmpty);
    });

    test('unpauseDomain returns the domain', () async {
      final api = FakeApi([FakeResponse(200, domainJson())]);
      final domain = await api.client().subAccounts.unpauseDomain(
        subId,
        'example.com',
      );
      expect(api.last.method, 'POST');
      expect(api.last.url.path, subPath('/domains/example.com/unpause'));
      expect(api.last.headers['Idempotency-Key'], isNull);
      expect(domain.paused, isFalse);
    });

    test('usage decodes the breakdown', () async {
      final api = FakeApi([
        FakeResponse(200, {
          'billing_period': {
            'start': '2024-01-01T00:00:00Z',
            'end': '2024-02-01T00:00:00Z',
          },
          'currency': 'usd',
          'allocation_method': 'proportional',
          'allocation_note': 'allocated_cost is a proportional share.',
          'parent': {
            'account_id': testAccountId,
            'reception_count': 1000000,
            'allocated_cost': 20.0,
          },
          'sub_accounts': [
            {
              'account_id': subId,
              'name': 'Acme Subsidiary',
              'reception_count': 3000000,
              'allocated_cost': 60.5,
            },
          ],
          'removed_sub_accounts': {'reception_count': 0, 'allocated_cost': 0},
          'total': {'reception_count': 4000000, 'allocated_cost': 80},
        }),
      ]);
      final usage = await api.client().subAccounts.usage();
      expect(api.last.method, 'GET');
      expect(api.last.url.path, accountPath('/sub-accounts/usage'));
      expect(usage.billingPeriod.start, DateTime.utc(2024));
      expect(usage.billingPeriod.end, DateTime.utc(2024, 2));
      expect(usage.allocationMethod, SubAccountAllocationMethod.proportional);
      expect(usage.parent.accountId, testAccountId);
      expect(usage.subAccounts.single.name, 'Acme Subsidiary');
      expect(usage.subAccounts.single.allocatedCost, 60.5);
      expect(usage.removedSubAccounts.accountId, isNull);
      expect(usage.total.allocatedCost, 80.0);
      expect(usage.total.receptionCount, 4000000);
    });

    test('unknown enum values are kept', () {
      expect(
        SubAccountStatus('parent-suspended'),
        SubAccountStatus.parentSuspended,
      );
      expect(SubAccountStatus('frozen').isKnown, isFalse);
      expect(SubAccountAllocationMethod('flat').isKnown, isFalse);
    });
  });

  group('subAccounts.apiKeys', () {
    test('list and listAll', () async {
      final api = FakeApi([
        FakeResponse(200, pageBody([apiKeyJson()], hasMore: true)),
      ]);
      final page = await api.client().subAccounts.apiKeys.list(
        subId,
        after: 'c1',
      );
      expect(api.last.method, 'GET');
      expect(api.last.url.path, subPath('/api-keys'));
      expect(api.last.url.queryParameters, {'after': 'c1'});
      expect(page.data.single.id, 'k-1');

      final api2 = FakeApi([
        FakeResponse(
          200,
          pageBody([apiKeyJson(id: '1')], hasMore: true, nextCursor: 'c2'),
        ),
        FakeResponse(200, pageBody([apiKeyJson(id: '2')])),
      ]);
      final ids = await api2
          .client()
          .subAccounts
          .apiKeys
          .listAll(subId)
          .map((k) => k.id)
          .toList();
      expect(ids, ['1', '2']);
      expect(api2.requests[1].url.path, subPath('/api-keys'));
    });

    test('create is idempotent and returns the secret', () async {
      final api = FakeApi([
        FakeResponse(201, {...apiKeyJson(), 'secret_key': 'aha-sk-CHILD'}),
      ]);
      final created = await api.client().subAccounts.apiKeys.create(
        subId,
        const CreateApiKeyRequest(
          label: 'Bootstrap key',
          scopes: ['messages:send:all', 'domains:read'],
        ),
      );
      expect(api.last.method, 'POST');
      expect(api.last.url.path, subPath('/api-keys'));
      expect(api.last.headers['Idempotency-Key'], isNotEmpty);
      expect(api.lastJson, {
        'label': 'Bootstrap key',
        'scopes': ['messages:send:all', 'domains:read'],
      });
      expect(created.secretKey, 'aha-sk-CHILD');
      expect(created.toString(), isNot(contains('CHILD')));
    });

    test('get, update and delete', () async {
      final api = FakeApi([
        FakeResponse(200, apiKeyJson()),
        FakeResponse(200, apiKeyJson()),
        FakeResponse(200, {'message': 'ok'}),
      ]);
      final keys = api.client().subAccounts.apiKeys;

      await keys.get(subId, 'k-1');
      expect(api.last.method, 'GET');
      expect(api.last.url.path, subPath('/api-keys/k-1'));

      await keys.update(
        subId,
        'k-1',
        const UpdateApiKeyRequest(label: 'Renamed', ipAllowList: []),
      );
      expect(api.last.method, 'PUT');
      expect(api.last.url.path, subPath('/api-keys/k-1'));
      expect(api.last.headers['Idempotency-Key'], isNull);
      expect(api.lastJson, {'label': 'Renamed', 'ip_allow_list': <String>[]});

      final result = await keys.delete(subId, 'k-1');
      expect(api.last.method, 'DELETE');
      expect(api.last.url.path, subPath('/api-keys/k-1'));
      expect(result.message, 'ok');
    });
  });
}
