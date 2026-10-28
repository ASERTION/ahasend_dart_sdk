import '../json.dart';

/// A suppressed email address that AhaSend does not send to until
/// [expiresAt].
final class const Suppression({
  /// The suppression ID.
  required final String id,

  /// When the suppression was created.
  required final DateTime createdAt,

  /// The suppressed email address.
  required final String email,

  /// The domain the address is suppressed for.
  required final String domain,

  /// Why the address is suppressed.
  required final String reason,

  /// Whether [SuppressionsResource.deleteAll] keeps this suppression.
  ///
  /// `true` when the recipient decided themselves, by unsubscribing or
  /// reporting spam. Suppressions you create are never protected. It does
  /// not stop the suppression from expiring.
  required final bool protected,

  /// When the suppression expires.
  required final DateTime expiresAt,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a suppression.
  this;

  /// Decodes a suppression from JSON.
  factory fromJson(JsonMap json) => Suppression(
    id: json['id'] as String,
    createdAt: decodeDateTime(json['created_at']),
    email: json['email'] as String,
    domain: json['domain'] as String? ?? '',
    reason: json['reason'] as String? ?? '',
    protected: json['protected'] as bool? ?? false,
    expiresAt: decodeDateTime(json['expires_at']),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'suppression',
    'id': id,
    'created_at': encodeDateTime(createdAt),
    'email': email,
    'domain': domain,
    'reason': reason,
    'protected': protected,
    'expires_at': encodeDateTime(expiresAt),
  };

  @override
  String toString() =>
      'Suppression(id: $id, email: $email, domain: $domain, '
      'reason: $reason, expiresAt: ${encodeDateTime(expiresAt)})';
}

/// A request to suppress an email address.
final class const CreateSuppressionRequest({
  /// The email address to suppress.
  required final String email,

  /// When the suppression expires.
  required final DateTime expiresAt,

  /// The domain to suppress the address for; all account domains when
  /// omitted.
  final String? domain,

  /// Why the address is suppressed, at most 255 characters.
  final String? reason,
}) {
  /// Creates a request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'email': email,
    'domain': ?domain,
    'reason': ?reason,
    'expires_at': encodeDateTime(expiresAt),
  };
}

/// The response to creating a suppression: the suppressions created.
final class const CreateSuppressionResponse({
  /// The created suppressions, one per affected domain.
  required final List<Suppression> data,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a response.
  this;

  /// Decodes a response from JSON.
  factory fromJson(JsonMap json) => CreateSuppressionResponse(
    data: decodeList(json['data'], Suppression.fromJson),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'list',
    'data': [for (final s in data) s.toJson()],
  };

  @override
  String toString() => 'CreateSuppressionResponse($data)';
}
