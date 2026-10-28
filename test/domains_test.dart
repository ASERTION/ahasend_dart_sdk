import 'package:ahasend/ahasend.dart';
import 'package:test/test.dart';

import 'helpers.dart';

Map<String, Object?> domainJson({
  String domain = 'example.com',
  String sendingType = 'transactional',
  bool paused = false,
  String? pauseReason,
}) => {
  'object': 'domain',
  'id': 'd-1',
  'created_at': '2024-01-01T00:00:00Z',
  'updated_at': '2024-01-02T00:00:00Z',
  'domain': domain,
  'account_id': testAccountId,
  'dns_records': [
    {
      'type': 'CNAME',
      'label': 'DKIM',
      'host': 'aha1._domainkey.example.com',
      'content': 'dkim.ahasend.com',
      'required': true,
      'propagated': false,
    },
    {
      'type': 'TXT',
      'host': 'example.com',
      'content': 'v=spf1 include:ahasend.com ~all',
      'required': false,
      'propagated': true,
    },
  ],
  'last_dns_check_at': '2024-01-02T00:00:00Z',
  'dns_valid': false,
  'tracking_subdomain': 'click',
  'return_path_subdomain': null,
  'subscription_subdomain': null,
  'media_subdomain': null,
  'dkim_rotation_interval_days': 45,
  'dkim_selector': null,
  'rotation_ready': true,
  'dsn_recipient': null,
  'sending_type': sendingType,
  'paused': paused,
  'paused_at': paused ? '2024-01-03T00:00:00Z' : null,
  'pause_reason': pauseReason,
};

void main() {
  group('domains.list', () {
    test('sends filters and decodes domains', () async {
      final api = FakeApi([
        FakeResponse(200, pageBody([domainJson()])),
      ]);
      final page = await api.client().domains.list(
        dnsValid: false,
        sendingType: DomainSendingType.marketing,
        limit: 20,
        before: 'b1',
      );
      expect(api.last.method, 'GET');
      expect(api.last.url.path, accountPath('/domains'));
      expect(api.last.url.queryParameters, {
        'dns_valid': 'false',
        'sending_type': 'marketing',
        'limit': '20',
        'before': 'b1',
      });
      final domain = page.data.single;
      expect(domain.domain, 'example.com');
      expect(domain.dnsValid, isFalse);
      expect(domain.dnsRecords.first.label, 'DKIM');
      expect(domain.dnsRecords.first.required, isTrue);
      expect(domain.dnsRecords.last.label, isNull);
      expect(domain.dnsRecords.last.propagated, isTrue);
      expect(domain.trackingSubdomain, 'click');
      expect(domain.returnPathSubdomain, isNull);
      expect(domain.dkimRotationIntervalDays, 45);
      expect(domain.sendingType, DomainSendingType.transactional);
      expect(domain.paused, isFalse);
      expect(domain.pausedAt, isNull);
      expect(domain.pauseReason, isNull);
      expect(domain.lastDnsCheckAt, DateTime.utc(2024, 1, 2));
    });

    test('listAll keeps filters across pages', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          pageBody([domainJson()], hasMore: true, nextCursor: 'c2'),
        ),
        FakeResponse(200, pageBody([domainJson(domain: 'b.com')])),
      ]);
      final names = await api
          .client()
          .domains
          .listAll(dnsValid: true)
          .map((d) => d.domain)
          .toList();
      expect(names, ['example.com', 'b.com']);
      expect(api.requests[1].url.queryParameters, {
        'dns_valid': 'true',
        'after': 'c2',
      });
    });
  });

  test('domains.create is idempotent and sends the body', () async {
    final api = FakeApi([FakeResponse(201, domainJson())]);
    final domain = await api.client().domains.create(
      const CreateDomainRequest(
        domain: 'example.com',
        trackingSubdomain: 'click',
        returnPathSubdomain: 'mail',
        subscriptionSubdomain: 'preferences',
        mediaSubdomain: 'media',
        dkimRotationIntervalDays: 45,
        sendingType: DomainSendingType.marketing,
      ),
    );
    expect(api.last.method, 'POST');
    expect(api.last.url.path, accountPath('/domains'));
    expect(api.last.headers['Idempotency-Key'], isNotEmpty);
    expect(api.lastJson, {
      'domain': 'example.com',
      'tracking_subdomain': 'click',
      'return_path_subdomain': 'mail',
      'subscription_subdomain': 'preferences',
      'media_subdomain': 'media',
      'dkim_rotation_interval_days': 45,
      'sending_type': 'marketing',
    });
    expect(domain.id, 'd-1');
  });

  test('domains.get decodes a paused domain', () async {
    final api = FakeApi([
      FakeResponse(200, domainJson(paused: true, pauseReason: 'bounce_rate')),
    ]);
    final domain = await api.client().domains.get('example.com');
    expect(api.last.method, 'GET');
    expect(api.last.url.path, accountPath('/domains/example.com'));
    expect(domain.paused, isTrue);
    expect(domain.pausedAt, DateTime.utc(2024, 1, 3));
    expect(domain.pauseReason, DomainPauseReason.bounceRate);
    expect(domain.toJson()['pause_reason'], 'bounce_rate');
    expect(domain.toJson()['object'], 'domain');
  });

  test('domains.update sends PUT without idempotency key', () async {
    final api = FakeApi([FakeResponse(200, domainJson())]);
    await api.client().domains.update(
      'example.com',
      const UpdateDomainRequest(
        dkimSelector: '',
        sendingType: DomainSendingType.transactional,
      ),
    );
    expect(api.last.method, 'PUT');
    expect(api.last.url.path, accountPath('/domains/example.com'));
    expect(api.last.headers['Idempotency-Key'], isNull);
    expect(api.lastJson, {
      'dkim_selector': '',
      'sending_type': 'transactional',
    });
  });

  test('domains.delete sends DELETE', () async {
    final api = FakeApi();
    final result = await api.client().domains.delete('example.com');
    expect(api.last.method, 'DELETE');
    expect(api.last.url.path, accountPath('/domains/example.com'));
    expect(result.message, 'ok');
  });

  test('domains.checkDns posts without body', () async {
    final api = FakeApi([FakeResponse(200, domainJson())]);
    final domain = await api.client().domains.checkDns('example.com');
    expect(api.last.method, 'POST');
    expect(api.last.url.path, accountPath('/domains/example.com/check-dns'));
    expect(api.last.headers['Idempotency-Key'], isNull);
    expect(api.last.body, isEmpty);
    expect(domain.domain, 'example.com');
  });

  test('unknown enum values are kept', () {
    expect(DomainSendingType('bulk').isKnown, isFalse);
    expect(DomainPauseReason('abuse').isKnown, isFalse);
    final domain = Domain.fromJson(
      domainJson(sendingType: 'bulk', paused: true, pauseReason: 'abuse'),
    );
    expect(domain.sendingType.value, 'bulk');
    expect(domain.pauseReason!.isKnown, isFalse);
    expect(domain.toJson()['pause_reason'], 'abuse');
  });
}
