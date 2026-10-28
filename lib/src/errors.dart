import 'dart:convert';

/// Base class for every error thrown by this package.
///
/// Branch on the subtype rather than on [message]: the API sends no stable
/// machine-readable error code, and its messages may change.
///
/// ```dart
/// try {
///   await client.messages.create(request);
/// } on RateLimitException catch (e) {
///   print('Slow down, retry after ${e.retryAfter}');
/// } on ApiException catch (e) {
///   print('API error ${e.statusCode}: ${e.message}');
/// } on NetworkException catch (e) {
///   print('Network problem: ${e.message}');
/// }
/// ```
sealed class const AhaSendException(
  /// A human-readable description of the error.
  final String message,
) implements Exception {
  /// Creates an exception with [message].
  this;

  @override
  String toString() => '${_name(this)}: $message';
}

/// The API answered with a non-success HTTP status.
///
/// The subclasses cover the statuses the API documents. Other statuses are
/// reported as a plain [ApiException].
class const ApiException({
  /// The HTTP status code.
  required final int statusCode,
  required String message,

  /// The value of the `X-Request-Id` response header, if the API sent one.
  final String? requestId,

  /// The raw response body.
  ///
  /// It can echo parts of the request, so log it with care.
  final String? body,

  /// The response headers, with lowercase names.
  final Map<String, String> headers = const {},
}) extends AhaSendException {
  /// Creates an exception for an API error response.
  this : super(message);

  /// Creates the most specific [ApiException] subclass for [statusCode].
  factory fromResponse({
    required int statusCode,
    required Map<String, String> headers,
    required String body,
  }) {
    final message = _extractMessage(body) ?? 'HTTP $statusCode';
    final requestId = headers['x-request-id'];
    final retryAfter = parseRetryAfter(headers['retry-after']);
    return switch (statusCode) {
      400 => BadRequestException(
        message: message,
        requestId: requestId,
        body: body,
        headers: headers,
      ),
      401 => AuthenticationException(
        message: message,
        requestId: requestId,
        body: body,
        headers: headers,
      ),
      403 => PermissionDeniedException(
        message: message,
        requestId: requestId,
        body: body,
        headers: headers,
      ),
      404 => NotFoundException(
        message: message,
        requestId: requestId,
        body: body,
        headers: headers,
      ),
      // The API marks an in-progress idempotent execution with exactly
      // this header tuple; the message is not a stable discriminator.
      409
          when headers['idempotent-replayed'] == 'false' &&
              retryAfter != null =>
        IdempotencyConflictException(
          message: message,
          retryAfter: retryAfter,
          requestId: requestId,
          body: body,
          headers: headers,
        ),
      409 => ConflictException(
        message: message,
        retryAfter: retryAfter,
        requestId: requestId,
        body: body,
        headers: headers,
      ),
      422 => UnprocessableEntityException(
        message: message,
        requestId: requestId,
        body: body,
        headers: headers,
      ),
      429 => RateLimitException(
        message: message,
        retryAfter: retryAfter,
        requestId: requestId,
        body: body,
        headers: headers,
      ),
      >= 500 => ServerException(
        statusCode: statusCode,
        message: message,
        retryAfter: retryAfter,
        requestId: requestId,
        body: body,
        headers: headers,
      ),
      _ => ApiException(
        statusCode: statusCode,
        message: message,
        requestId: requestId,
        body: body,
        headers: headers,
      ),
    };
  }

  @override
  String toString() {
    final id = requestId == null ? '' : ' (request $requestId)';
    return '${_name(this)}: HTTP $statusCode: $message$id';
  }

  static String? _extractMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(body);
      if (decoded case {'message': final String message}) return message;
    } on FormatException {
      // Not JSON, fall through.
    }
    return null;
  }
}

/// HTTP 400: the request was malformed or failed validation.
class const BadRequestException({
  required super.message,
  super.requestId,
  super.body,
  super.headers,
}) extends ApiException {
  /// Creates a [BadRequestException].
  this : super(statusCode: 400);
}

/// HTTP 401: the API key is missing, malformed or revoked.
class const AuthenticationException({
  required super.message,
  super.requestId,
  super.body,
  super.headers,
}) extends ApiException {
  /// Creates an [AuthenticationException].
  this : super(statusCode: 401);
}

