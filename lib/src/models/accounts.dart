import '../json.dart';

/// The role of a member in an account.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const AccountMemberRole(
  /// The string the API uses for this value.
  String value,
) {
  /// Full access to the account.
  static const AccountMemberRole administrator = AccountMemberRole(
    'Administrator',
  );

  /// Developer access.
  static const AccountMemberRole developer = AccountMemberRole('Developer');

  /// Read-only analytics access.
  static const AccountMemberRole analyst = AccountMemberRole('Analyst');

  /// Billing access.
  static const AccountMemberRole billingManager = AccountMemberRole(
    'Billing Manager',
  );

  /// Every value this version of the package knows.
  static const List<AccountMemberRole> values = [
    administrator,
    developer,
    analyst,
    billingManager,
  ];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// An AhaSend account and its default settings.
final class const Account({
  /// The ID of the account.
  required final String id,

  /// When the account was created.
  required final DateTime createdAt,

  /// When the account was last updated.
  required final DateTime updatedAt,

  /// The account name.
  required final String name,

  /// The account website, as a bare domain such as `acme.com`.
  required final String website,

  /// The account description.
  required final String about,

  /// Whether open tracking is on by default.
  required final bool trackOpens,

  /// Whether click tracking is on by default.
  required final bool trackClicks,

  /// Whether bad recipients are rejected.
  required final bool rejectBadRecipients,

  /// Whether mistyped recipients are rejected.
  required final bool rejectMistypedRecipients,

  /// The default message metadata retention in days.
  required final int messageMetadataRetention,

  /// The default message data retention in days.
  required final int messageDataRetention,

  /// The user ID of the account owner.
  required final String ownerId,

  /// The ID of the parent account, when this is a sub-account.
  final String? parentAccountId,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates an account.
  this;

  /// Decodes an account from JSON.
  factory fromJson(JsonMap json) => Account(
    id: json['id'] as String,
    parentAccountId: json['parent_account_id'] as String?,
    createdAt: decodeDateTime(json['created_at']),
    updatedAt: decodeDateTime(json['updated_at']),
    name: json['name'] as String,
    website: json['website'] as String? ?? '',
    about: json['about'] as String? ?? '',
    trackOpens: json['track_opens'] as bool? ?? false,
    trackClicks: json['track_clicks'] as bool? ?? false,
    rejectBadRecipients: json['reject_bad_recipients'] as bool? ?? false,
    rejectMistypedRecipients:
        json['reject_mistyped_recipients'] as bool? ?? false,
    messageMetadataRetention:
        decodeIntOrNull(json['message_metadata_retention']) ?? 0,
    messageDataRetention: decodeIntOrNull(json['message_data_retention']) ?? 0,
    ownerId: json['owner_id'] as String,
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'account',
    'id': id,
    'parent_account_id': parentAccountId,
    'created_at': encodeDateTime(createdAt),
    'updated_at': encodeDateTime(updatedAt),
    'name': name,
    'website': website,
    'about': about,
    'track_opens': trackOpens,
    'track_clicks': trackClicks,
    'reject_bad_recipients': rejectBadRecipients,
    'reject_mistyped_recipients': rejectMistypedRecipients,
    'message_metadata_retention': messageMetadataRetention,
    'message_data_retention': messageDataRetention,
    'owner_id': ownerId,
  };

  @override
  String toString() => 'Account(id: $id, name: $name)';
}

/// A request to update account settings. Fields left `null` are not
/// changed.
final class const UpdateAccountRequest({
  /// The account name, at most 255 characters.
  final String? name,

  /// The website, as a domain or an http(s) URL. Only the host is stored.
  final String? website,

  /// The account description, used for account verification.
  final String? about,

  /// Whether open tracking is on by default.
  final bool? trackOpens,

  /// Whether click tracking is on by default.
  final bool? trackClicks,

  /// Whether to reject bad recipients.
  final bool? rejectBadRecipients,

  /// Whether to reject mistyped recipients.
  final bool? rejectMistypedRecipients,

  /// The default message metadata retention in days, 1 to 30.
  final int? messageMetadataRetention,

  /// The default message data retention in days, 0 to 30.
  final int? messageDataRetention,
}) {
  /// Creates a request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'name': ?name,
    'website': ?website,
    'about': ?about,
    'track_opens': ?trackOpens,
    'track_clicks': ?trackClicks,
    'reject_bad_recipients': ?rejectBadRecipients,
    'reject_mistyped_recipients': ?rejectMistypedRecipients,
    'message_metadata_retention': ?messageMetadataRetention,
    'message_data_retention': ?messageDataRetention,
  };
}

/// The membership of a user in an account.
final class const UserAccount({
  /// When the membership was created.
  required final DateTime createdAt,

  /// When the membership was last updated.
  required final DateTime updatedAt,

  /// The ID of the user.
  required final String userId,

  /// The ID of the account.
  required final String accountId,

  /// The user's role in the account.
  required final AccountMemberRole role,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a membership.
  this;

  /// Decodes a membership from JSON.
  factory fromJson(JsonMap json) => UserAccount(
    createdAt: decodeDateTime(json['created_at']),
    updatedAt: decodeDateTime(json['updated_at']),
    userId: json['user_id'] as String,
    accountId: json['account_id'] as String,
    role: decodeEnum(json['role'], AccountMemberRole.new),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'created_at': encodeDateTime(createdAt),
    'updated_at': encodeDateTime(updatedAt),
    'user_id': userId,
    'account_id': accountId,
    'role': role.value,
  };

  @override
  String toString() => 'UserAccount(userId: $userId, role: ${role.value})';
}

/// A request to add a member to an account.
final class const AddMemberRequest({
  /// The email address of the user to add.
  required final String email,

  /// The role to assign.
  required final AccountMemberRole role,

  /// The display name of the user.
  final String? name,
}) {
  /// Creates a request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {'email': email, 'name': ?name, 'role': role.value};
}
