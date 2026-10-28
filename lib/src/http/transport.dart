import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../errors.dart';
import '../json.dart';
import '../version.dart';
import 'idempotency.dart';
import 'request_options.dart';
import 'retry.dart';

/// Whether the code runs in a browser, where `User-Agent` cannot be set.
const bool _isWeb = bool.fromEnvironment('dart.library.js_interop');

/// Decodes UTF-8 bytes straight into JSON values. The VM has a fast path
/// for this fused converter that skips building an intermediate string.
final Converter<List<int>, Object?> _jsonFromBytes = const Utf8Decoder().fuse(
  const JsonDecoder(),
);

/// Sends HTTP requests to the AhaSend API: builds URLs, adds headers,
/// encodes and decodes JSON, retries and maps errors.
@internal
final class Transport({
  /// The API key sent as a bearer token.
  required final String apiKey,
  required Uri baseUrl,

  /// The HTTP client that sends the requests.
  required final http.Client httpClient,

  /// Whether [close] closes [httpClient].
  required final bool ownsHttpClient,

  /// The timeout for each attempt.
  required final Duration timeout,

  /// How failed requests are retried.
  required final RetryConfig retry,

  /// The `User-Agent` header, not sent in browsers.
  required final String userAgent,

  /// Headers sent with every request.
  final Map<String, String> defaultHeaders = const {},
  Future<void> Function(Duration delay)? sleep,
  Random? random,
}) {
  /// The base URL without trailing slashes, ready for appending paths.
  final String _base = baseUrl.toString().replaceAll(RegExp(r'/+$'), '');
  final Future<void> Function(Duration delay) _sleep =
      sleep ?? Future<void>.delayed;
  final Random? _random = random;

  /// Creates a transport. Used by `AhaSendClient`.
  this;

  /// Sends a request and returns the decoded JSON body (or `null` for an
  /// empty body).
  ///
  /// [path] is appended to the base URL. Path parameters must already be
  /// encoded with [encodePathSegment]. Query values that are `null` are
  /// dropped; lists are joined with commas; [DateTime]s are sent as RFC 3339.
  ///
  /// Set [idempotent] for operations that accept an `Idempotency-Key`.
  Future<Object?> request(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    bool idempotent = false,
    RequestOptions? options,
  }) async {
    final uri = _buildUri(path, query);
    final idempotencyKey = idempotent
        ? (options?.idempotencyKey ?? generateIdempotencyKey())
        : null;
    // Encoding straight to bytes skips the intermediate string.
    final encodedBody = body == null ? null : _encodeJson(body);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer ${options?.apiKey ?? apiKey}',
      if (!_isWeb) 'User-Agent': userAgent,
      if (encodedBody != null)
        'Content-Type': 'application/json; charset=utf-8',
      'Idempotency-Key': ?idempotencyKey,
      ...defaultHeaders,
      ...?options?.headers,
    };
    final requestTimeout = options?.timeout ?? timeout;

    // POSTs without an idempotency key are not safe to repeat once the
    // server may have acted on them.
    final safeToRepeat = method != 'POST' || idempotencyKey != null;

    var attempt = 0;
    while (true) {
      attempt++;
      final http.Response response;
      try {
        response = await _send(
          method,
          uri,
          headers,
          encodedBody,
          requestTimeout,
        );
      } on NetworkException {
        if (safeToRepeat && attempt <= retry.maxRetries) {
          await _sleep(retry.backoff(attempt - 1, _random));
          continue;
        }
        rethrow;
      }

      final responseHeaders = response.headers;
      final status = response.statusCode;
      if (status >= 200 && status < 300) {
        options?.onResponse?.call(
          ResponseInfo(
            statusCode: status,
            headers: responseHeaders,
            idempotencyKey: idempotencyKey,
            attempts: attempt,
          ),
        );
        return _decode(response);
      }

      final error = ApiException.fromResponse(
        statusCode: status,
        headers: responseHeaders,
        body: _bodyText(response.bodyBytes),
      );
      final delay = _retryDelay(error, attempt, safeToRepeat);
      if (delay == null) {
        options?.onResponse?.call(
          ResponseInfo(
            statusCode: status,
            headers: responseHeaders,
            idempotencyKey: idempotencyKey,
            attempts: attempt,
          ),
        );
        throw error;
      }
      await _sleep(delay);
    }
  }

  /// Returns how long to wait before retrying after [error], or `null` when
  /// the request must not be retried.
  Duration? _retryDelay(ApiException error, int attempt, bool safeToRepeat) {
    if (attempt > retry.maxRetries) return null;
    final Duration? retryAfter;
    switch (error) {
      case RateLimitException():
        // A rate-limited request was not processed, so it is always safe.
        retryAfter = error.retryAfter;
      case ServerException() when safeToRepeat:
        retryAfter = error.retryAfter;
      default:
        return null;
    }
    if (retryAfter != null) {
      return retryAfter > retry.maxRetryAfter ? null : retryAfter;
    }
    return retry.backoff(attempt - 1, _random);
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    Uint8List? body,
    Duration requestTimeout,
  ) async {
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.bodyBytes = body;
    try {
      final streamed = await httpClient.send(request).timeout(requestTimeout);
      return await http.Response.fromStream(streamed).timeout(requestTimeout);
    } on TimeoutException catch (e) {
      throw NetworkException(
        'Request timed out after $requestTimeout',
        cause: e,
        isTimeout: true,
      );
    } on http.ClientException catch (e) {
      throw NetworkException(e.message, cause: e);
    }
  }

  /// Decodes a success body. The API always sends UTF-8 JSON, so the bytes
  /// are decoded directly, whatever charset the `Content-Type` names.
  Object? _decode(http.Response response) {
    final bytes = response.bodyBytes;
    if (_isBlank(bytes)) return null;
    try {
      return _jsonFromBytes.convert(bytes);
    } on FormatException catch (e) {
      throw UnexpectedResponseException(
        'Response body is not valid JSON',
        statusCode: response.statusCode,
        body: _bodyText(bytes),
        cause: e,
      );
    }
  }

  Uri _buildUri(String path, Map<String, Object?>? query) {
    final uri = Uri.parse('$_base$path');
    if (query == null) return uri;
    final params = <String, String>{
      for (final MapEntry(:key, :value) in query.entries)
        key: ?encodeQueryValue(value),
    };
    return params.isEmpty ? uri : uri.replace(queryParameters: params);
  }

  /// Returns a transport that shares this transport's HTTP client and
  /// settings, optionally with another [apiKey]. The returned transport
  /// never closes the HTTP client.
  Transport view({String? apiKey}) => Transport(
    apiKey: apiKey ?? this.apiKey,
    baseUrl: Uri.parse(_base),
    httpClient: httpClient,
    ownsHttpClient: false,
    timeout: timeout,
    retry: retry,
    userAgent: userAgent,
    defaultHeaders: defaultHeaders,
    sleep: _sleep,
    random: _random,
  );

  /// Closes the HTTP client if this transport created it.
  void close() {
    if (ownsHttpClient) httpClient.close();
  }
}