/// HTTP 403: the API key lacks a scope, or the caller's IP is not on the
/// key's allow list.
class const PermissionDeniedException({
  required super.message,
  super.requestId,
  super.body,
  super.headers,
}) extends ApiException {
  /// Creates a [PermissionDeniedException].
  this : super(statusCode: 403);
}

/// HTTP 404: the resource does not exist or is not visible to this key.
class const NotFoundException({
  required super.message,
  super.requestId,
  super.body,
  super.headers,
}) extends ApiException {
  /// Creates a [NotFoundException].
  this : super(statusCode: 404);
}

/// HTTP 409: the request conflicts with the current state of a resource.
class const ConflictException({
  required super.message,

  /// How long to wait before retrying, if the API said so.
  final Duration? retryAfter,
  super.requestId,
  super.body,
  super.headers,
}) extends ApiException {
  /// Creates a [ConflictException].
  this : super(statusCode: 409);
}

/// HTTP 409 for a request whose idempotency key belongs to an execution that
/// is still in progress.
///
/// Retry the unchanged request with the same key after [retryAfter].
class const IdempotencyConflictException({
  required super.message,
  required Duration super.retryAfter,
  super.requestId,
  super.body,
  super.headers,
}) extends ConflictException {
  /// Creates an [IdempotencyConflictException].
  this;

  @override
  Duration get retryAfter => super.retryAfter!;
}

/// HTTP 422: the request was understood but cannot be processed, for
/// example because an idempotency key was reused with a different payload.
class const UnprocessableEntityException({
  required super.message,
  super.requestId,
  super.body,
  super.headers,
}) extends ApiException {
  /// Creates an [UnprocessableEntityException].
  this : super(statusCode: 422);
}

/// HTTP 429: too many requests.
class const RateLimitException({
  required super.message,

  /// How long to wait before retrying, from the `Retry-After` header.
  final Duration? retryAfter,
  super.requestId,
  super.body,
  super.headers,
}) extends ApiException {
  /// Creates a [RateLimitException].
  this : super(statusCode: 429);
}

/// HTTP 5xx: the API failed to handle the request.
class const ServerException({
  required super.statusCode,
  required super.message,

  /// How long to wait before retrying, if the API said so.
  final Duration? retryAfter,
  super.requestId,
  super.body,
  super.headers,
}) extends ApiException {
  /// Creates a [ServerException].
  this;
}

/// The request did not complete: the connection failed or timed out.
class const NetworkException(
  super.message, {

  /// The underlying error, if any.
  final Object? cause,

  /// Whether the request timed out.
  final bool isTimeout = false,
}) extends AhaSendException {
  /// Creates a [NetworkException].
  this;
}

/// The API answered with a success status but a body this package could not
/// decode.
class const UnexpectedResponseException(
  super.message, {

  /// The HTTP status code.
  required final int statusCode,

  /// The raw response body.
  final String? body,

  /// The underlying decoding error.
  final Object? cause,
}) extends AhaSendException {
  /// Creates an [UnexpectedResponseException].
  this;
}

/// The SDK was used incorrectly, for example by calling an account endpoint
/// without an account ID. No request was sent.
class const InvalidUsageException(super.message) extends AhaSendException {
  /// Creates an [InvalidUsageException].
  this;
}

/// The class name for `toString`. `runtimeType` is not used because
/// compiling for the web shortens class names.
String _name(AhaSendException e) => switch (e) {
  BadRequestException() => 'BadRequestException',
  AuthenticationException() => 'AuthenticationException',
  PermissionDeniedException() => 'PermissionDeniedException',
  NotFoundException() => 'NotFoundException',
  IdempotencyConflictException() => 'IdempotencyConflictException',
  ConflictException() => 'ConflictException',
  UnprocessableEntityException() => 'UnprocessableEntityException',
  RateLimitException() => 'RateLimitException',
  ServerException() => 'ServerException',
  ApiException() => 'ApiException',
  NetworkException() => 'NetworkException',
  UnexpectedResponseException() => 'UnexpectedResponseException',
  InvalidUsageException() => 'InvalidUsageException',
};

/// Parses a `Retry-After` header given in whole seconds.
///
/// Returns `null` for a missing or unparseable value.
Duration? parseRetryAfter(String? value) {
  if (value == null) return null;
  final seconds = int.tryParse(value.trim());
  if (seconds == null || seconds < 0) return null;
  return Duration(seconds: seconds);
}
