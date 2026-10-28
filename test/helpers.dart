import 'dart:convert';

import 'package:ahasend/ahasend.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const testAccountId = '11111111-2222-3333-4444-555555555555';
const testApiKey = 'aha-sk-test';

/// A canned HTTP response for [FakeApi].
class FakeResponse(
  final int status, [
  Object? content,
  final Map<String, String> headers = const {},
]) {
  final String body = switch (content) {
    null => '',
    final String text => text,
    _ => jsonEncode(content),
  };
}

/// Records requests and answers them with queued responses.
///
/// When the queue holds a single response, it answers every request.
class FakeApi([List<FakeResponse>? responses]) {
  final List<FakeResponse> _responses =
      responses ??
      [
        FakeResponse(200, {'message': 'ok'}),
      ];
  final List<http.Request> requests = [];

  http.Request get last => requests.last;

  /// The decoded JSON body of the last request.
  Object? get lastJson => jsonDecode(last.body);

  late final MockClient httpClient = MockClient((request) async {
    requests.add(request);
    final response = _responses.length > 1
        ? _responses.removeAt(0)
        : _responses.first;
    return http.Response(
      response.body,
      response.status,
      headers: {'content-type': 'application/json', ...response.headers},
    );
  });

  AhaSendClient client({RetryConfig retry = RetryConfig.disabled}) =>
      AhaSendClient(
        apiKey: testApiKey,
        accountId: testAccountId,
        httpClient: httpClient,
        retry: retry,
      );
}

/// The path of an account endpoint, for comparing with `request.url.path`.
String accountPath(String rest) => '/v2/accounts/$testAccountId$rest';

/// A JSON list response body with pagination.
Map<String, Object?> pageBody(
  List<Object?> data, {
  bool hasMore = false,
  String? nextCursor,
}) => {
  'object': 'list',
  'data': data,
  'pagination': {'has_more': hasMore, 'next_cursor': ?nextCursor},
};
