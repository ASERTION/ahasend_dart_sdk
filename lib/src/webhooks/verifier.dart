import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'events.dart';
import 'exceptions.dart';

/// Verifies the signatures of webhook and route deliveries.
///
/// AhaSend signs deliveries with the Standard Webhooks scheme: the
/// `webhook-signature` header holds `v1,<base64 HMAC-SHA256>` of
/// `{webhook-id}.{webhook-timestamp}.{body}`. Unlike some Standard Webhooks
/// libraries, the HMAC key is the literal UTF-8 text of the secret,
/// including its `aha-whsec-` or `aha-rsec-` prefix.
///
/// Pass the exact bytes of the request body. Parsing and re-encoding the
/// JSON changes the bytes and breaks the signature.
///
/// ```dart
/// final verifier = WebhookVerifier(webhookSecret);
/// try {
///   final event = verifier.verify(body: rawBody, headers: request.headers);
///   // Handle the event, then answer 2xx.
/// } on WebhookVerificationException {
///   // Not verified: answer 400 and drop the delivery.
/// } on InvalidPayloadException {
///   // Authentic, but not decodable: store the body and answer 2xx.
/// }
/// ```
final class WebhookVerifier(
  String secret, {

  /// The largest allowed difference between the delivery timestamp and the
  /// current time, in either direction.
  final Duration tolerance = const Duration(minutes: 5),
  DateTime Function()? clock,
}) {
  /// Creates a verifier for [secret], the `secret` returned when the
  /// webhook or route was created.
  ///
  /// Deliveries whose timestamp is more than [tolerance] away from the
  /// current time are rejected. [clock] returns the current time and
  /// defaults to [DateTime.now]; override it in tests.
  this {
    if (tolerance.isNegative) {
      throw ArgumentError.value(tolerance, 'tolerance', 'Must not be negative');
    }
  }

  /// The name of the header with the delivery ID.
  static const String idHeader = 'webhook-id';

  /// The name of the header with the Unix timestamp in seconds.
  static const String timestampHeader = 'webhook-timestamp';

  /// The name of the header with the signatures.
  static const String signatureHeader = 'webhook-signature';

  static final RegExp _timestampPattern = RegExp(r'^\d{1,12}$');
  static final RegExp _separators = RegExp(r'[\s,]+');

  // Validates the secret before the tolerance, as before. The HMAC holds
  // the prepared key, so it is built once and reused for every delivery.
  final Hmac _hmac = _hmacFor(secret);
  final DateTime Function() _clock = clock ?? DateTime.now;

  /// Verifies a delivery and parses its body into a [WebhookEvent].
  ///
  /// [body] is the raw request body. [headers] are the request headers;
  /// names are matched case-insensitively. When the framework hands you
  /// the body as bytes, use [verifyBytes].
  ///
  /// Throws a [WebhookVerificationException] ([MissingHeaderException],
  /// [InvalidSignatureException] or [TimestampOutOfToleranceException])
  /// when verification fails, and an [InvalidPayloadException] when the
  /// delivery is authentic but its body is not a payload this version of
  /// the package can decode.
  WebhookEvent verify({
    required String body,
    required Map<String, String> headers,
  }) {
    verifySignature(body: body, headers: headers);
    return WebhookEvent.parse(body);
  }

  /// Like [verify], for a body given as the raw bytes of the request.
  WebhookEvent verifyBytes({
    required List<int> body,
    required Map<String, String> headers,
  }) {
    verifySignatureBytes(body: body, headers: headers);
    final String text;
    try {
      text = utf8.decode(body);
    } on FormatException catch (e) {
      throw InvalidPayloadException('The body is not valid UTF-8.', cause: e);
    }
    return WebhookEvent.parse(text);
  }

  /// Verifies the signature and timestamp of a delivery without parsing
  /// its body.
  ///
  /// Takes the same arguments and throws the same exceptions as [verify],
  /// except [InvalidPayloadException].
  void verifySignature({
    required String body,
    required Map<String, String> headers,
  }) => verifySignatureBytes(body: utf8.encode(body), headers: headers);

  /// Like [verifySignature], for a body given as the raw bytes of the
  /// request.
  void verifySignatureBytes({
    required List<int> body,
    required Map<String, String> headers,
  }) {
    final id = _header(headers, idHeader);
    final timestampText = _header(headers, timestampHeader);
    final signatures = _header(headers, signatureHeader);

    if (!_timestampPattern.hasMatch(timestampText)) {
      throw const InvalidSignatureException(
        'The "webhook-timestamp" header is not a Unix timestamp in seconds.',
      );
    }
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      int.parse(timestampText) * 1000,
      isUtc: true,
    );
    final now = _clock();
    if (now.difference(timestamp).abs() > tolerance) {
      throw TimestampOutOfToleranceException(
        timestamp: timestamp,
        now: now,
        tolerance: tolerance,
      );
    }

    final expected = _compute(_hmac, id, timestampText, body);
    var matched = false;
    // The header holds space-separated `version,signature` pairs. Some
    // frameworks join repeated headers with commas, so split on both and
    // read the tokens in pairs: base64 never contains a comma.
    final tokens = signatures.split(_separators);
    for (var i = 0; i + 1 < tokens.length; i++) {
      if (tokens[i] != 'v1') continue;
      // Check every candidate so the time taken does not reveal which one
      // matched.
      if (_constantTimeEquals(tokens[++i], expected)) matched = true;
    }
    if (!matched) throw const InvalidSignatureException();
  }

  /// Computes the `webhook-signature` value for a delivery: `v1,` followed
  /// by the base64 signature.
  ///
  /// Use it to build signed test requests for your webhook handler.
  static String sign({
    required String secret,
    required String id,
    required DateTime timestamp,
    required String body,
  }) {
    final hmac = _hmacFor(secret);
    final seconds = _unixSeconds(timestamp);
    return 'v1,${_compute(hmac, id, seconds, utf8.encode(body))}';
  }

  /// Builds the `webhook-id`, `webhook-timestamp` and `webhook-signature`
  /// headers of a signed delivery, for testing webhook handlers.
  static Map<String, String> signedHeaders({
    required String secret,
    required String id,
    required DateTime timestamp,
    required String body,
  }) => {
    idHeader: id,
    timestampHeader: _unixSeconds(timestamp),
    signatureHeader: sign(
      secret: secret,
      id: id,
      timestamp: timestamp,
      body: body,
    ),
  };

  static Hmac _hmacFor(String secret) {
    if (secret.isEmpty) {
      throw ArgumentError.value(secret, 'secret', 'Must not be empty');
    }
    return Hmac(sha256, utf8.encode(secret));
  }

  static String _unixSeconds(DateTime timestamp) =>
      (timestamp.millisecondsSinceEpoch ~/ 1000).toString();

  /// Feeds `{id}.{timestamp}.` and [body] to [hmac] in chunks, so the
  /// body is never copied into a combined buffer.
  static String _compute(
    Hmac hmac,
    String id,
    String timestamp,
    List<int> body,
  ) {
    final sink = _DigestSink();
    hmac.startChunkedConversion(sink)
      ..add(utf8.encode('$id.$timestamp.'))
      ..add(body)
      ..close();
    return base64.encode(sink.digest.bytes);
  }

  static String _header(Map<String, String> headers, String name) {
    for (final MapEntry(:key, :value) in headers.entries) {
      if (key.toLowerCase() == name) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) return trimmed;
      }
    }
    throw MissingHeaderException(name);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

/// Receives the single digest of a chunked HMAC conversion.
final class _DigestSink() implements Sink<Digest> {
  late Digest digest;

  @override
  void add(Digest data) => digest = data;

  @override
  void close() {}
}
