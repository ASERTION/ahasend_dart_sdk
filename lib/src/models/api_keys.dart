import '../json.dart';

/// A scope granted to an API key.
final class const ApiKeyScope({
  /// The ID of the scope.
  required final String id,

  /// When the scope was created.
  required final DateTime createdAt,

  /// When the scope was last updated.
  required final DateTime updatedAt,

  /// The ID of the API key this scope belongs to.
  required final String apiKeyId,

  /// The scope string, for example `messages:send:all`.
  required final String scope,

  /// The domain ID for domain-specific scopes; `null` for other scopes.
  final String? domainId,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates an API key scope.
  this;

  /// Decodes an API key scope from JSON.
  factory fromJson(JsonMap json) => ApiKeyScope(
    id: json['id'] as String,
    createdAt: decodeDateTime(json['created_at']),
    updatedAt: decodeDateTime(json['updated_at']),
    apiKeyId: json['api_key_id'] as String,
    scope: json['scope'] as String,
    domainId: json['domain_id'] as String?,
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'id': id,
    'created_at': encodeDateTime(createdAt),
    'updated_at': encodeDateTime(updatedAt),
    'api_key_id': apiKeyId,
    'scope': scope,
    'domain_id': domainId,
  };

  @override
  String toString() => 'ApiKeyScope($scope)';
}

/// An API key of an account. The secret is never part of this object;
/// it is only returned once, as [CreatedApiKey.secretKey].
final class const ApiKey({
  /// The ID of the API key.
  required final String id,

  /// When the API key was created.
  required final DateTime createdAt,

  /// When the API key was last updated.
  required final DateTime updatedAt,

  /// The ID of the account the key belongs to.
  required final String accountId,

  /// The human-readable label.
  required final String label,

  /// The public part of the key.
  required final String publicKey,

  /// The scopes granted to the key.
  required final List<ApiKeyScope> scopes,

  /// The source IPs allowed to use the key, as canonical CIDR blocks.
  ///
  /// Empty means the key may be used from any IP. Otherwise requests from
  /// other IPs are rejected with HTTP 403.
  required final List<String> ipAllowList,

  /// When the API key was last used. Updated every 5 to 10 minutes.
  final DateTime? lastUsedAt,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates an API key.
  this;

  /// Decodes an API key from JSON.
  factory fromJson(JsonMap json) => ApiKey(
    id: json['id'] as String,
    createdAt: decodeDateTime(json['created_at']),
    updatedAt: decodeDateTime(json['updated_at']),
    lastUsedAt: decodeDateTimeOrNull(json['last_used_at']),
    accountId: json['account_id'] as String,
    label: json['label'] as String,
    publicKey: json['public_key'] as String,
    scopes: decodeList(json['scopes'], ApiKeyScope.fromJson),
    ipAllowList: decodeScalarList<String>(json['ip_allow_list']),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'api_key',
    'id': id,
    'created_at': encodeDateTime(createdAt),
    'updated_at': encodeDateTime(updatedAt),
    'last_used_at': encodeDateTimeOrNull(lastUsedAt),
    'account_id': accountId,
    'label': label,
    'public_key': publicKey,
    'scopes': [for (final e in scopes) e.toJson()],
    'ip_allow_list': ipAllowList,
  };

  @override
  String toString() {
    final className = this is CreatedApiKey ? 'CreatedApiKey' : 'ApiKey';
    return '$className(id: $id, label: $label, publicKey: $publicKey)';
  }
}

/// A newly created API key, returned by `apiKeys.create` and
/// `subAccounts.apiKeys.create`. It carries the one-time [secretKey].
final class const CreatedApiKey({
  required super.id,
  required super.createdAt,
  required super.updatedAt,
  required super.accountId,
  required super.label,
  required super.publicKey,
  required super.scopes,
  required super.ipAllowList,

  /// The secret key. It is returned only once, so store it immediately.
  ///
  /// Exact idempotent replays within five minutes return the same secret.
  /// It is not included in [toString].
  required final String secretKey,
  super.lastUsedAt,
  super.raw,
}) extends ApiKey {
  /// Creates a created API key.
  this;

  /// Decodes a created API key from JSON.
  factory fromJson(JsonMap json) {
    final key = ApiKey.fromJson(json);
    return CreatedApiKey(
      id: key.id,
      createdAt: key.createdAt,
      updatedAt: key.updatedAt,
      lastUsedAt: key.lastUsedAt,
      accountId: key.accountId,
      label: key.label,
      publicKey: key.publicKey,
      scopes: key.scopes,
      ipAllowList: key.ipAllowList,
      secretKey: json['secret_key'] as String,
      raw: json,
    );
  }

  @override
  JsonMap toJson() => {...super.toJson(), 'secret_key': secretKey};
}

/// A request to create an API key.
final class const CreateApiKeyRequest({
  /// The human-readable label, 1 to 255 characters.
  required final String label,

  /// The scopes to grant, at least one.
  required final List<String> scopes,

  /// The source IPs allowed to use the key, as CIDR blocks or bare
  /// addresses. At most 100 entries; `0.0.0.0/0` and `::/0` are rejected.
  /// Omit or leave empty to allow any IP.
  final List<String>? ipAllowList,
}) {
  /// Creates a request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'label': label,
    'scopes': scopes,
    'ip_allow_list': ?ipAllowList,
  };
}

/// A request to update an API key.
///
/// Fields left `null` are not changed. Provide at least one field, and at
/// least one value must differ from the current one.
final class const UpdateApiKeyRequest({
  /// The new label, 1 to 255 characters.
  final String? label,

  /// The new scopes, at least one. Replaces the current scopes.
  final List<String>? scopes,

  /// The new list of allowed source IPs, replacing the current one.
  ///
  /// Leave `null` to keep the current list. Pass an empty list to clear it,
  /// so the key can be used from any IP. Updating the calling key with a
  /// list that excludes the caller's IP fails with HTTP 409.
  final List<String>? ipAllowList,
}) {
  /// Creates a request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'label': ?label,
    'scopes': ?scopes,
    'ip_allow_list': ?ipAllowList,
  };
}
