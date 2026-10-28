import '../json.dart';

/// Any JSON value stored in a contact attribute (spec schema `JSONValue`).
///
/// One of `null`, `bool`, `num`, `String`, `List<Object?>` or
/// `Map<String, Object?>`, nested to any depth. Reads return this broader
/// type because attributes stored before canonical validation can hold any
/// JSON value.
typedef JsonValue = Object?;

/// A non-null contact attribute value accepted by writes (spec schema
/// `CanonicalContactAttributeValue`).
///
/// Use a `String`, a finite `num` or a `bool`, matching the attribute
/// definition managed in the dashboard. `date` attributes take a strict
/// `YYYY-MM-DD` string and `timestamp` attributes an RFC 3339 string. The
/// server rejects values whose type or format does not match the
/// definition.
typedef CanonicalContactAttributeValue = Object;

/// The account-wide status of a contact.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const ContactStatus(
  /// The string the API uses for this value.
  String value,
) {
  /// The contact can receive mail.
  static const ContactStatus enabled = ContactStatus('enabled');

  /// The contact is disabled.
  static const ContactStatus disabled = ContactStatus('disabled');

  /// The contact is blocked.
  static const ContactStatus blocked = ContactStatus('blocked');

  /// Every value this version of the package knows.
  static const List<ContactStatus> values = [enabled, disabled, blocked];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// The result of validating a contact's email address.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const ContactValidationStatus(
  /// The string the API uses for this value.
  String value,
) {
  /// The address has not been validated.
  static const ContactValidationStatus unvalidated = ContactValidationStatus(
    'unvalidated',
  );

  /// The address is valid.
  static const ContactValidationStatus valid = ContactValidationStatus('valid');

  /// The address is invalid.
  static const ContactValidationStatus invalid = ContactValidationStatus(
    'invalid',
  );

  /// The address is risky.
  static const ContactValidationStatus risky = ContactValidationStatus('risky');

  /// Validation was inconclusive.
  static const ContactValidationStatus unknown = ContactValidationStatus(
    'unknown',
  );

  /// Every value this version of the package knows.
  static const List<ContactValidationStatus> values = [
    unvalidated,
    valid,
    invalid,
    risky,
    unknown,
  ];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// An account-global contact.
///
/// Attribute values are read as legacy-safe JSON: they can be any JSON
/// value, even though writes accept only canonical values.
final class const Contact({
  /// The contact ID.
  required final String id,

  /// When the contact was created.
  required final DateTime createdAt,

  /// When the contact was last updated.
  required final DateTime updatedAt,

  /// The normalized (trimmed, lowercased) email address.
  required final String email,

  /// The first name; empty when unset.
  required final String firstName,

  /// The last name; empty when unset.
  required final String lastName,

  /// The account-wide status.
  required final ContactStatus status,

  /// Why the status was set; empty when unset.
  required final String statusReason,

  /// Whether the contact unsubscribed from all marketing mail.
  required final bool unsubscribed,

  /// Custom attributes. Values can be any [JsonValue].
  required final Map<String, JsonValue> attributes,

  /// The result of the last email validation.
  required final ContactValidationStatus validationStatus,

  /// When the contact unsubscribed, if they did.
  final DateTime? unsubscribedAt,

  /// When the address was last validated.
  final DateTime? lastValidatedAt,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a contact.
  this;

  /// Decodes a contact from JSON.
  factory fromJson(JsonMap json) => Contact(
    id: json['id'] as String,
    createdAt: decodeDateTime(json['created_at']),
    updatedAt: decodeDateTime(json['updated_at']),
    email: json['email'] as String,
    firstName: json['first_name'] as String? ?? '',
    lastName: json['last_name'] as String? ?? '',
    status: decodeEnum(json['status'], ContactStatus.new),
    statusReason: json['status_reason'] as String? ?? '',
    unsubscribed: json['unsubscribed'] as bool? ?? false,
    unsubscribedAt: decodeDateTimeOrNull(json['unsubscribed_at']),
    attributes: Map.unmodifiableOf({...?asJsonMapOrNull(json['attributes'])}),
    validationStatus: decodeEnum(
      json['validation_status'],
      ContactValidationStatus.new,
    ),
    lastValidatedAt: decodeDateTimeOrNull(json['last_validated_at']),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'contact',
    'id': id,
    'created_at': encodeDateTime(createdAt),
    'updated_at': encodeDateTime(updatedAt),
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'status': status.value,
    'status_reason': statusReason,
    'unsubscribed': unsubscribed,
    'unsubscribed_at': encodeDateTimeOrNull(unsubscribedAt),
    'attributes': attributes,
    'validation_status': validationStatus.value,
    'last_validated_at': encodeDateTimeOrNull(lastValidatedAt),
  };

  @override
  String toString() =>
      'Contact(id: $id, email: $email, '
      'status: ${status.value}, unsubscribed: $unsubscribed)';
}

/// A request to create a contact without list membership.
final class const CreateContactRequest({
  /// The email address; trimmed and lowercased by the server.
  required final String email,

  /// The first name.
  final String? firstName,

  /// The last name.
  final String? lastName,

  /// The status; the server defaults to [ContactStatus.enabled].
  final ContactStatus? status,

  /// Why the status was set.
  final String? statusReason,

  /// Only `true` records an initial unsubscription.
  final bool? unsubscribed,

  /// Custom attribute values; see [CanonicalContactAttributeValue]. Values
  /// cannot be `null`.
  final Map<String, CanonicalContactAttributeValue>? attributes,
}) {
  /// Creates a request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'email': email,
    'first_name': ?firstName,
    'last_name': ?lastName,
    'status': ?status?.value,
    'status_reason': ?statusReason,
    'unsubscribed': ?unsubscribed,
    'attributes': ?attributes,
  };
}

/// A partial contact update.
///
/// Fields left `null` keep their stored value; this request cannot clear
/// them. A present [attributes] map is merged into the stored attributes.
final class const UpdateContactRequest({
  /// The new email address.
  final String? email,

  /// The new first name.
  final String? firstName,

  /// The new last name.
  final String? lastName,

  /// The new status.
  final ContactStatus? status,

  /// The new status reason.
  final String? statusReason,

  /// Whether the contact is unsubscribed from all marketing mail.
  final bool? unsubscribed,

  /// Attribute changes, merged into the stored attributes.
  ///
  /// A `null` value removes that key; other values are
  /// [CanonicalContactAttributeValue]s.
  final Map<String, CanonicalContactAttributeValue?>? attributes,
}) {
  /// Creates a request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'email': ?email,
    'first_name': ?firstName,
    'last_name': ?lastName,
    'status': ?status?.value,
    'status_reason': ?statusReason,
    'unsubscribed': ?unsubscribed,
    'attributes': ?attributes,
  };
}

