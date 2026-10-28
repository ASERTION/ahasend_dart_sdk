import 'package:ahasend/ahasend.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  const fastRetry = RetryConfig(
    maxRetries: 2,
    baseDelay: Duration(milliseconds: 1),
    maxDelay: Duration(milliseconds: 2),
  );

  test('sends auth, accept and user agent headers', () async {
    final api = FakeApi();
    await api.client().ping();
    expect(api.last.method, 'GET');
    expect(api.last.url.toString(), 'https://api.ahasend.com/v2/ping');
    expect(api.last.headers['Authorization'], 'Bearer $testApiKey');
    expect(api.last.headers['Accept'], 'application/json');
    // Browsers forbid setting User-Agent, so the client only sends it
    // outside the web.
    const isWeb = bool.fromEnvironment('dart.library.js_interop');
    expect(
      api.last.headers['User-Agent'],
      isWeb ? isNull : startsWith('ahasend-dart/'),
    );
  });

  test('per-request options override key and add headers', () async {
    final api = FakeApi();
    await api.client().ping(
      options: const RequestOptions(apiKey: 'other', headers: {'X-Test': '1'}),
    );
    expect(api.last.headers['Authorization'], 'Bearer other');
    expect(api.last.headers['X-Test'], '1');
  });

  test('maps error statuses to exception types', () async {
    final cases = <int, Matcher>{
      400: isA<BadRequestException>(),
      401: isA<AuthenticationException>(),
      403: isA<PermissionDeniedException>(),
      404: isA<NotFoundException>(),
      409: isA<ConflictException>(),
      422: isA<UnprocessableEntityException>(),
      429: isA<RateLimitException>(),
      500: isA<ServerException>(),
      418: isA<ApiException>(),
    };
    for (final MapEntry(key: status, value: matcher) in cases.entries) {
      final api = FakeApi([
        FakeResponse(status, {'message': 'nope'}),
      ]);
      await expectLater(
        api.client().ping(),
        throwsA(
          allOf(
            matcher,
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', status)
                .having((e) => e.message, 'message', 'nope'),
          ),
        ),
      );
    }
  });

  test('detects in-progress idempotency conflicts', () async {
    final api = FakeApi([
      FakeResponse(
        409,
        {'message': 'in progress'},
        {'idempotent-replayed': 'false', 'retry-after': '3'},
      ),
    ]);
    await expectLater(
      api.client().ping(),
      throwsA(
        isA<IdempotencyConflictException>().having(
          (e) => e.retryAfter,
          'retryAfter',
          const Duration(seconds: 3),
        ),
      ),
    );
  });

  test('retries 5xx on GET and succeeds', () async {
    final api = FakeApi([
      FakeResponse(503, {'message': 'down'}),
      FakeResponse(502, {'message': 'down'}),
      FakeResponse(200, {'message': 'pong'}),
    ]);
    final result = await api.client(retry: fastRetry).ping();
    expect(result.message, 'pong');
    expect(api.requests, hasLength(3));
  });

  test('gives up after maxRetries', () async {
    final api = FakeApi([
      FakeResponse(500, {'message': 'down'}),
    ]);
    await expectLater(
      api.client(retry: fastRetry).ping(),
      throwsA(isA<ServerException>()),
    );
    expect(api.requests, hasLength(3));
  });

  test('honours Retry-After on 429', () async {
    final api = FakeApi([
      FakeResponse(429, {'message': 'slow'}, {'retry-after': '0'}),
      FakeResponse(200, {'message': 'pong'}),
    ]);
    await api.client(retry: fastRetry).ping();
    expect(api.requests, hasLength(2));
  });

  test('does not retry when Retry-After exceeds the limit', () async {
    final api = FakeApi([
      FakeResponse(429, {'message': 'slow'}, {'retry-after': '3600'}),
      FakeResponse(200, {'message': 'pong'}),
    ]);
    await expectLater(
      api.client(retry: fastRetry).ping(),
      throwsA(isA<RateLimitException>()),
    );
    expect(api.requests, hasLength(1));
  });

  test('does not retry other 4xx', () async {
    final api = FakeApi([
      FakeResponse(400, {'message': 'bad'}),
    ]);
    await expectLater(
      api.client(retry: fastRetry).ping(),
      throwsA(isA<BadRequestException>()),
    );
    expect(api.requests, hasLength(1));
  });

  test('reuses the idempotency key across retries', () async {
    final api = FakeApi([
      FakeResponse(500, {'message': 'down'}),
      FakeResponse(202, {'object': 'list', 'data': <Object>[]}),
    ]);
    ResponseInfo? info;
    await api
        .client(retry: fastRetry)
        .messages
        .create(
          const CreateMessageRequest(
            from: Address(email: 'a@example.com'),
            recipients: [Recipient(email: 'b@example.com')],
            subject: 'Hi',
            textContent: 'Hi',
          ),
          options: RequestOptions(onResponse: (i) => info = i),
        );
    final keys = api.requests.map((r) => r.headers['Idempotency-Key']).toList();
    expect(keys, hasLength(2));
    expect(keys.first, isNotNull);
    expect(keys.first, keys.last);
    expect(info!.attempts, 2);
    expect(info!.idempotencyKey, keys.first);
  });

  test('uses a caller-supplied idempotency key', () async {
    final api = FakeApi([
      FakeResponse(
        202,
        {'object': 'list', 'data': <Object>[]},
        {'idempotent-replayed': 'true'},
      ),
    ]);
    ResponseInfo? info;
    await api.client().messages.create(
      const CreateMessageRequest(
        from: Address(email: 'a@example.com'),
        recipients: [Recipient(email: 'b@example.com')],
        subject: 'Hi',
        textContent: 'Hi',
      ),
      options: RequestOptions(
        idempotencyKey: 'order-1',
        onResponse: (i) => info = i,
      ),
    );
    expect(api.last.headers['Idempotency-Key'], 'order-1');
    expect(info!.idempotentReplayed, isTrue);
  });

  test('does not send an idempotency key on GET', () async {
    final api = FakeApi();
    await api.client().ping();
    expect(api.last.headers.containsKey('Idempotency-Key'), isFalse);
  });

  test('reports invalid JSON as UnexpectedResponseException', () async {
    final api = FakeApi([FakeResponse(200, 'not json')]);
    await expectLater(
      api.client().ping(),
      throwsA(isA<UnexpectedResponseException>()),
    );
  });

  test('reports a missing account ID through the future or stream', () async {
    final client = AhaSendClient(
      apiKey: testApiKey,
      httpClient: FakeApi().httpClient,
    );
    // Calling must not throw synchronously, so `.catchError` and
    // `unawaited` callers see the error too.
    final future = client.messages.get('x');
    final stream = client.domains.listAll();
    await expectLater(future, throwsA(isA<InvalidUsageException>()));
    await expectLater(stream, emitsError(isA<InvalidUsageException>()));
  });

  test('forAccount targets another account', () async {
    final api = FakeApi([
      FakeResponse(200, {
        'object': 'list',
        'data': <Object>[],
        'pagination': {'has_more': false},
      }),
    ]);
    await api.client().forAccount('sub-1').messages.list();
    expect(api.last.url.path, '/v2/accounts/sub-1/messages');
  });

  test(
    'forAccount can use another API key and shares the connection',
    () async {
      final api = FakeApi([
        FakeResponse(200, {
          'object': 'list',
          'data': <Object>[],
          'pagination': {'has_more': false},
        }),
      ]);
      final parent = api.client();
      final child = parent.forAccount('sub-1', apiKey: 'aha-sk-child');
      await child.messages.list();
      expect(api.last.url.path, '/v2/accounts/sub-1/messages');
      expect(api.last.headers['Authorization'], 'Bearer aha-sk-child');

      // Closing the view leaves the parent usable.
      child.close();
      await parent.messages.list();
      expect(api.last.headers['Authorization'], 'Bearer $testApiKey');
      expect(() => parent.forAccount('x', apiKey: ' '), throwsArgumentError);
    },
  );

  test('rejects an empty API key', () {
    expect(() => AhaSendClient(apiKey: ' '), throwsArgumentError);
  });
}
