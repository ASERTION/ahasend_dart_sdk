import 'package:ahasend/ahasend.dart';
import 'package:test/test.dart';

import 'contacts_test.dart' show contactJson, contactPage, contactId;
import 'helpers.dart';

const listId = 'a1b2c3d4-0000-4000-8000-000000000001';

Map<String, Object?> listJson({String id = listId}) => {
  'object': 'contact_list',
  'id': id,
  'created_at': '2026-09-01T09:00:00.000Z',
  'updated_at': '2026-09-02T09:00:00.000Z',
  'name': 'Newsletter',
  'description': '',
  'tags': ['weekly'],
  'contact_count': 42,
};

Map<String, Object?> membershipJson({
  Map<String, Object?>? contact,
  Map<String, Object?>? list,
}) => {
  'object': 'list_contact',
  'list_id': listId,
  'contact_id': contactId,
  'email': 'person@example.com',
  'subscription_status': 'confirmed',
  'subscribed_at': '2026-09-03T09:00:00Z',
  'unsubscribed_at': null,
  'created_at': '2026-09-03T09:00:00Z',
  'updated_at': '2026-09-03T09:00:00Z',
  'contact': ?contact,
  'list': ?list,
};

void main() {
  group('lists.list', () {
    test('sends the name filter and decodes the page', () async {
      final api = FakeApi([
        FakeResponse(200, contactPage([listJson()], hasMore: true, next: 'n')),
      ]);
      final page = await api.client().lists.list(name: 'news', limit: 5);
      expect(api.last.method, 'GET');
      expect(api.last.url.path, accountPath('/lists'));
      expect(api.last.url.queryParameters, {'name': 'news', 'limit': '5'});
      final list = page.data.single;
      expect(list.name, 'Newsletter');
      expect(list.tags, ['weekly']);
      expect(list.contactCount, 42);
      expect(list.toJson(), listJson());
      expect(page.pagination.nextCursor, 'n');
    });

    test('listAll follows cursors', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          contactPage([listJson(id: '1')], hasMore: true, next: 'n'),
        ),
        FakeResponse(200, contactPage([listJson(id: '2')])),
      ]);
      final ids = await api
          .client()
          .lists
          .listAll(name: 'x')
          .map((l) => l.id)
          .toList();
      expect(ids, ['1', '2']);
      expect(api.requests[1].url.queryParameters, {'name': 'x', 'after': 'n'});
    });
  });

  test('lists.create posts with an idempotency key', () async {
    final api = FakeApi([FakeResponse(201, listJson())]);
    await api.client().lists.create(
      const CreateContactListRequest(name: 'Newsletter', tags: ['weekly']),
    );
    expect(api.last.method, 'POST');
    expect(api.last.url.path, accountPath('/lists'));
    expect(api.last.headers['Idempotency-Key'], isNotEmpty);
    expect(api.lastJson, {
      'name': 'Newsletter',
      'tags': ['weekly'],
    });
  });

  test('lists.get, update and delete use the list path', () async {
    final api = FakeApi([FakeResponse(200, listJson())]);
    final client = api.client();

    final list = await client.lists.get(listId);
    expect(api.last.method, 'GET');
    expect(api.last.url.path, accountPath('/lists/$listId'));
    expect(list.id, listId);

    await client.lists.update(
      listId,
      const UpdateContactListRequest(description: '', tags: []),
    );
    expect(api.last.method, 'PUT');
    expect(api.last.url.path, accountPath('/lists/$listId'));
    expect(api.last.headers['Idempotency-Key'], isNull);
    expect(api.lastJson, {'description': '', 'tags': <Object>[]});

    await client.lists.update(listId, const UpdateContactListRequest());
    expect(api.lastJson, <String, Object?>{});

    await client.lists.delete(listId);
    expect(api.last.method, 'DELETE');
    expect(api.last.url.path, accountPath('/lists/$listId'));
  });

  group('lists.listContacts', () {
    test('sends filters and decodes embedded contacts', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          contactPage([membershipJson(contact: contactJson())]),
        ),
      ]);
      final page = await api.client().lists.listContacts(
        listId,
        subscriptionStatus: ListSubscriptionStatus.complained,
        email: 'person@example.com',
        includeContacts: true,
        limit: 10,
      );
      expect(api.last.url.path, accountPath('/lists/$listId/contacts'));
      expect(api.last.url.queryParameters, {
        'subscription_status': 'complained',
        'email': 'person@example.com',
        'include_contacts': 'true',
        'limit': '10',
      });
      final membership = page.data.single;
      expect(membership.subscriptionStatus, ListSubscriptionStatus.confirmed);
      expect(membership.subscribedAt, DateTime.utc(2026, 9, 3, 9));
      expect(membership.unsubscribedAt, isNull);
      expect(membership.contact!.email, 'person@example.com');
      expect(membership.list, isNull);
      expect(page.hasMore, isFalse);
    });

    test('listAllContacts follows cursors and keeps filters', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          contactPage([membershipJson()], hasMore: true, next: 'n'),
        ),
        FakeResponse(200, contactPage([membershipJson()])),
      ]);
      final items = await api
          .client()
          .lists
          .listAllContacts(listId, includeContacts: false)
          .toList();
      expect(items, hasLength(2));
      expect(api.requests[1].url.queryParameters, {
        'include_contacts': 'false',
        'after': 'n',
      });
    });
  });

  test('lists.batchAddContacts posts entries and decodes results', () async {
    final api = FakeApi([
      FakeResponse(200, {
        'object': 'list',
        'added': 1,
        'skipped': 1,
        'failed': 1,
        'data': [
          {
            'position': 0,
            'email': 'person@example.com',
            'outcome': 'added',
            'membership': membershipJson(),
          },
          {
            'position': 1,
            'id': contactId,
            'outcome': 'already_member',
            'membership': membershipJson(),
          },
          {'position': 2, 'outcome': 'invalid', 'reason': 'names both'},
        ],
      }),
    ]);
    final response = await api.client().lists.batchAddContacts(
      listId,
      const BatchAddListContactsRequest(
        data: [
          BatchAddListContactInput.byEmail('person@example.com'),
          BatchAddListContactInput.byId(contactId),
        ],
      ),
    );
    expect(api.last.method, 'POST');
    expect(api.last.url.path, accountPath('/lists/$listId/contacts/batch'));
    expect(api.last.headers['Idempotency-Key'], isNotEmpty);
    expect(api.lastJson, {
      'data': [
        {'email': 'person@example.com'},
        {'id': contactId},
      ],
    });
    expect(response.added, 1);
    expect(response.skipped, 1);
    expect(response.failed, 1);
    expect(response.data[0].outcome, BatchListContactOutcome.added);
    expect(response.data[1].outcome, BatchListContactOutcome.alreadyMember);
    expect(response.data[1].id, contactId);
    expect(response.data[1].membership!.listId, listId);
    expect(response.data[2].outcome, BatchListContactOutcome.invalid);
    expect(response.data[2].email, isNull);
    expect(response.data[2].reason, 'names both');
  });

  group('lists.upsertContact', () {
    test('encodes the email and sends the status', () async {
      final api = FakeApi([FakeResponse(200, membershipJson())]);
      final membership = await api.client().lists.upsertContact(
        listId,
        'user+tag@example.com',
        const UpsertListContactRequest(
          subscriptionStatus: ListSubscriptionStatus.unsubscribed,
        ),
      );
      expect(api.last.method, 'PUT');
      expect(
        api.last.url.path,
        accountPath('/lists/$listId/contacts/user%2Btag%40example.com'),
      );
      expect(api.last.headers['Idempotency-Key'], isNull);
      expect(api.lastJson, {'subscription_status': 'unsubscribed'});
      expect(membership.contactId, contactId);
    });

    test('an empty request sends an empty object', () async {
      final api = FakeApi([FakeResponse(200, membershipJson())]);
      await api.client().lists.upsertContact(
        listId,
        contactId,
        const UpsertListContactRequest(),
      );
      expect(api.lastJson, <String, Object?>{});
    });
  });

  test('lists.removeContact sends DELETE with the encoded email', () async {
    final api = FakeApi();
    final result = await api.client().lists.removeContact(
      listId,
      'a+b@example.com',
    );
    expect(api.last.method, 'DELETE');
    expect(
      api.last.url.path,
      accountPath('/lists/$listId/contacts/a%2Bb%40example.com'),
    );
    expect(result.message, 'ok');
  });

  group('lists.listForContact', () {
    test('uses the contact path and decodes embedded lists', () async {
      final embedded = Map.of(listJson())..remove('contact_count');
      final api = FakeApi([
        FakeResponse(200, contactPage([membershipJson(list: embedded)])),
      ]);
      final page = await api.client().lists.listForContact(
        'user+tag@example.com',
        subscriptionStatus: ListSubscriptionStatus.confirmed,
        limit: 3,
      );
      expect(api.last.method, 'GET');
      expect(
        api.last.url.path,
        accountPath('/contacts/user%2Btag%40example.com/lists'),
      );
      expect(api.last.url.queryParameters, {
        'subscription_status': 'confirmed',
        'limit': '3',
      });
      final list = page.data.single.list!;
      expect(list.name, 'Newsletter');
      expect(list.toJson(), embedded);
    });

    test('listAllForContact follows cursors', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          contactPage([membershipJson()], hasMore: true, next: 'n'),
        ),
        FakeResponse(200, contactPage([membershipJson()])),
      ]);
      final items = await api
          .client()
          .lists
          .listAllForContact(contactId)
          .toList();
      expect(items, hasLength(2));
      expect(
        api.requests[1].url.path,
        accountPath('/contacts/$contactId/lists'),
      );
      expect(api.requests[1].url.queryParameters, {'after': 'n'});
    });
  });

  test('unknown enum values are kept', () {
    expect(ListSubscriptionStatus('bounced').isKnown, isFalse);
    expect(BatchListContactOutcome('queued').isKnown, isFalse);
  });
}