/// One create-or-update entry of a batch upsert.
///
/// On update, fields left `null` keep their stored value. On create, they
/// get the defaults of [CreateContactRequest].
final class const BatchUpsertContactInput({
  /// The email address that identifies the contact.
  required final String email,

  /// The first name.
  final String? firstName,

  /// The last name.
  final String? lastName,

  /// The status.
  final ContactStatus? status,

  /// Why the status was set.
  final String? statusReason,

  /// Whether the contact is unsubscribed from all marketing mail.
  final bool? unsubscribed,

  /// Attribute changes, merged into the stored attributes.
  ///
  /// A `null` value removes that key; other values are
  /// [CanonicalContactAttributeValue]s.
  final Map<String, CanonicalContactAttributeValue?>? attributes,
}) {
  /// Creates an entry.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'email': email,
    'first_name': ?firstName,
    'last_name': ?lastName,
    'status': ?status?.value,
    'status_reason': ?statusReason,
    'unsubscribed': ?unsubscribed,
    'attributes': ?attributes,
  };
}

/// A request to create or update up to 1,000 contacts.
final class const BatchUpsertContactsRequest({
  /// The entries.
  required final List<BatchUpsertContactInput> data,
}) {
  /// Creates a request with 1 to 1,000 entries.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'data': [for (final e in data) e.toJson()],
  };
}

/// The outcome of one batch upsert entry.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const BatchContactOutcome(
  /// The string the API uses for this value.
  String value,
) {
  /// A contact was created.
  static const BatchContactOutcome created = BatchContactOutcome('created');

  /// An existing contact was updated.
  static const BatchContactOutcome updated = BatchContactOutcome('updated');

  /// The entry failed; see [BatchContactResult.reason].
  static const BatchContactOutcome failed = BatchContactOutcome('failed');

  /// Every value this version of the package knows.
  static const List<BatchContactOutcome> values = [created, updated, failed];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// The result of one batch upsert entry.
final class const BatchContactResult({
  /// The entry's index in the request.
  required final int position,

  /// The normalized input email; empty when it was not a string.
  required final String email,

  /// The outcome.
  required final BatchContactOutcome outcome,

  /// The created or updated contact.
  final Contact? contact,

  /// Why the entry failed; present only for failures.
  final String? reason,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a result.
  this;

  /// Decodes a result from JSON.
  factory fromJson(JsonMap json) => BatchContactResult(
    position: decodeInt(json['position']),
    email: json['email'] as String? ?? '',
    outcome: decodeEnum(json['outcome'], BatchContactOutcome.new),
    contact: switch (json['contact']) {
      null => null,
      final contact => Contact.fromJson(asJsonMap(contact)),
    },
    reason: json['reason'] as String?,
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'position': position,
    'email': email,
    'outcome': outcome.value,
    'contact': ?contact?.toJson(),
    'reason': ?reason,
  };

  @override
  String toString() =>
      'BatchContactResult(position: $position, '
      'email: $email, outcome: ${outcome.value}'
      '${reason == null ? '' : ', reason: $reason'})';
}

/// The response to a batch upsert: counts and one result per entry.
final class const BatchUpsertContactsResponse({
  /// The number of contacts created.
  required final int created,

  /// The number of contacts updated.
  required final int updated,

  /// The number of failed entries.
  required final int failed,

  /// One result per entry, in request order.
  required final List<BatchContactResult> data,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a response.
  this;

  /// Decodes a response from JSON.
  factory fromJson(JsonMap json) => BatchUpsertContactsResponse(
    created: decodeInt(json['created'] ?? 0),
    updated: decodeInt(json['updated'] ?? 0),
    failed: decodeInt(json['failed'] ?? 0),
    data: decodeList(json['data'], BatchContactResult.fromJson),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'list',
    'created': created,
    'updated': updated,
    'failed': failed,
    'data': [for (final r in data) r.toJson()],
  };

  @override
  String toString() =>
      'BatchUpsertContactsResponse(created: $created, '
      'updated: $updated, failed: $failed)';
}
