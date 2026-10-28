import 'package:ahasend/ahasend.dart';
import 'package:test/test.dart';

import 'helpers.dart';

Map<String, Object?> routeJson({String id = 'r-1'}) => {
  'object': 'route',
  'id': id,
  'created_at': '2024-05-06T09:00:00Z',
  'updated_at': '2024-05-06T10:00:00Z',
  'name': 'Support Route',
  'url': 'https://example.com/webhook',
  'recipient': 'support@example.com',
  'attachments': true,
  'headers': false,
  'group_by_message_id': false,
  'strip_replies': true,
  'enabled': true,
  'success_count': 12,
  'error_count': 1.0,
  'errors_since_last_success': 0,
  'last_request_at': null,
};

void main() {
  group('routes.list', () {
    test('sends filters and decodes the page', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          pageBody([routeJson()], hasMore: true, nextCursor: 'c2'),
        ),
      ]);
      final page = await api.client().routes.list(
        domain: 'example.com',
        limit: 20,
        after: 'c1',
      );
      expect(api.last.method, 'GET');
      expect(api.last.url.path, accountPath('/routes'));
      expect(api.last.url.queryParameters, {
        'domain': 'example.com',
        'limit': '20',
        'after': 'c1',
      });
      final route = page.data.single;
      expect(route.id, 'r-1');
      expect(route.name, 'Support Route');
      expect(route.recipient, 'support@example.com');
      expect(route.attachments, isTrue);
      expect(route.stripReplies, isTrue);
      expect(route.errorCount, 1);
      expect(route.lastRequestAt, isNull);
      expect(route.createdAt, DateTime.utc(2024, 5, 6, 9));
      expect(page.pagination.nextCursor, 'c2');
    });

    test('listAll follows cursors and keeps filters', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          pageBody([routeJson(id: '1')], hasMore: true, nextCursor: 'c2'),
        ),
        FakeResponse(200, pageBody([routeJson(id: '2')])),
      ]);
      final ids = await api
          .client()
          .routes
          .listAll(domain: 'example.com')
          .map((r) => r.id)
          .toList();
      expect(ids, ['1', '2']);
      expect(api.requests[1].url.queryParameters, {
        'domain': 'example.com',
        'after': 'c2',
      });
    });
  });

  test(
    'routes.create posts with an idempotency key and keeps the secret',
    () async {
      final api = FakeApi([
        FakeResponse(201, {...routeJson(), 'secret': 'aha-rsec-abc'}),
      ]);
      final created = await api.client().routes.create(
        const CreateRouteRequest(
          name: 'Support Route',
          url: 'https://example.com/webhook',
          recipient: 'support@example.com',
          attachments: true,
          enabled: true,
        ),
      );
      expect(api.last.method, 'POST');
      expect(api.last.url.path, accountPath('/routes'));
      expect(api.last.headers['Idempotency-Key'], isNotEmpty);
      expect(api.lastJson, {
        'name': 'Support Route',
        'url': 'https://example.com/webhook',
        'recipient': 'support@example.com',
        'attachments': true,
        'enabled': true,
      });
      expect(created.secret, 'aha-rsec-abc');
      expect(created.id, 'r-1');
      expect(created.toString(), isNot(contains('aha-rsec-abc')));
      expect(created.toJson()['secret'], 'aha-rsec-abc');
    },
  );

  test('routes.get encodes the route ID', () async {
    final api = FakeApi([FakeResponse(200, routeJson())]);
    final route = await api.client().routes.get('r/1');
    expect(api.last.method, 'GET');
    expect(api.last.url.path, accountPath('/routes/r%2F1'));
    expect(route.url, 'https://example.com/webhook');
    expect(route.toJson()['object'], 'route');
  });

  test('routes.update sends PUT without an idempotency key', () async {
    final api = FakeApi([FakeResponse(200, routeJson())]);
    await api.client().routes.update(
      'r-1',
      const UpdateRouteRequest(name: 'Updated Support Route', enabled: false),
    );
    expect(api.last.method, 'PUT');
    expect(api.last.url.path, accountPath('/routes/r-1'));
    expect(api.last.headers.containsKey('Idempotency-Key'), isFalse);
    expect(api.lastJson, {'name': 'Updated Support Route', 'enabled': false});
  });

  test('routes.delete sends DELETE', () async {
    final api = FakeApi();
    final result = await api.client().routes.delete('r-1');
    expect(api.last.method, 'DELETE');
    expect(api.last.url.path, accountPath('/routes/r-1'));
    expect(api.last.headers.containsKey('Idempotency-Key'), isFalse);
    expect(result.message, 'ok');
  });
}
