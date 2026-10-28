import 'package:meta/meta.dart';

import '../errors.dart';
import '../http/request_options.dart';
import '../http/transport.dart';
import '../json.dart';
import '../pagination.dart';

/// Base class for the API resource groups, such as `client.messages`.
abstract class Resource(
  /// The transport that sends requests.
  @protected final Transport transport,

  /// The account the requests act on, or `null` if none was configured.
  @protected final String? accountId,
) {
  /// Creates a resource bound to [transport] and [accountId].
  @internal
  this;

  /// The path prefix for account endpoints: `/v2/accounts/{account_id}`.
  ///
  /// Throws an [InvalidUsageException] when no account ID was configured.
  @protected
  String get accountPath {
    final id = accountId;
    if (id == null || id.isEmpty) {
      throw const InvalidUsageException(
        'This endpoint needs an account ID. Pass accountId to AhaSendClient '
        'or use client.forAccount(id).',
      );
    }
    return '/v2/accounts/${encodePathSegment(id)}';
  }

  /// Returns [body], or throws an [InvalidUsageException] when it is empty.
  ///
  /// For update requests the API rejects without at least one field.
  @protected
  JsonMap requireFields(JsonMap body) {
    if (body.isEmpty) {
      throw const InvalidUsageException(
        'The update request sets no field. Set at least one.',
      );
    }
    return body;
  }

  /// Percent-encodes a path parameter.
  @protected
  String segment(String value) => encodePathSegment(value);

  /// Sends a request and returns the decoded JSON.
  @protected
  Future<Object?> sendRequest(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    bool idempotent = false,
    RequestOptions? options,
  }) => transport.request(
    method,
    path,
    query: query,
    body: body,
    idempotent: idempotent,
    options: options,
  );

  /// Sends a request and decodes the JSON object with [fromJson].
  @protected
  Future<T> sendAndDecode<T>(
    String method,
    String path,
    T Function(JsonMap json) fromJson, {
    Map<String, Object?>? query,
    Object? body,
    bool idempotent = false,
    RequestOptions? options,
  }) async {
    final json = await sendRequest(
      method,
      path,
      query: query,
      body: body,
      idempotent: idempotent,
      options: options,
    );
    return decodeResponse<T>(json, fromJson);
  }

  /// Fetches one page of a cursor-paginated list.
  ///
  /// [query] must not contain `after` or `before`; they are added from
  /// [after] and [before], and from the cursors when the page's
  /// `nextPage()` or `previousPage()` is called.
  @protected
  Future<CursorPage<T>> fetchPage<T>(
    String path,
    T Function(JsonMap json) fromJson, {
    Map<String, Object?> query = const {},
    String? after,
    String? before,
    RequestOptions? options,
  }) async {
    final json = await sendRequest(
      'GET',
      path,
      query: {...query, 'after': after, 'before': before},
      options: options,
    );
    return decodeResponse<CursorPage<T>>(
      json,
      (map) => CursorPage.fromJson(
        map,
        fromJson,
        fetchAfter: (cursor) => fetchPage(
          path,
          fromJson,
          query: query,
          after: cursor,
          options: options,
        ),
        fetchBefore: (cursor) => fetchPage(
          path,
          fromJson,
          query: query,
          before: cursor,
          options: options,
        ),
        fetchedBefore: before != null,
      ),
    );
  }

  /// Iterates over every item of a cursor-paginated list.
  @protected
  Stream<T> fetchAll<T>(
    String path,
    T Function(JsonMap json) fromJson, {
    Map<String, Object?> query = const {},
    RequestOptions? options,
  }) async* {
    final first = await fetchPage(
      path,
      fromJson,
      query: query,
      options: options,
    );
    yield* first.autoPaginate();
  }

  /// Fetches an unpaginated list response (`{"object": "list", "data": [...]}`).
  @protected
  Future<List<T>> fetchList<T>(
    String path,
    T Function(JsonMap json) fromJson, {
    Map<String, Object?>? query,
    RequestOptions? options,
  }) async {
    final json = await sendRequest('GET', path, query: query, options: options);
    return decodeResponse<List<T>>(
      json,
      (map) => decodeList(map['data'], fromJson),
    );
  }

  /// Decodes [json] with [fromJson], reporting decoding errors as
  /// [UnexpectedResponseException].
  @protected
  T decodeResponse<T>(Object? json, T Function(JsonMap json) fromJson) {
    try {
      return fromJson(asJsonMap(json));
    } on Object catch (e) {
      if (e is AhaSendException) rethrow;
      throw UnexpectedResponseException(
        'Could not decode the response: $e',
        statusCode: 200,
        cause: e,
      );
    }
  }
}
