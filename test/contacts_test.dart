import 'package:ahasend/ahasend.dart';
import 'package:test/test.dart';

import 'helpers.dart';

const contactId = 'c0a8e2f4-1b2c-4d5e-8f90-123456789abc';

Map<String, Object?> contactJson({String id = contactId}) => {
  'object': 'contact',
  'id': id,
  'created_at': '2026-09-09T10:04:56Z',
  'updated_at': '2026-09-10T08:00:00Z',
  'email': 'person@example.com',
  'first_name': 'Pat',
  'last_name': 'Example',
  'status': 'enabled',
  'status_reason': '',
  'unsubscribed': false,
  'unsubscribed_at': null,
  'attributes': {
    'customer': true,
    'score': 12.5,
    'birthday': '2024-02-29',
    'legacy': [
      1,
      null,
      {'nested': 'x'},
    ],
    'gone': null,
  },
  'validation_status': 'valid',
  'last_validated_at': '2026-09-10T07:00:00Z',
};

/// A list response with the contact pagination shape: cursors are always
/// present and may be `null`.
Map<String, Object?> contactPage(
  List<Object?> data, {
  bool hasMore = false,
  String? next,
}) => {
  'object': 'list',
  'data': data,
  'pagination': {
    'has_more': hasMore,
    'next_cursor': next,
    'previous_cursor': null,
  },
};

