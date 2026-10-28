import '../json.dart';

/// The generic response of operations that only confirm success, such as
/// deletes.
final class const SuccessResponse({
  /// The confirmation message.
  required final String message,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a success response.
  this;

  /// Decodes a success response from JSON.
  factory fromJson(JsonMap json) =>
      SuccessResponse(message: json['message'] as String? ?? '', raw: json);

  /// Encodes this object as JSON.
  JsonMap toJson() => {'message': message};

  @override
  String toString() => 'SuccessResponse(message: $message)';
}

/// An email address with an optional display name.
final class const Address({
  /// The email address. A `from` address must be on a domain of the account
  /// with valid DNS records.
  required final String email,

  /// The display name shown with the address.
  final String? name,
}) {
  /// Creates an address.
  this;

  /// Decodes an address from JSON.
  factory fromJson(JsonMap json) =>
      Address(email: json['email'] as String, name: json['name'] as String?);

  /// Encodes this object as JSON.
  JsonMap toJson() => {'email': email, 'name': ?name};

  @override
  bool operator ==(Object other) =>
      other is Address && other.email == email && other.name == name;

  @override
  int get hashCode => Object.hash(email, name);

  @override
  String toString() => name == null ? email : '$name <$email>';
}
