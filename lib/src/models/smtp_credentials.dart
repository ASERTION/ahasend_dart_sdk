import '../json.dart';

/// Which domains an SMTP credential can send from.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const SmtpCredentialScope(
  /// The string the API uses for this value.
  String value,
) {
  /// Every domain of the account.
  static const SmtpCredentialScope global = SmtpCredentialScope('global');

  /// Only the credential's [SmtpCredential.domains].
  static const SmtpCredentialScope scoped = SmtpCredentialScope('scoped');

  /// Every value this version of the package knows.
  static const List<SmtpCredentialScope> values = [global, scoped];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// A credential for sending through SMTP. The password is never part of
/// this object; it is only returned once, as
/// [CreatedSmtpCredential.password].
final class const SmtpCredential({
  /// The ID of the credential.
  required final String id,

  /// When the credential was created.
  required final DateTime createdAt,

  /// When the credential was last updated.
  required final DateTime updatedAt,

  /// The credential name.
  required final String name,

  /// The SMTP username.
  required final String username,

  /// Whether this is a sandbox credential.
  required final bool sandbox,

  /// Whether the credential is global or scoped to domains.
  required final SmtpCredentialScope scope,

  /// The domains the credential can send from. Empty for global
  /// credentials.
  required final List<String> domains,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates an SMTP credential.
  this;

  /// Decodes an SMTP credential from JSON.
  factory fromJson(JsonMap json) => SmtpCredential(
    id: json['id'] as String,
    createdAt: decodeDateTime(json['created_at']),
    updatedAt: decodeDateTime(json['updated_at']),
    name: json['name'] as String,
    username: json['username'] as String,
    sandbox: json['sandbox'] as bool? ?? false,
    scope: decodeEnum(json['scope'], SmtpCredentialScope.new),
    domains: decodeScalarList<String>(json['domains']),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'credential_smtp',
    'id': id,
    'created_at': encodeDateTime(createdAt),
    'updated_at': encodeDateTime(updatedAt),
    'name': name,
    'username': username,
    'sandbox': sandbox,
    'scope': scope.value,
    'domains': domains,
  };

  @override
  String toString() {
    final className = this is CreatedSmtpCredential
        ? 'CreatedSmtpCredential'
        : 'SmtpCredential';
    return '$className(id: $id, name: $name, '
        'username: $username, scope: ${scope.value})';
  }
}

/// A newly created SMTP credential, returned by `smtpCredentials.create`.
/// It carries the one-time [password].
final class const CreatedSmtpCredential({
  required super.id,
  required super.createdAt,
  required super.updatedAt,
  required super.name,
  required super.username,
  required super.sandbox,
  required super.scope,
  required super.domains,

  /// The SMTP password. It is returned only once, so store it immediately.
  /// It is not included in [toString].
  required final String password,
  super.raw,
}) extends SmtpCredential {
  /// Creates a created SMTP credential.
  this;

  /// Decodes a created SMTP credential from JSON.
  factory fromJson(JsonMap json) {
    final credential = SmtpCredential.fromJson(json);
    return CreatedSmtpCredential(
      id: credential.id,
      createdAt: credential.createdAt,
      updatedAt: credential.updatedAt,
      name: credential.name,
      username: credential.username,
      sandbox: credential.sandbox,
      scope: credential.scope,
      domains: credential.domains,
      password: json['password'] as String,
      raw: json,
    );
  }

  @override
  JsonMap toJson() => {...super.toJson(), 'password': password};
}

/// A request to create an SMTP credential.
final class const CreateSmtpCredentialRequest({
  /// The credential name, at most 255 characters.
  required final String name,

  /// Whether the credential is global or scoped to [domains]. A global
  /// credential requires the `smtp-credentials:write:all` scope.
  required final SmtpCredentialScope scope,

  /// Whether this is a sandbox credential. Defaults to `false`.
  final bool? sandbox,

  /// The domains a scoped credential can send from. Ignored for global
  /// credentials.
  final List<String>? domains,
}) {
  /// Creates a request. A [SmtpCredentialScope.scoped] credential needs at
  /// least one domain in [domains].
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'name': name,
    'sandbox': ?sandbox,
    'scope': scope.value,
    'domains': ?domains,
  };
}