void main() {
  group('contacts.list', () {
    test('sends filters and decodes a page with null cursors', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          contactPage([contactJson()], hasMore: true, next: 'c2'),
        ),
      ]);
      final page = await api.client().contacts.list(
        email: 'person@example.com',
        status: ContactStatus.enabled,
        subscribed: true,
        fromTime: DateTime.utc(2026, 1, 1),
        toTime: DateTime.utc(2026, 2, 1),
        limit: 20,
      );
      expect(api.last.method, 'GET');
      expect(api.last.url.path, accountPath('/contacts'));
      expect(api.last.url.queryParameters, {
        'email': 'person@example.com',
        'status': 'enabled',
        'subscribed': 'true',
        'from_time': '2026-01-01T00:00:00.000Z',
        'to_time': '2026-02-01T00:00:00.000Z',
        'limit': '20',
      });
      expect(api.last.headers['Idempotency-Key'], isNull);

      final contact = page.data.single;
      expect(contact.id, contactId);
      expect(contact.status, ContactStatus.enabled);
      expect(contact.validationStatus, ContactValidationStatus.valid);
      expect(contact.unsubscribedAt, isNull);
      expect(contact.lastValidatedAt, DateTime.utc(2026, 9, 10, 7));
      expect(contact.attributes['score'], 12.5);
      expect(contact.attributes['legacy'], [
        1,
        null,
        {'nested': 'x'},
      ]);
      expect(contact.attributes.containsKey('gone'), isTrue);
      expect(page.hasMore, isTrue);
      expect(page.pagination.nextCursor, 'c2');
      expect(page.pagination.previousCursor, isNull);
      expect(await page.previousPage(), isNull);
    });

    test('listAll stops at a null next_cursor and keeps filters', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          contactPage([contactJson(id: '1')], hasMore: true, next: 'c2'),
        ),
        FakeResponse(200, contactPage([contactJson(id: '2')])),
      ]);
      final ids = await api
          .client()
          .contacts
          .listAll(status: ContactStatus.blocked)
          .map((c) => c.id)
          .toList();
      expect(ids, ['1', '2']);
      expect(api.requests, hasLength(2));
      expect(api.requests[1].url.queryParameters, {
        'status': 'blocked',
        'after': 'c2',
      });
    });

    test('a page fetched with before still has a next page', () async {
      // has_more is false: no page exists before this one.
      final api = FakeApi([
        FakeResponse(200, contactPage([contactJson(id: '1')], next: 'c2')),
        FakeResponse(200, contactPage([contactJson(id: '2')])),
      ]);
      final page = await api.client().contacts.list(before: 'c1');
      expect(page.hasMore, isTrue);
      final next = await page.nextPage();
      expect(next!.data.single.id, '2');
      expect(api.requests[1].url.queryParameters, {'after': 'c2'});
      expect(next.hasMore, isFalse);
    });
  });

  test('contacts.create posts the request with an idempotency key', () async {
    final api = FakeApi([FakeResponse(201, contactJson())]);
    final contact = await api.client().contacts.create(
      const CreateContactRequest(
        email: 'person@example.com',
        firstName: 'Pat',
        lastName: 'Example',
        status: ContactStatus.enabled,
        unsubscribed: false,
        attributes: {
          'customer': true,
          'score': 12.5,
          'birthday': '2024-02-29',
          'joined_at': '2026-09-09T10:04:56Z',
        },
      ),
    );
    expect(api.last.method, 'POST');
    expect(api.last.url.path, accountPath('/contacts'));
    expect(api.last.headers['Idempotency-Key'], isNotEmpty);
    expect(api.lastJson, {
      'email': 'person@example.com',
      'first_name': 'Pat',
      'last_name': 'Example',
      'status': 'enabled',
      'unsubscribed': false,
      'attributes': {
        'customer': true,
        'score': 12.5,
        'birthday': '2024-02-29',
        'joined_at': '2026-09-09T10:04:56Z',
      },
    });
    expect(contact.email, 'person@example.com');
    expect(contact.toJson()['attributes'], contactJson()['attributes']);
  });

  group('id_or_email', () {
    test('get percent-encodes an email with + and @ exactly once', () async {
      final api = FakeApi([FakeResponse(200, contactJson())]);
      await api.client().contacts.get('user+tag@example.com');
      expect(api.last.method, 'GET');
      expect(
        api.last.url.path,
        accountPath('/contacts/user%2Btag%40example.com'),
      );
      expect(api.last.url.toString(), contains('user%2Btag%40example.com'));
      expect(api.last.url.pathSegments.last, 'user+tag@example.com');
    });

    test('get accepts a contact ID', () async {
      final api = FakeApi([FakeResponse(200, contactJson())]);
      final contact = await api.client().contacts.get(contactId);
      expect(api.last.url.path, accountPath('/contacts/$contactId'));
      expect(contact.firstName, 'Pat');
    });
  });

  group('contacts.update', () {
    test('sends only set fields and keeps null attribute members', () async {
      final api = FakeApi([FakeResponse(200, contactJson())]);
      await api.client().contacts.update(
        'user+tag@example.com',
        const UpdateContactRequest(
          firstName: 'Jordan',
          unsubscribed: true,
          attributes: {'obsolete': null, 'score': 3},
        ),
      );
      expect(api.last.method, 'PUT');
      expect(
        api.last.url.path,
        accountPath('/contacts/user%2Btag%40example.com'),
      );
      expect(api.last.headers['Idempotency-Key'], isNull);
      expect(api.lastJson, {
        'first_name': 'Jordan',
        'unsubscribed': true,
        'attributes': {'obsolete': null, 'score': 3},
      });
    });

    test('an empty update sends an empty object', () async {
      final api = FakeApi([FakeResponse(200, contactJson())]);
      await api.client().contacts.update(
        contactId,
        const UpdateContactRequest(),
      );
      expect(api.lastJson, <String, Object?>{});
    });
  });

  test('contacts.delete sends DELETE with the encoded email', () async {
    final api = FakeApi();
    final result = await api.client().contacts.delete('a+b@example.com');
    expect(api.last.method, 'DELETE');
    expect(api.last.url.path, accountPath('/contacts/a%2Bb%40example.com'));
    expect(api.last.headers['Idempotency-Key'], isNull);
    expect(result.message, 'ok');
  });

  test('contacts.batchUpsert posts entries and decodes results', () async {
    final api = FakeApi([
      FakeResponse(200, {
        'object': 'list',
        'created': 1,
        'updated': 0,
        'failed': 1,
        'data': [
          {
            'position': 0,
            'email': 'new@example.com',
            'outcome': 'created',
            'contact': contactJson(),
          },
          {
            'position': 1,
            'email': '',
            'outcome': 'failed',
            'reason': 'invalid email',
          },
        ],
      }),
    ]);
    final response = await api.client().contacts.batchUpsert(
      const BatchUpsertContactsRequest(
        data: [
          BatchUpsertContactInput(
            email: 'new@example.com',
            attributes: {'customer': true},
          ),
          BatchUpsertContactInput(
            email: 'existing@example.com',
            status: ContactStatus.disabled,
            attributes: {'obsolete': null},
          ),
        ],
      ),
    );
    expect(api.last.method, 'POST');
    expect(api.last.url.path, accountPath('/contacts/batch'));
    expect(api.last.headers['Idempotency-Key'], isNotEmpty);
    expect(api.lastJson, {
      'data': [
        {
          'email': 'new@example.com',
          'attributes': {'customer': true},
        },
        {
          'email': 'existing@example.com',
          'status': 'disabled',
          'attributes': {'obsolete': null},
        },
      ],
    });
    expect(response.created, 1);
    expect(response.failed, 1);
    expect(response.data[0].outcome, BatchContactOutcome.created);
    expect(response.data[0].contact!.id, contactId);
    expect(response.data[1].outcome, BatchContactOutcome.failed);
    expect(response.data[1].reason, 'invalid email');
    expect(response.data[1].contact, isNull);
  });

  test('unknown enum values are kept', () {
    expect(ContactStatus('archived').isKnown, isFalse);
    expect(ContactValidationStatus('unknown'), ContactValidationStatus.unknown);
    expect(ContactValidationStatus.unknown.isKnown, isTrue);
    expect(ContactValidationStatus('new').isKnown, isFalse);
    expect(BatchContactOutcome('skipped').isKnown, isFalse);
  });
}
