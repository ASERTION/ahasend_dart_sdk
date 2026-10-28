import '../http/request_options.dart';
import '../models/common.dart';
import '../models/contacts.dart';
import '../pagination.dart';
import 'resource.dart';

/// Create, list, update and delete contacts.
///
/// Methods that take `idOrEmail` accept a contact ID or a raw email address
/// such as `user+tag@example.com`; the client percent-encodes it.
///
/// Access it through [AhaSendClient.contacts].
interface class ContactsResource(super.transport, super.accountId)
    extends Resource {
  /// Creates the resource. Use [AhaSendClient.contacts] instead.
  this;

  /// Lists contacts, newest first.
  ///
  /// [email] is an exact, normalized email filter. [subscribed] filters by
  /// the account-wide subscription state. [fromTime] and [toTime] bound the
  /// creation time (inclusive). [limit] is 1 to 100.
  ///
  /// Requires the `contacts:read` scope.
  Future<CursorPage<Contact>> list({
    String? email,
    ContactStatus? status,
    bool? subscribed,
    DateTime? fromTime,
    DateTime? toTime,
    int? limit,
    String? after,
    String? before,
    RequestOptions? options,
  }) async => await fetchPage(
    '$accountPath/contacts',
    Contact.fromJson,
    query: _listQuery(
      email: email,
      status: status,
      subscribed: subscribed,
      fromTime: fromTime,
      toTime: toTime,
      limit: limit,
    ),
    after: after,
    before: before,
    options: options,
  );

  /// Iterates over every contact matching the filters, fetching pages as
  /// needed. Takes the same filters as [list].
  Stream<Contact> listAll({
    String? email,
    ContactStatus? status,
    bool? subscribed,
    DateTime? fromTime,
    DateTime? toTime,
    int? limit,
    RequestOptions? options,
  }) async* {
    yield* fetchAll(
      '$accountPath/contacts',
      Contact.fromJson,
      query: _listQuery(
        email: email,
        status: status,
        subscribed: subscribed,
        fromTime: fromTime,
        toTime: toTime,
        limit: limit,
      ),
      options: options,
    );
  }

  /// Creates a contact without list membership.
  ///
  /// Add it to a list with [ListsResource.upsertContact] before it can be
  /// targeted by campaigns. The request carries an idempotency key.
  ///
  /// Requires the `contacts:write` scope.
  Future<Contact> create(
    CreateContactRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '$accountPath/contacts',
    Contact.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Fetches a contact by ID or email address.
  ///
  /// Requires the `contacts:read` scope.
  Future<Contact> get(String idOrEmail, {RequestOptions? options}) async =>
      await sendAndDecode(
        'GET',
        '$accountPath/contacts/${segment(idOrEmail)}',
        Contact.fromJson,
        options: options,
      );

  /// Partially updates a contact identified by ID or email address.
  ///
  /// Requires the `contacts:write` scope.
  Future<Contact> update(
    String idOrEmail,
    UpdateContactRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'PUT',
    '$accountPath/contacts/${segment(idOrEmail)}',
    Contact.fromJson,
    body: request.toJson(),
    options: options,
  );

  /// Permanently deletes a contact with its list memberships and activity.
  ///
  /// Prefer unsubscribing when you only want to stop marketing mail.
  ///
  /// Requires the `contacts:delete` scope.
  Future<SuccessResponse> delete(
    String idOrEmail, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'DELETE',
    '$accountPath/contacts/${segment(idOrEmail)}',
    SuccessResponse.fromJson,
    options: options,
  );

  /// Creates or updates 1 to 1,000 contacts in one synchronous request.
  ///
  /// Entries succeed or fail individually; check
  /// [BatchUpsertContactsResponse.data]. The request carries an idempotency
  /// key.
  ///
  /// Requires the `contacts:write` scope.
  Future<BatchUpsertContactsResponse> batchUpsert(
    BatchUpsertContactsRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '$accountPath/contacts/batch',
    BatchUpsertContactsResponse.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  Map<String, Object?> _listQuery({
    String? email,
    ContactStatus? status,
    bool? subscribed,
    DateTime? fromTime,
    DateTime? toTime,
    int? limit,
  }) => {
    'email': email,
    'status': status,
    'subscribed': subscribed,
    'from_time': fromTime,
    'to_time': toTime,
    'limit': limit,
  };
}
