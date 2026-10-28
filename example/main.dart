// Sends a message, lists domains and verifies a webhook delivery.
//
// Run with:
//   AHASEND_API_KEY=aha-sk-... AHASEND_ACCOUNT_ID=... dart run example/main.dart
import 'dart:io';

import 'package:ahasend/ahasend.dart';
import 'package:ahasend/webhooks.dart';

Future<void> main() async {
  final apiKey = Platform.environment['AHASEND_API_KEY'];
  final accountId = Platform.environment['AHASEND_ACCOUNT_ID'];
  if (apiKey == null || accountId == null) {
    stderr.writeln('Set AHASEND_API_KEY and AHASEND_ACCOUNT_ID.');
    exitCode = 64;
    return;
  }

  final client = AhaSendClient(apiKey: apiKey, accountId: accountId);
  try {
    await client.ping();

    // List every domain, fetching pages as needed.
    await for (final domain in client.domains.listAll()) {
      print('${domain.domain}: DNS valid = ${domain.dnsValid}');
    }

    // Send a message in the sandbox, so nothing is delivered.
    final response = await client.messages.create(
      const CreateMessageRequest(
        from: Address(email: 'hello@example.com', name: 'Example'),
        recipients: [
          Recipient(
            email: 'user@example.org',
            substitutions: {'first_name': 'Ada'},
          ),
        ],
        subject: 'Welcome, {{ first_name }}!',
        htmlContent: '<p>Hello {{ first_name }}!</p>',
        textContent: 'Hello {{ first_name }}!',
        sandbox: true,
      ),
      // A stable key makes the send safe to retry, even after a restart.
      options: const RequestOptions(idempotencyKey: 'example-welcome-ada'),
    );
    for (final message in response.data) {
      print('${message.recipient.email}: ${message.status.value}');
    }
  } on RateLimitException catch (e) {
    stderr.writeln('Rate limited, retry after ${e.retryAfter}');
  } on ApiException catch (e) {
    stderr.writeln('API error ${e.statusCode}: ${e.message}');
  } on NetworkException catch (e) {
    stderr.writeln('Network error: ${e.message}');
  } finally {
    client.close();
  }

  verifyWebhookExample();
}

/// Shows how a webhook handler verifies and dispatches a delivery.
void verifyWebhookExample() {
  const secret = 'aha-whsec-example';
  const body =
      '{"type":"message.delivered","timestamp":"2024-01-01T00:00:00Z",'
      '"data":{"account_id":"a","event":"on_delivered","from":"a@example.com",'
      '"recipient":"b@example.com","subject":"Hi","message_id_header":"<m>",'
      '"id":"m"}}';
  // In a real handler these come from the HTTP request.
  final headers = WebhookVerifier.signedHeaders(
    secret: secret,
    id: 'msg_1',
    timestamp: DateTime.now(),
    body: body,
  );

  final verifier = WebhookVerifier(secret);
  try {
    final event = verifier.verify(body: body, headers: headers);
    switch (event) {
      case MessageDeliveredEvent(:final data):
        print('Delivered to ${data.recipient}');
      case MessageBouncedEvent(:final data):
        print('Bounced: ${data.recipient}');
      default:
        print('Received ${event.type}');
    }
  } on WebhookVerificationException catch (e) {
    print('Rejected delivery: $e');
  } on InvalidPayloadException catch (e) {
    print('Authentic delivery this version cannot decode: $e');
  }
}
