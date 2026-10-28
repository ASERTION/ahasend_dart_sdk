import 'package:ahasend/ahasend.dart';
import 'package:test/test.dart';

import 'helpers.dart';

Map<String, Object?> apiKeyJson({String id = 'k-1'}) => {
  'object': 'api_key',
  'id': id,
  'created_at': '2024-01-01T00:00:00Z',
  'updated_at': '2024-01-02T00:00:00Z',
  'last_used_at': null,
  'account_id': testAccountId,
  'label': 'Production API Key',
  'public_key': 'aha-pk-123',
  'scopes': [
    {
      'id': 's-1',
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
      'api_key_id': id,
      'scope': 'messages:send:all',
      'domain_id': null,
    },
    {
      'id': 's-2',
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
      'api_key_id': id,
      'scope': 'messages:send:{example.com}',
      'domain_id': 'd-1',
    },
  ],
  'ip_allow_list': ['203.0.113.0/24'],
};

void main() {
  test('apiKeys.list sends paging and decodes keys', () async {
    final api = FakeApi([
      FakeResponse(200, pageBody([apiKeyJson()], hasMore: true)),
    ]);
    final page = await api.client().apiKeys.list(limit: 5, after: 'c1');
    expect(api.last.method, 'GET');
    expect(api.last.url.path, accountPath('/api-keys'));
    expect(api.last.url.queryParameters, {'limit': '5', 'after': 'c1'});
    expect(api.last.headers['Idempotency-Key'], isNull);
    final key = page.data.single;
    expect(key.label, 'Production API Key');
    expect(key.lastUsedAt, isNull);
    expect(key.scopes.first.domainId, isNull);
    expect(key.scopes.last.domainId, 'd-1');
    expect(key.ipAllowList, ['203.0.113.0/24']);
    expect(key.createdAt, DateTime.utc(2024));
  });

  test('apiKeys.listAll follows cursors', () async {
    final api = FakeApi([
      FakeResponse(
        200,
        pageBody([apiKeyJson(id: '1')], hasMore: true, nextCursor: 'c2'),
      ),
      FakeResponse(200, pageBody([apiKeyJson(id: '2')])),
    ]);
    final ids = await api.client().apiKeys.listAll().map((k) => k.id).toList();
    expect(ids, ['1', '2']);
    expect(api.requests[1].url.queryParameters, {'after': 'c2'});
  });

  test('apiKeys.create is idempotent and returns the secret once', () async {
    final api = FakeApi([
      FakeResponse(201, {...apiKeyJson(), 'secret_key': 'aha-sk-SECRET'}),
    ]);
    final created = await api.client().apiKeys.create(
      const CreateApiKeyRequest(
        label: 'Production API Key',
        scopes: ['messages:send:all', 'domains:read'],
        ipAllowList: ['203.0.113.0/24', '198.51.100.7'],
      ),
    );
    expect(api.last.method, 'POST');
    expect(api.last.url.path, accountPath('/api-keys'));
    expect(api.last.headers['Idempotency-Key'], isNotEmpty);
    expect(api.lastJson, {
      'label': 'Production API Key',
      'scopes': ['messages:send:all', 'domains:read'],
      'ip_allow_list': ['203.0.113.0/24', '198.51.100.7'],
    });
    expect(created, isA<ApiKey>());
    expect(created.secretKey, 'aha-sk-SECRET');
    expect(created.toString(), isNot(contains('SECRET')));
    expect(created.toString(), contains('CreatedApiKey'));
    expect(created.toJson()['secret_key'], 'aha-sk-SECRET');
  });

  test('create omits the IP allow list when not given', () async {
    final api = FakeApi([
      FakeResponse(201, {...apiKeyJson(), 'secret_key': 's'}),
    ]);
    await api.client().apiKeys.create(
      const CreateApiKeyRequest(label: 'L', scopes: ['domains:read']),
    );
    expect(api.lastJson, {
      'label': 'L',
      'scopes': ['domains:read'],
    });
  });

  test('apiKeys.get encodes the key ID', () async {
    final api = FakeApi([FakeResponse(200, apiKeyJson())]);
    final key = await api.client().apiKeys.get('k/1');
    expect(api.last.method, 'GET');
    expect(api.last.url.path, accountPath('/api-keys/k%2F1'));
    expect(key.id, 'k-1');
    expect(key.toJson()['object'], 'api_key');
  });

  group('apiKeys.update', () {
    test('an empty request throws without sending', () async {
      final api = FakeApi();
      await expectLater(
        api.client().apiKeys.update('k-1', const UpdateApiKeyRequest()),
        throwsA(isA<InvalidUsageException>()),
      );
      expect(api.requests, isEmpty);
    });

    test('sends only the given fields with PUT', () async {
      final api = FakeApi([FakeResponse(200, apiKeyJson())]);
      await api.client().apiKeys.update(
        'k-1',
        const UpdateApiKeyRequest(label: 'Updated API Key'),
      );
      expect(api.last.method, 'PUT');
      expect(api.last.url.path, accountPath('/api-keys/k-1'));
      expect(api.last.headers['Idempotency-Key'], isNull);
      expect(api.lastJson, {'label': 'Updated API Key'});
    });

    test('an empty IP allow list clears it, null keeps it', () async {
      final api = FakeApi([FakeResponse(200, apiKeyJson())]);
      await api.client().apiKeys.update(
        'k-1',
        const UpdateApiKeyRequest(ipAllowList: []),
      );
      expect(api.lastJson, {'ip_allow_list': <String>[]});

      await api.client().apiKeys.update(
        'k-1',
        const UpdateApiKeyRequest(scopes: ['domains:read']),
      );
      expect(api.lastJson, {
        'scopes': ['domains:read'],
      });
    });
  });

  test('apiKeys.delete sends DELETE', () async {
    final api = FakeApi();
    final result = await api.client().apiKeys.delete('k-1');
    expect(api.last.method, 'DELETE');
    expect(api.last.url.path, accountPath('/api-keys/k-1'));
    expect(api.last.headers['Idempotency-Key'], isNull);
    expect(result.message, 'ok');
  });
}
