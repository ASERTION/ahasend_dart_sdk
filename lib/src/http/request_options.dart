/// Per-request settings that override the client's defaults.
///
/// ```dart
/// await client.messages.create(
///   request,
///   options: RequestOptions(idempotencyKey: 'order-1234-receipt'),
/// );
/// ```
final class const RequestOptions({
  /// The idempotency key to send.
  ///
  /// Only used by operations that support idempotency. When it is `null`,
  /// the client generates a random key for those operations and reuses it
  /// across its own retries. Derive the key from a stable business
  /// identifier (an order number, say) to make retries safe across process
  /// restarts as well.
  final String? idempotencyKey,

  /// An API key to use instead of the client's key.
  final String? apiKey,

  /// A timeout to use instead of the client's timeout.
  final Duration? timeout,

  /// Extra headers to send.
  final Map<String, String> headers = const {},

  /// Called with details of the final HTTP response, before it is decoded.
  ///
  /// Use it to read headers such as `Idempotent-Replayed`.
  final void Function(ResponseInfo info)? onResponse,
}) {
  /// Creates per-request options.
  this;
}

/// Details of an HTTP response, passed to [RequestOptions.onResponse].
final class const ResponseInfo({
  /// The HTTP status code.
  required final int statusCode,

  /// The response headers, with lowercase names.
  required final Map<String, String> headers,

  /// The idempotency key that was sent, if any.
  final String? idempotencyKey,

  /// How many attempts the request took, including retries.
  final int attempts = 1,
}) {
  /// Creates response details.
  this;

  /// Whether the API replayed a stored response for this idempotency key
  /// (`Idempotent-Replayed: true`).
  bool get idempotentReplayed => headers['idempotent-replayed'] == 'true';

  /// The `X-Request-Id` response header, if present.
  String? get requestId => headers['x-request-id'];
}
