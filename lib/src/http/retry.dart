import 'dart:math';

/// Controls how the client retries failed requests.
///
/// The client retries network failures, HTTP 429 and HTTP 5xx responses.
/// It waits for the `Retry-After` header when the API sends one, and
/// otherwise backs off exponentially with jitter.
///
/// A POST request is only retried after a 5xx or a network failure when it
/// carries an idempotency key, so a retry cannot send a message twice.
final class const RetryConfig({
  /// How many times a request is retried after the first attempt.
  final int maxRetries = 3,

  /// The delay before the first retry. Each further retry doubles it.
  final Duration baseDelay = const Duration(milliseconds: 500),

  /// The longest computed backoff delay.
  final Duration maxDelay = const Duration(seconds: 30),

  /// The longest `Retry-After` the client waits for. When the API asks for a
  /// longer wait, the error is thrown instead.
  final Duration maxRetryAfter = const Duration(seconds: 60),
}) {
  /// Creates a retry configuration.
  this : assert(maxRetries >= 0, 'maxRetries must not be negative');

  /// A configuration that never retries.
  static const RetryConfig disabled = RetryConfig(maxRetries: 0);

  static final Random _random = Random();

  /// The delay before retry number [attempt] (starting at 0).
  ///
  /// Uses "full jitter": a random delay between zero and the exponential
  /// backoff value, capped at [maxDelay].
  Duration backoff(int attempt, [Random? random]) {
    final cap = maxDelay.inMicroseconds;
    // Shifting past 2^30 cannot change the result once capped, and keeps
    // the value inside the integer range on the web.
    final exponential = baseDelay.inMicroseconds * (1 << min(attempt, 30));
    // Random.nextInt accepts at most 2^32 as its bound.
    final upper = min(min(cap, exponential), 0xffffffff);
    if (upper <= 0) return Duration.zero;
    return Duration(microseconds: (random ?? _random).nextInt(upper + 1));
  }
}
