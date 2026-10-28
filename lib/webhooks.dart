/// Verify and parse AhaSend webhook and route deliveries.
///
/// Create a [WebhookVerifier] with the secret returned when the webhook or
/// route was created, then call [WebhookVerifier.verify] with the raw
/// request body and headers. It checks the Standard Webhooks signature and
/// timestamp and returns a typed [WebhookEvent].
///
/// This library has no dependency on `dart:io`, so it works on the Dart VM,
/// in Flutter and on the web.
///
/// ```dart
/// import 'package:ahasend/webhooks.dart';
///
/// final verifier = WebhookVerifier(webhookSecret);
///
/// int handle(String body, Map<String, String> headers) {
///   final WebhookEvent event;
///   try {
///     event = verifier.verify(body: body, headers: headers);
///   } on WebhookVerificationException {
///     return 400; // Not from AhaSend, or replayed.
///   } on InvalidPayloadException {
///     return 204; // Authentic, but not decodable: store it and move on.
///   }
///   switch (event) {
///     case MessageBouncedEvent(:final data):
///       print('Bounced: ${data.recipient}');
///     case SuppressionCreatedEvent(:final data):
///       print('Suppressed: ${data.recipient}');
///     default:
///       break;
///   }
///   return 204;
/// }
/// ```
library;

export 'src/json.dart' show JsonMap;
export 'src/webhooks/events.dart';
export 'src/webhooks/exceptions.dart';
export 'src/webhooks/verifier.dart';
