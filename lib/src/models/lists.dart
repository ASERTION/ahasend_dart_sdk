import '../json.dart';
import 'contacts.dart';

/// A contact's consent for one list, independent of the contact's
/// account-wide unsubscription.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const ListSubscriptionStatus(
  /// The string the API uses for this value.
  String value,
) {
  /// Consent has not been confirmed.
  static const ListSubscriptionStatus unconfirmed = ListSubscriptionStatus(
    'unconfirmed',
  );

  /// The contact is subscribed; campaigns to the list reach them.
  static const ListSubscriptionStatus confirmed = ListSubscriptionStatus(
    'confirmed',
  );

  /// The contact unsubscribed from the list.
  static const ListSubscriptionStatus unsubscribed = ListSubscriptionStatus(
    'unsubscribed',
  );

  /// The contact reported the list as spam. Set by the mailbox provider;
  /// cannot be written.
  static const ListSubscriptionStatus complained = ListSubscriptionStatus(
    'complained',
  );

  /// Every value this version of the package knows.
  static const List<ListSubscriptionStatus> values = [
    unconfirmed,
    confirmed,
    unsubscribed,
    complained,
  ];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// A static, private, single opt-in list of contacts that campaigns target.
final class const ContactList({
  /// The list ID.
  required final String id,

  /// When the list was created.
  required final DateTime createdAt,

  /// When the list was last updated.
  required final DateTime updatedAt,

  /// The list name; not unique within an account.
  required final String name,

  /// The description; empty when none was given.
  required final String description,

  /// The tags; empty when the list has none.
  required final List<String> tags,

  /// The number of subscribers a campaign to this list would reach.
  ///
  /// Counts confirmed members whose contact is enabled, not unsubscribed
  /// account-wide and not found invalid by validation.
  required final int contactCount,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a list.
  this;

  /// Decodes a list from JSON.
  factory fromJson(JsonMap json) => ContactList(
    id: json['id'] as String,
    createdAt: decodeDateTime(json['created_at']),
    updatedAt: decodeDateTime(json['updated_at']),
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    tags: decodeScalarList<String>(json['tags']),
    contactCount: decodeInt(json['contact_count'] ?? 0),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'contact_list',
    'id': id,
    'created_at': encodeDateTime(createdAt),
    'updated_at': encodeDateTime(updatedAt),
    'name': name,
    'description': description,
    'tags': tags,
    'contact_count': contactCount,
  };

  @override
  String toString() =>
      'ContactList(id: $id, name: $name, contactCount: $contactCount)';
}

/// A list as embedded in a membership: a [ContactList] without
/// `contactCount`.
final class const EmbeddedContactList({
  /// The list ID.
  required final String id,

  /// When the list was created.
  required final DateTime createdAt,

  /// When the list was last updated.
  required final DateTime updatedAt,

  /// The list name.
  required final String name,

  /// The description; empty when none was given.
  required final String description,

  /// The tags; empty when the list has none.
  required final List<String> tags,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates an embedded list.
  this;

  /// Decodes an embedded list from JSON.
  factory fromJson(JsonMap json) => EmbeddedContactList(
    id: json['id'] as String,
    createdAt: decodeDateTime(json['created_at']),
    updatedAt: decodeDateTime(json['updated_at']),
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    tags: decodeScalarList<String>(json['tags']),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'contact_list',
    'id': id,
    'created_at': encodeDateTime(createdAt),
    'updated_at': encodeDateTime(updatedAt),
    'name': name,
    'description': description,
    'tags': tags,
  };

  @override
  String toString() => 'EmbeddedContactList(id: $id, name: $name)';
}

/// A request to create a list.
final class const CreateContactListRequest({
  /// The name, 1 to 255 characters after trimming.
  required final String name,

  /// The description, at most 1,000 characters after trimming.
  final String? description,

  /// The tags; trimmed, empty ones dropped, duplicates collapsed, at most 50.
  final List<String>? tags,
}) {
  /// Creates a request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'name': name,
    'description': ?description,
    'tags': ?tags,
  };
}

/// A partial list update.
///
/// Fields left `null` keep their stored value. A present [tags] list
/// replaces the stored tags; an empty list clears them.
final class const UpdateContactListRequest({
  /// The new name, 1 to 255 characters after trimming.
  final String? name,

  /// The new description, at most 1,000 characters after trimming. Pass an
  /// empty string to clear it.
  final String? description,

  /// The new tags. Pass an empty list to clear them.
  final List<String>? tags,
}) {
  /// Creates a request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'name': ?name,
    'description': ?description,
    'tags': ?tags,
  };
}

/// One contact's membership of one list, addressed by list and contact ID.
final class const ListContact({
  /// The list ID.
  required final String listId,

  /// The contact ID.
  required final String contactId,

  /// The contact's normalized email address.
  required final String email,

  /// The per-list consent.
  required final ListSubscriptionStatus subscriptionStatus,

  /// When the membership was created.
  required final DateTime createdAt,

  /// When the membership was last updated.
  required final DateTime updatedAt,

  /// When consent was first given (the membership became confirmed).
  final DateTime? subscribedAt,

  /// When the membership became unsubscribed or complained. Cleared when it
  /// is confirmed again.
  final DateTime? unsubscribedAt,

  /// The whole contact; present only when listing a list's contacts with
  /// `includeContacts: true`.
  final Contact? contact,

  /// The list; present only when listing a contact's lists.
  final EmbeddedContactList? list,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a membership.
  this;

  /// Decodes a membership from JSON.
  factory fromJson(JsonMap json) => ListContact(
    listId: json['list_id'] as String,
    contactId: json['contact_id'] as String,
    email: json['email'] as String,
    subscriptionStatus: decodeEnum(
      json['subscription_status'],
      ListSubscriptionStatus.new,
    ),
    subscribedAt: decodeDateTimeOrNull(json['subscribed_at']),
    unsubscribedAt: decodeDateTimeOrNull(json['unsubscribed_at']),
    createdAt: decodeDateTime(json['created_at']),
    updatedAt: decodeDateTime(json['updated_at']),
    contact: switch (json['contact']) {
      null => null,
      final contact => Contact.fromJson(asJsonMap(contact)),
    },
    list: switch (json['list']) {
      null => null,
      final list => EmbeddedContactList.fromJson(asJsonMap(list)),
    },
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'list_contact',
    'list_id': listId,
    'contact_id': contactId,
    'email': email,
    'subscription_status': subscriptionStatus.value,
    'subscribed_at': encodeDateTimeOrNull(subscribedAt),
    'unsubscribed_at': encodeDateTimeOrNull(unsubscribedAt),
    'created_at': encodeDateTime(createdAt),
    'updated_at': encodeDateTime(updatedAt),
    'contact': ?contact?.toJson(),
    'list': ?list?.toJson(),
  };

  @override
  String toString() =>
      'ListContact(listId: $listId, contactId: $contactId, '
      'email: $email, subscriptionStatus: ${subscriptionStatus.value})';
}

/// A request to add a contact to a list or update its membership.
final class const UpsertListContactRequest({
  /// The per-list consent to set: [ListSubscriptionStatus.confirmed],
  /// [ListSubscriptionStatus.unconfirmed] or
  /// [ListSubscriptionStatus.unsubscribed]. `complained` is rejected.
  final ListSubscriptionStatus? subscriptionStatus,
}) {
  /// Creates a request.
  ///
  /// Without [subscriptionStatus], a new membership is confirmed and an
  /// existing one keeps its status.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {'subscription_status': ?subscriptionStatus?.value};
}

/// One entry of a batch add: an existing contact named by email or ID.
final class const BatchAddListContactInput._({
  /// The contact's email address.
  final String? email,

  /// The contact ID.
  final String? id,
}) {
  /// Names the contact by email address.
  const new byEmail(String email) : this._(email: email);

  /// Names the contact by ID.
  const new byId(String id) : this._(id: id);

  /// Encodes this object as JSON.
  JsonMap toJson() => {'email': ?email, 'id': ?id};
}

/// A request to add up to 1,000 existing contacts to a list.
final class const BatchAddListContactsRequest({
  /// The entries.
  required final List<BatchAddListContactInput> data,
}) {
  /// Creates a request with 1 to 1,000 entries.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'data': [for (final e in data) e.toJson()],
  };
}

/// The outcome of one batch add entry.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const BatchListContactOutcome(
  /// The string the API uses for this value.
  String value,
) {
  /// The membership was created as confirmed.
  static const BatchListContactOutcome added = BatchListContactOutcome('added');

  /// A membership already existed and was left unchanged.
  static const BatchListContactOutcome alreadyMember = BatchListContactOutcome(
    'already_member',
  );

  /// No contact in the account matches the entry.
  static const BatchListContactOutcome notFound = BatchListContactOutcome(
    'not_found',
  );

  /// The entry is malformed or repeats an identifier.
  static const BatchListContactOutcome invalid = BatchListContactOutcome(
    'invalid',
  );

  /// Every value this version of the package knows.
  static const List<BatchListContactOutcome> values = [
    added,
    alreadyMember,
    notFound,
    invalid,
  ];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// The result of one batch add entry.
final class const BatchListContactResult({
  /// The entry's index in the request.
  required final int position,

  /// The outcome.
  required final BatchListContactOutcome outcome,

  /// The normalized input email, when the entry named a valid one.
  final String? email,

  /// The input contact ID, when the entry named a valid UUID.
  final String? id,

  /// The membership; present for `added` and `alreadyMember`.
  final ListContact? membership,

  /// Why the entry failed; present for `notFound` and `invalid`.
  final String? reason,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a result.
  this;

  /// Decodes a result from JSON.
  factory fromJson(JsonMap json) => BatchListContactResult(
    position: decodeInt(json['position']),
    email: json['email'] as String?,
    id: json['id'] as String?,
    outcome: decodeEnum(json['outcome'], BatchListContactOutcome.new),
    membership: switch (json['membership']) {
      null => null,
      final membership => ListContact.fromJson(asJsonMap(membership)),
    },
    reason: json['reason'] as String?,
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'position': position,
    'email': ?email,
    'id': ?id,
    'outcome': outcome.value,
    'membership': ?membership?.toJson(),
    'reason': ?reason,
  };

  @override
  String toString() =>
      'BatchListContactResult(position: $position, '
      'outcome: ${outcome.value}${reason == null ? '' : ', reason: $reason'})';
}

/// The response to a batch add: counts and one result per entry.
final class const BatchAddListContactsResponse({
  /// Entries whose membership was created.
  required final int added,

  /// Entries reported as already a member.
  required final int skipped,

  /// Entries reported as not found or invalid.
  required final int failed,

  /// One result per entry, in request order.
  required final List<BatchListContactResult> data,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a response.
  this;

  /// Decodes a response from JSON.
  factory fromJson(JsonMap json) => BatchAddListContactsResponse(
    added: decodeInt(json['added'] ?? 0),
    skipped: decodeInt(json['skipped'] ?? 0),
    failed: decodeInt(json['failed'] ?? 0),
    data: decodeList(json['data'], BatchListContactResult.fromJson),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'list',
    'added': added,
    'skipped': skipped,
    'failed': failed,
    'data': [for (final r in data) r.toJson()],
  };

  @override
  String toString() =>
      'BatchAddListContactsResponse(added: $added, '
      'skipped: $skipped, failed: $failed)';
}
