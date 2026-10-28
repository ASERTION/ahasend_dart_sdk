// Measures decoding and encoding through the whole client, with an
// in-memory HTTP client so that no network time is included.
//
// For realistic numbers, compile it ahead of time:
//   dart compile exe benchmark/parse_benchmark.dart -o /tmp/bench && /tmp/bench
import 'dart:convert';
import 'dart:typed_data';

import 'package:ahasend/ahasend.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, Object?> _message(int i) => {
  'object': 'message',
  'created_at': '2024-01-01T10:00:00Z',
  'updated_at': '2024-01-01T10:00:05Z',
  'sent_at': '2024-01-01T10:00:01Z',
  'delivered_at': '2024-01-01T10:00:03Z',
  'retain_until': '2024-01-31T10:00:00Z',
  'direction': 'outbound',
  'is_bounce_notification': false,
  'bounce_classification': '',
  'delivery_attempts': [
    for (var a = 0; a < 3; a++)
      {
        'time': '2024-01-01T10:00:0${a}Z',
        'log': '250 2.0.0 OK queued as ABC$a — Grüße',
        'status': 'Delivered',
      },
  ],
  'message_id': '<$i@example.com>',
  'id': '0195c2a4-7d3e-7b6a-9f1c-${i.toString().padLeft(12, '0')}',
  'subject': 'Ihre Bestellung #$i ist unterwegs 🚚',
  'tags': ['shipping', 'order'],
  'sender': 'shop@example.com',
  'recipient': 'user$i@example.org',
  'status': 'Delivered',
  'num_attempts': 1,
  'click_count': i % 3,
  'open_count': i % 5,
  'reference_message_id': null,
  'domain_id': '0195c2a4-0000-7b6a-9f1c-2e4d5a6b7c8d',
  'account_id': '0195c2a4-1111-7b6a-9f1c-2e4d5a6b7c8d',
  'template_id': null,
};

final Uint8List _pageBytes = utf8.encode(
  jsonEncode({
    'object': 'list',
    'data': [for (var i = 0; i < 100; i++) _message(i)],
    'pagination': {'has_more': false},
  }),
);

final CreateMessageRequest _request = CreateMessageRequest(
  from: const Address(email: 'shop@example.com', name: 'Shop'),
  recipients: [
    for (var i = 0; i < 100; i++)
      Recipient(
        email: 'user$i@example.org',
        name: 'Kundin $i',
        substitutions: {'order_id': '$i', 'items': i % 7, 'vip': i.isEven},
      ),
  ],
  subject: 'Ihre Bestellung {{ order_id }} 🚚',
  htmlContent: '<p>${'Hallo {{ name }}, danke für Ihre Bestellung. ' * 40}</p>',
  textContent: 'Hallo {{ name }}, danke für Ihre Bestellung. ' * 40,
  tags: const ['shipping'],
);

final Uint8List _sendResponse = utf8.encode(
  jsonEncode({'object': 'list', 'data': <Object>[]}),
);

Future<void> _measure(
  String name,
  int iterations,
  Future<void> Function() body,
) async {
  for (var i = 0; i < iterations ~/ 5; i++) {
    await body();
  }
  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    await body();
  }
  sw.stop();
  final perOp = sw.elapsedMicroseconds / iterations;
  print('${name.padRight(42)} ${perOp.toStringAsFixed(1).padLeft(8)} µs/op');
}

Future<void> main() async {
  final listClient = AhaSendClient(
    apiKey: 'k',
    accountId: 'a',
    httpClient: MockClient(
      (_) async => http.Response.bytes(
        _pageBytes,
        200,
        headers: {'content-type': 'application/json'},
      ),
    ),
  );
  final sendClient = AhaSendClient(
    apiKey: 'k',
    accountId: 'a',
    httpClient: MockClient(
      (r) async => http.Response.bytes(
        _sendResponse,
        202,
        headers: {'content-type': 'application/json'},
      ),
    ),
  );

  print(
    'page: ${(_pageBytes.length / 1024).toStringAsFixed(0)} KiB, '
    'request: ${(utf8.encode(jsonEncode(_request.toJson())).length / 1024).toStringAsFixed(0)} KiB',
  );
  await _measure('messages.list (100 items)', 2000, () async {
    await listClient.messages.list();
  });
  await _measure('messages.create (100 recipients)', 2000, () async {
    await sendClient.messages.create(_request);
  });
  await _measure('CreateMessageRequest.toJson only', 20000, () async {
    _request.toJson();
  });
  final decoded = jsonDecode(utf8.decode(_pageBytes)) as Map<String, Object?>;
  final items = (decoded['data']! as List).cast<Map<String, Object?>>();
  await _measure('MessageSummary.fromJson x100 only', 5000, () async {
    for (final item in items) {
      MessageSummary.fromJson(item);
    }
  });
}
