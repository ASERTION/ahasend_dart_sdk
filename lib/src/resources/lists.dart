import '../http/request_options.dart';
import '../models/common.dart';
import '../models/lists.dart';
import '../pagination.dart';
import 'resource.dart';

/// Manage contact lists and their members.
///
/// Methods that take `idOrEmail` accept a contact ID or a raw email address
/// such as `user+tag@example.com`; the client percent-encodes it.
///
/// Access it through [AhaSendClient.lists].
interface class ListsResource(super.transport, super.accountId)
    extends Resource {
  /// Creates the resource. Use [AhaSendClient.lists] instead.
  this;

  /// Lists the account's lists, newest first.
  ///
  /// [name] is a case-insensitive substring filter. [limit] is 1 to 100.
  ///
  /// Requires the `lists:read` scope.
  Future<CursorPage<ContactList>> list({
    String? name,
    int? limit,
    String? after,
    String? before,
    RequestOptions? options,
  }) async => await fetchPage(
    '$accountPath/lists',
    ContactList.fromJson,
    query: {'name': name, 'limit': limit},
    after: after,
    before: before,
    options: options,
  );

  /// Iterates over every list matching the filter, fetching pages as
  /// needed. Takes the same filters as [list].
  Stream<ContactList> listAll({
    String? name,
    int? limit,
    RequestOptions? options,
  }) async* {
    yield* fetchAll(
      '$accountPath/lists',
      ContactList.fromJson,
      query: {'name': name, 'limit': limit},
      options: options,
    );
  }

  /// Creates an empty list. The request carries an idempotency key.
  ///
  /// Requires the `lists:write` scope.
  Future<ContactList> create(
    CreateContactListRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '$accountPath/lists',
    ContactList.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Fetches a list.
  ///
  /// Requires the `lists:read` scope.
  Future<ContactList> get(String listId, {RequestOptions? options}) async =>
      await sendAndDecode(
        'GET',
        '$accountPath/lists/${segment(listId)}',
        ContactList.fromJson,
        options: options,
      );

  /// Partially updates a list.
  ///
  /// Requires the `lists:write` scope.
  Future<ContactList> update(
    String listId,
    UpdateContactListRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'PUT',
    '$accountPath/lists/${segment(listId)}',
    ContactList.fromJson,
    body: request.toJson(),
    options: options,
  );

  /// Soft-deletes a list. Memberships, including unsubscribes, are kept
  /// but are no longer readable.
  ///
  /// Requires the `lists:delete` scope.
  Future<SuccessResponse> delete(
    String listId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'DELETE',
    '$accountPath/lists/${segment(listId)}',
    SuccessResponse.fromJson,
    options: options,
  );

  /// Lists the memberships of a list, newest first.
  ///
  /// [subscriptionStatus] filters by per-list consent; `confirmed` answers
  /// who a campaign can reach. [email] is an exact email filter. Set
  /// [includeContacts] to embed each [ListContact.contact]; this also
  /// requires the `contacts:read` scope.
  ///
  /// Requires the `lists:read` scope.
  Future<CursorPage<ListContact>> listContacts(
    String listId, {
    ListSubscriptionStatus? subscriptionStatus,
    String? email,
    bool? includeContacts,
    int? limit,
    String? after,
    String? before,
    RequestOptions? options,
  }) async => await fetchPage(
    '$accountPath/lists/${segment(listId)}/contacts',
    ListContact.fromJson,
    query: {
      'subscription_status': subscriptionStatus,
      'email': email,
      'include_contacts': includeContacts,
      'limit': limit,
    },
    after: after,
    before: before,
    options: options,
  );

  /// Iterates over every membership of a list, fetching pages as needed.
  /// Takes the same filters as [listContacts].
  Stream<ListContact> listAllContacts(
    String listId, {
    ListSubscriptionStatus? subscriptionStatus,
    String? email,
    bool? includeContacts,
    int? limit,
    RequestOptions? options,
  }) async* {
    yield* fetchAll(
      '$accountPath/lists/${segment(listId)}/contacts',
      ListContact.fromJson,
      query: {
        'subscription_status': subscriptionStatus,
        'email': email,
        'include_contacts': includeContacts,
        'limit': limit,
      },
      options: options,
    );
  }

  /// Adds 1 to 1,000 existing contacts to a list as confirmed members.
  ///
  /// Existing memberships are left unchanged and reported as
  /// `alreadyMember`, so this never erases an unsubscribe. The request
  /// carries an idempotency key.
  ///
  /// Requires the `lists:write` scope.
  Future<BatchAddListContactsResponse> batchAddContacts(
    String listId,
    BatchAddListContactsRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '$accountPath/lists/${segment(listId)}/contacts/batch',
    BatchAddListContactsResponse.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Adds an existing contact to a list, or updates its membership.
  ///
  /// A new membership is confirmed unless [request] names another status.
  /// An existing membership keeps its status unless [request] names one.
  /// Pass `const UpsertListContactRequest()` to only ensure membership.
  ///
  /// Requires the `lists:write` scope.
  Future<ListContact> upsertContact(
    String listId,
    String idOrEmail,
    UpsertListContactRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'PUT',
    '$accountPath/lists/${segment(listId)}/contacts/${segment(idOrEmail)}',
    ListContact.fromJson,
    body: request.toJson(),
    options: options,
  );

  /// Removes a contact from a list, deleting the membership and any record
  /// that the contact unsubscribed from it.
  ///
  /// Prefer [upsertContact] with [ListSubscriptionStatus.unsubscribed] to
  /// stop mail while keeping the record. Complained memberships cannot be
  /// removed (409).
  ///
  /// Requires the `lists:write` scope.
  Future<SuccessResponse> removeContact(
    String listId,
    String idOrEmail, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'DELETE',
    '$accountPath/lists/${segment(listId)}/contacts/${segment(idOrEmail)}',
    SuccessResponse.fromJson,
    options: options,
  );

  /// Lists the memberships of one contact, each with
  /// [ListContact.list] embedded, newest first. Deleted lists are excluded.
  ///
  /// Requires the `lists:read` scope.
  Future<CursorPage<ListContact>> listForContact(
    String idOrEmail, {
    ListSubscriptionStatus? subscriptionStatus,
    int? limit,
    String? after,
    String? before,
    RequestOptions? options,
  }) async => await fetchPage(
    '$accountPath/contacts/${segment(idOrEmail)}/lists',
    ListContact.fromJson,
    query: {'subscription_status': subscriptionStatus, 'limit': limit},
    after: after,
    before: before,
    options: options,
  );

  /// Iterates over every membership of one contact, fetching pages as
  /// needed. Takes the same filters as [listForContact].
  Stream<ListContact> listAllForContact(
    String idOrEmail, {
    ListSubscriptionStatus? subscriptionStatus,
    int? limit,
    RequestOptions? options,
  }) async* {
    yield* fetchAll(
      '$accountPath/contacts/${segment(idOrEmail)}/lists',
      ListContact.fromJson,
      query: {'subscription_status': subscriptionStatus, 'limit': limit},
      options: options,
    );
  }
}
