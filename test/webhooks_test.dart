import 'package:ahasend/ahasend.dart';
import 'package:test/test.dart';

import 'helpers.dart';

Map<String, Object?> webhookJson({String id = 'w-1'}) => {
  'object': 'webhook',
  'id': id,
  'created_at': '2024-05-06T09:00:00Z',
  'updated_at': '2024-05-06T10:00:00Z',
  'name': 'Delivery Webhook',
  'url': 'https://example.com/webhook',
  'enabled': true,
  'on_reception': false,
  'on_delivered': true,
  'on_transient_error': false,
  'on_failed': true,
  'on_bounced': true,
  'on_suppressed': false,
  'on_opened': false,
  'on_clicked': false,
  'on_suppression_created': false,
  'on_dns_error': true,
  'scope': 'scoped',
  'domains': ['example.com'],
  'success_count': 3,
  'error_count': 0,
  'errors_since_last_success': 0,
  'last_request_at': '2024-05-06T11:00:00Z',
};

void main() {
  group('webhooks.list', () {
    test('sends boolean filters and decodes the page', () async {
      final api = FakeApi([
        FakeResponse(200, pageBody([webhookJson()])),
      ]);
      final page = await api.client().webhooks.list(
        enabled: true,
        onDelivered: true,
        onDnsError: false,
        onSuppressionCreated: true,
        limit: 5,
        before: 'c0',
      );
      expect(api.last.method, 'GET');
      expect(api.last.url.path, accountPath('/webhooks'));
      expect(api.last.url.queryParameters, {
        'enabled': 'true',
        'on_delivered': 'true',
        'on_dns_error': 'false',
        'on_suppression_created': 'true',
        'limit': '5',
        'before': 'c0',
      });
      final webhook = page.data.single;
      expect(webhook.name, 'Delivery Webhook');
      expect(webhook.scope, WebhookScope.scoped);
      expect(webhook.domains, ['example.com']);
      expect(webhook.onDelivered, isTrue);
      expect(webhook.onOpened, isFalse);
      expect(webhook.onDnsError, isTrue);
      expect(webhook.lastRequestAt, DateTime.utc(2024, 5, 6, 11));
    });

    test('listAll follows cursors and keeps filters', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          pageBody([webhookJson(id: '1')], hasMore: true, nextCursor: 'c2'),
        ),
        FakeResponse(200, pageBody([webhookJson(id: '2')])),
      ]);
      final ids = await api
          .client()
          .webhooks
          .listAll(onBounced: true)
          .map((w) => w.id)
          .toList();
      expect(ids, ['1', '2']);
      expect(api.requests[1].url.queryParameters, {
        'on_bounced': 'true',
        'after': 'c2',
      });
    });
  });

  test('webhooks.create posts with an idempotency key', () async {
    final api = FakeApi([
      FakeResponse(201, {
        ...webhookJson(),
        'scope': 'global',
        'domains': <String>[],
        'secret': 'aha-whsec-xyz',
      }),
    ]);
    final created = await api.client().webhooks.create(
      const CreateWebhookRequest(
        name: 'Delivery Webhook',
        url: 'https://example.com/webhook',
        scope: WebhookScope.global,
        enabled: true,
        onDelivered: true,
      ),
    );
    expect(api.last.method, 'POST');
    expect(api.last.url.path, accountPath('/webhooks'));
    expect(api.last.headers['Idempotency-Key'], isNotEmpty);
    expect(api.lastJson, {
      'name': 'Delivery Webhook',
      'url': 'https://example.com/webhook',
      'scope': 'global',
      'enabled': true,
      'on_delivered': true,
    });
    expect(created.secret, 'aha-whsec-xyz');
    expect(created.scope, WebhookScope.global);
    expect(created.domains, isEmpty);
    expect(created.toString(), isNot(contains('aha-whsec-xyz')));
  });

  test('webhooks.get encodes the webhook ID', () async {
    final api = FakeApi([FakeResponse(200, webhookJson())]);
    final webhook = await api.client().webhooks.get('w 1');
    expect(api.last.url.path, accountPath('/webhooks/w%201'));
    expect(webhook.toJson()['scope'], 'scoped');
  });

  test('webhooks.update sends PUT and an empty domain list', () async {
    final api = FakeApi([FakeResponse(200, webhookJson())]);
    await api.client().webhooks.update(
      'w-1',
      const UpdateWebhookRequest(
        onOpened: true,
        scope: WebhookScope.scoped,
        domains: [],
      ),
    );
    expect(api.last.method, 'PUT');
    expect(api.last.url.path, accountPath('/webhooks/w-1'));
    expect(api.last.headers.containsKey('Idempotency-Key'), isFalse);
    expect(api.lastJson, {
      'on_opened': true,
      'scope': 'scoped',
      'domains': <String>[],
    });

    await api.client().webhooks.update('w-1', const UpdateWebhookRequest());
    expect(api.lastJson, <String, Object?>{});
  });

  test('webhooks.delete sends DELETE', () async {
    final api = FakeApi();
    final result = await api.client().webhooks.delete('w-1');
    expect(api.last.method, 'DELETE');
    expect(api.last.url.path, accountPath('/webhooks/w-1'));
    expect(result.message, 'ok');
  });

  test('unknown scope decodes to unknown', () {
    expect(WebhookScope('team').isKnown, isFalse);
  });
}
