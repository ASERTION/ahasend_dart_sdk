/// Base class for every exception thrown by the webhook library.
///
/// Catch the subtypes to tell the cases apart:
///
/// - [WebhookVerificationException]: the delivery could not be verified,
///   so it may not come from AhaSend. Answer with an HTTP 4xx status and
///   do not process it.
/// - [InvalidPayloadException]: the delivery is authentic, but its body is
///   not a payload this version of the package can decode. Retrying will
///   not help, so store the body for a look later and answer with a 2xx
///   status. AhaSend disables a webhook after many failed deliveries.
abstract final class const WebhookException(
  /// A description of the problem.
  final String message,
) implements Exception {
  /// Creates the exception with a [message].
  this;

  @override
  String toString() => '${_name(this)}: $message';
}

/// Thrown when a webhook delivery cannot be verified: a header is missing,
/// no signature matches, or the timestamp is too old or too new.
///
/// Answer such a delivery with an HTTP 4xx status and do not process it.
abstract final class const WebhookVerificationException(super.message)
    extends WebhookException {
  /// Creates the exception with a [message].
  this;
}

/// A required header, such as `webhook-signature`, is missing or empty.
final class MissingHeaderException(
  /// The lower-case name of the missing header.
  final String header,
) extends WebhookVerificationException {
  /// Creates the exception for the missing [header].
  this : super('Missing header "$header".');
}

/// No signature in `webhook-signature` matches the payload, or the
/// signature headers are malformed.
final class const InvalidSignatureException([
  super.message = 'No signature matches the payload.',
]) extends WebhookVerificationException {
  /// Creates the exception.
  this;
}

/// The `webhook-timestamp` is further from the current time than the
/// verifier's tolerance, in the past or in the future.
///
/// This protects against replayed deliveries.
final class TimestampOutOfToleranceException({
  /// The time from the `webhook-timestamp` header.
  required final DateTime timestamp,

  /// The current time when the delivery was checked.
  required final DateTime now,

  /// The allowed difference between [timestamp] and [now].
  required final Duration tolerance,
}) extends WebhookVerificationException {
  /// Creates the exception.
  this
    : super(
        'Timestamp ${timestamp.toUtc().toIso8601String()} is more than '
        '${tolerance.inSeconds}s away from '
        '${now.toUtc().toIso8601String()}.',
      );
}

/// The body is not a valid webhook payload, for example not JSON or
/// without a `type`.
///
/// When `WebhookVerifier.verify` throws it, the signature was valid: the
/// delivery comes from AhaSend, but this version of the package cannot
/// decode it.
final class const InvalidPayloadException(
  super.message, {

  /// The underlying error, if any.
  final Object? cause,
}) extends WebhookException {
  /// Creates the exception.
  this;
}

/// The class name for [WebhookException.toString]. `runtimeType` is not
/// used because compiling for the web shortens class names.
String _name(WebhookException e) => switch (e) {
  MissingHeaderException() => 'MissingHeaderException',
  InvalidSignatureException() => 'InvalidSignatureException',
  TimestampOutOfToleranceException() => 'TimestampOutOfToleranceException',
  InvalidPayloadException() => 'InvalidPayloadException',
  _ => 'WebhookException',
};