Uint8List _encodeJson(Object body) =>
    JsonUtf8Encoder().convert(body) as Uint8List;

/// Decodes an error or unexpected body for display, tolerating bad UTF-8.
String _bodyText(Uint8List bytes) =>
    const Utf8Decoder(allowMalformed: true).convert(bytes);

/// Whether [bytes] are empty or only JSON whitespace.
bool _isBlank(Uint8List bytes) {
  for (final byte in bytes) {
    if (byte != 0x20 && byte != 0x0a && byte != 0x0d && byte != 0x09) {
      return false;
    }
  }
  return true;
}

/// Encodes a value for a query string, or returns `null` to omit it.
@internal
String? encodeQueryValue(Object? value) => switch (value) {
  null => null,
  String() => value,
  bool() || num() => value.toString(),
  DateTime() => encodeDateTime(value),
  Enum(:final name) => name,
  Iterable<Object?>() when value.isEmpty => null,
  Iterable<Object?>() =>
    value.map(encodeQueryValue).whereType<String>().join(','),
  _ => value.toString(),
};

/// Percent-encodes a single path segment, such as an email or a domain.
@internal
String encodePathSegment(String value) => Uri.encodeComponent(value);

/// The default `User-Agent` header value.
@internal
const String defaultUserAgent = 'ahasend-dart/$packageVersion';
