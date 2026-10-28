import 'package:ahasend/ahasend.dart';
import 'package:test/test.dart';

import 'helpers.dart';

Map<String, Object?> suppressionJson({String id = 's-1'}) => {
  'object': 'suppression',
  'id': id,
  'created_at': '2024-12-01T10:30:00Z',
  'email': 'user@example.com',
  'domain': 'example.com',
  'reason': 'User requested removal',
  'protected': false,
  'expires_at': '2024-12-25T10:30:00Z',
};

void main() {
  group('suppressions.list', () {
    test('sends filters and decodes the page', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          pageBody([suppressionJson()], hasMore: true, nextCursor: 'c2'),
        ),
      ]);
      final page = await api.client().suppressions.list(
        domain: 'example.com',
        email: 'user@example.com',
        fromTime: DateTime.utc(2024, 1, 1),
        toTime: DateTime.utc(2024, 12, 31),
        limit: 50,
      );
      expect(api.last.method, 'GET');
      expect(api.last.url.path, accountPath('/suppressions'));
      expect(api.last.url.queryParameters, {
        'domain': 'example.com',
        'email': 'user@example.com',
        'from_time': '2024-01-01T00:00:00.000Z',
        'to_time': '2024-12-31T00:00:00.000Z',
        'limit': '50',
      });
      final suppression = page.data.single;
      expect(suppression.reason, 'User requested removal');
      expect(suppression.protected, isFalse);
      expect(suppression.expiresAt, DateTime.utc(2024, 12, 25, 10, 30));
      expect(suppression.toJson(), {
        ...suppressionJson(),
        'created_at': '2024-12-01T10:30:00.000Z',
        'expires_at': '2024-12-25T10:30:00.000Z',
      });
      expect(page.pagination.nextCursor, 'c2');
    });

    test('listAll follows cursors and keeps filters', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          pageBody([suppressionJson(id: '1')], hasMore: true, nextCursor: 'c2'),
        ),
        FakeResponse(200, pageBody([suppressionJson(id: '2')])),
      ]);
      final ids = await api
          .client()
          .suppressions
          .listAll(domain: 'example.com')
          .map((s) => s.id)
          .toList();
      expect(ids, ['1', '2']);
      expect(api.requests[1].url.queryParameters, {
        'domain': 'example.com',
        'after': 'c2',
      });
    });
  });

  test('suppressions.create posts with an idempotency key', () async {
    final api = FakeApi([
      FakeResponse(201, {
        'object': 'list',
        'data': [
          {...suppressionJson(), 'protected': true},
        ],
      }),
    ]);
    final response = await api.client().suppressions.create(
      CreateSuppressionRequest(
        email: 'user@example.com',
        domain: 'example.com',
        reason: 'User requested removal',
        expiresAt: DateTime.utc(2024, 12, 25, 10, 30),
      ),
    );
    expect(api.last.method, 'POST');
    expect(api.last.url.path, accountPath('/suppressions'));
    expect(api.last.headers['Idempotency-Key'], isNotEmpty);
    expect(api.lastJson, {
      'email': 'user@example.com',
      'domain': 'example.com',
      'reason': 'User requested removal',
      'expires_at': '2024-12-25T10:30:00.000Z',
    });
    expect(response.data.single.protected, isTrue);
  });

  group('suppressions.delete', () {
    test('sends email and domain as query parameters', () async {
      final api = FakeApi();
      final result = await api.client().suppressions.delete(
        'user+tag@example.com',
        domain: 'example.com',
      );
      expect(api.last.method, 'DELETE');
      expect(api.last.url.path, accountPath('/suppressions'));
      expect(api.last.url.queryParameters, {
        'email': 'user+tag@example.com',
        'domain': 'example.com',
      });
      expect(api.last.url.query, contains('user%2Btag%40example.com'));
      expect(api.last.headers['Idempotency-Key'], isNull);
      expect(api.last.body, isEmpty);
      expect(result.message, 'ok');
    });

    test('omits the domain when not given', () async {
      final api = FakeApi();
      await api.client().suppressions.delete('user@example.com');
      expect(api.last.url.queryParameters, {'email': 'user@example.com'});
    });
  });

  test('suppressions.deleteAll uses the /all path', () async {
    final api = FakeApi([
      FakeResponse(200, {'message': 'Deleted 3 suppressions, kept 1'}),
    ]);
    final client = api.client();
    final result = await client.suppressions.deleteAll(domain: 'example.com');
    expect(api.last.method, 'DELETE');
    expect(api.last.url.path, accountPath('/suppressions/all'));
    expect(api.last.url.queryParameters, {'domain': 'example.com'});
    expect(result.message, contains('kept 1'));

    await client.suppressions.deleteAll();
    expect(api.last.url.queryParameters, isEmpty);
  });
}
