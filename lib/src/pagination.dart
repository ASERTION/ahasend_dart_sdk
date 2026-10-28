import 'dart:async';

import 'package:meta/meta.dart';

import 'json.dart';

/// Cursor information returned with every page of a list.
final class const PaginationInfo({
  /// Whether more items exist in the requested direction.
  required final bool hasMore,

  /// Pass as `after` to fetch the next page.
  final String? nextCursor,

  /// Pass as `before` to fetch the previous page.
  final String? previousCursor,
}) {
  /// Creates pagination info.
  this;

  /// Decodes pagination info from JSON.
  factory fromJson(JsonMap json) => PaginationInfo(
    hasMore: json['has_more'] as bool? ?? false,
    nextCursor: json['next_cursor'] as String?,
    previousCursor: json['previous_cursor'] as String?,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'has_more': hasMore,
    'next_cursor': ?nextCursor,
    'previous_cursor': ?previousCursor,
  };

  @override
  String toString() =>
      'PaginationInfo(hasMore: $hasMore, '
      'nextCursor: $nextCursor, previousCursor: $previousCursor)';
}

/// One page of a cursor-paginated list.
///
/// ```dart
/// final page = await client.domains.list(limit: 50);
/// for (final domain in page.data) {
///   print(domain.domain);
/// }
/// if (page.hasMore) {
///   final next = await page.nextPage();
/// }
///
/// // Or iterate over every item, fetching pages as needed:
/// await for (final domain in client.domains.listAll()) {
///   print(domain.domain);
/// }
/// ```
final class CursorPage<T>({
  /// The items on this page.
  required final List<T> data,

  /// The cursors for neighbouring pages.
  required final PaginationInfo pagination,
  final Future<CursorPage<T>> Function(String cursor)? _fetchAfter,
  final Future<CursorPage<T>> Function(String cursor)? _fetchBefore,

  /// Whether this page was fetched with a `before` cursor.
  final bool _fetchedBefore = false,
}) {
  /// Creates a page. Used by the resource classes.
  @internal
  this;

  /// Decodes a paginated list response. Used by the resource classes.
  @internal
  factory fromJson(
    Object? json,
    T Function(JsonMap json) fromJson, {
    Future<CursorPage<T>> Function(String cursor)? fetchAfter,
    Future<CursorPage<T>> Function(String cursor)? fetchBefore,
    bool fetchedBefore = false,
  }) {
    final map = asJsonMap(json);
    return CursorPage(
      data: decodeList(map['data'], fromJson),
      pagination: switch (map['pagination']) {
        null => const PaginationInfo(hasMore: false),
        final pagination => PaginationInfo.fromJson(asJsonMap(pagination)),
      },
      fetchAfter: fetchAfter,
      fetchBefore: fetchBefore,
      fetchedBefore: fetchedBefore,
    );
  }

  /// Whether another page follows this one.
  bool get hasMore => _nextCursor != null;

  /// The cursor of the next page, or `null` when this is the last page.
  ///
  /// Some endpoints, such as contacts and lists, report `has_more` in the
  /// direction the page was fetched in. On a page fetched with `before` it
  /// says whether earlier pages exist, so only the cursor tells whether a
  /// later page does.
  String? get _nextCursor =>
      _fetchedBefore || pagination.hasMore ? pagination.nextCursor : null;

  /// Fetches the next page, or returns `null` when this is the last page.
  Future<CursorPage<T>?> nextPage() async {
    final cursor = _nextCursor;
    final fetch = _fetchAfter;
    if (cursor == null || fetch == null) return null;
    return await fetch(cursor);
  }

  /// Fetches the previous page, or returns `null` when there is none.
  Future<CursorPage<T>?> previousPage() async {
    final cursor = pagination.previousCursor;
    final fetch = _fetchBefore;
    if (cursor == null || fetch == null) return null;
    return await fetch(cursor);
  }

  /// Yields the items on this page and on every following page.
  Stream<T> autoPaginate() async* {
    CursorPage<T>? page = this;
    while (page != null) {
      yield* Stream.fromIterable(page.data);
      page = await page.nextPage();
    }
  }

  @override
  String toString() =>
      'CursorPage<$T>(${data.length} items, hasMore: ${pagination.hasMore})';
}
