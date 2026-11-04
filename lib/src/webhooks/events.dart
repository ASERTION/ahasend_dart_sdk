import 'dart:convert';
import 'dart:typed_data';

import '../json.dart';
import 'exceptions.dart';

/// An event delivered to a webhook or route URL.
///
/// Use [WebhookVerifier.verify] to check the signature and parse the body
/// in one step. To parse a body that was verified elsewhere, use
/// [WebhookEvent.parse] or [WebhookEvent.fromJson].
///
/// Switch over the subclasses to handle the events you care about, and
/// keep a `default` branch. AhaSend can add event types at any time: a type
/// this version of the package does not know arrives as an
/// [UnknownWebhookEvent], and a later version may decode it into a new
/// subclass. Neither breaks your code. To handle a type the package does
/// not know yet, match on [type] rather than on [UnknownWebhookEvent], so
/// the code keeps working once the package learns it.
///
/// ```dart
/// switch (event) {
///   case MessageDeliveredEvent(:final data):
///     print('Delivered to ${data.recipient}');
///   case MessageBouncedEvent(:final data):
///     print('Bounced: ${data.deliveryAttempt?.classification}');
///   case MessageRoutingEvent(:final data):
///     print('Inbound from ${data.from}: ${data.subject}');
///   default:
///     break;
/// }
/// ```
abstract final class const WebhookEvent({
  /// The event type, for example `message.delivered`.
  required final String type,

  /// When the event occurred.
  required final DateTime timestamp,

  /// The JSON payload this event was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates an event.
  this;

  /// Decodes an event from its JSON payload, without verifying it.
  ///
  /// Throws an [InvalidPayloadException] when [json] is not a valid
  /// payload. Unknown event types decode to [UnknownWebhookEvent].
  factory fromJson(JsonMap json) {
    final type = json['type'];
    if (type is! String || type.isEmpty) {
      throw const InvalidPayloadException('The payload has no "type" string.');
    }
    try {
      final timestamp = decodeDateTime(json['timestamp']);
      final webhookId = json['webhook_id'] as String? ?? '';
      JsonMap data() => asJsonMap(json['data']);
      MessageEventData messageData() => MessageEventData.fromJson(data());
      return switch (type) {
        MessageReceptionEvent.eventType => MessageReceptionEvent(
          timestamp: timestamp,
          webhookId: webhookId,
          data: messageData(),
          raw: json,
        ),
        MessageDeliveredEvent.eventType => MessageDeliveredEvent(
          timestamp: timestamp,
          webhookId: webhookId,
          data: messageData(),
          raw: json,
        ),
        MessageTransientErrorEvent.eventType => MessageTransientErrorEvent(
          timestamp: timestamp,
          webhookId: webhookId,
          data: messageData(),
          raw: json,
        ),
        MessageFailedEvent.eventType => MessageFailedEvent(
          timestamp: timestamp,
          webhookId: webhookId,
          data: messageData(),
          raw: json,
        ),
        MessageBouncedEvent.eventType => MessageBouncedEvent(
          timestamp: timestamp,
          webhookId: webhookId,
          data: messageData(),
          raw: json,
        ),
        MessageSuppressedEvent.eventType => MessageSuppressedEvent(
          timestamp: timestamp,
          webhookId: webhookId,
          data: messageData(),
          raw: json,
        ),
        MessageOpenedEvent.eventType => MessageOpenedEvent(
          timestamp: timestamp,
          webhookId: webhookId,
          data: messageData(),
          raw: json,
        ),
        MessageClickedEvent.eventType => MessageClickedEvent(
          timestamp: timestamp,
          webhookId: webhookId,
          data: MessageClickedEventData.fromJson(data()),
          raw: json,
        ),
        SuppressionCreatedEvent.eventType => SuppressionCreatedEvent(
          timestamp: timestamp,
          webhookId: webhookId,
          data: SuppressionCreatedEventData.fromJson(data()),
          raw: json,
        ),
        DomainDnsErrorEvent.eventType => DomainDnsErrorEvent(
          timestamp: timestamp,
          webhookId: webhookId,
          data: DomainDnsErrorEventData.fromJson(data()),
          raw: json,
        ),
        MessageRoutingEvent.eventType => MessageRoutingEvent(
          timestamp: timestamp,
          routeId: json['route_id'] as String? ?? '',
          data: MessageRoutingEventData.fromJson(data()),
          raw: json,
        ),
        _ => UnknownWebhookEvent(
          type: type,
          timestamp: timestamp,
          data: json['data'],
          raw: json,
        ),
      };
    } on WebhookException {
      rethrow;
    } on Object catch (e) {
      throw InvalidPayloadException(
        'Could not decode the "$type" payload: $e',
        cause: e,
      );
    }
  }

  /// Decodes an event from a JSON request body, without verifying it.
  ///
  /// Throws an [InvalidPayloadException] when [body] is not a valid
  /// payload.
  factory parse(String body) {
    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException catch (e) {
      throw InvalidPayloadException('The body is not valid JSON: $e', cause: e);
    }
    if (json is! Map<String, Object?>) {
      throw const InvalidPayloadException('The body is not a JSON object.');
    }
    return WebhookEvent.fromJson(json);
  }

  /// The event-specific data.
  Object? get data;

  /// Encodes this event as JSON.
  JsonMap toJson();

  @override
  String toString() =>
      'WebhookEvent($type, timestamp: $timestamp, data: $data)';
}

/// An event about an outbound message that shares the common message data
/// shape: reception, delivery, transient error, failure, bounce,
/// suppression or open.
///
/// [MessageClickedEvent] has its own data shape and is not a subclass.
abstract final class const MessageWebhookEvent({
  required super.type,
  required super.timestamp,

  /// The ID of the webhook this event was sent to.
  required final String webhookId,

  /// The message data of the event.
  @override required final MessageEventData data,
  super.raw,
}) extends WebhookEvent {
  /// Creates a message event.
  this;

  @override
  JsonMap toJson() => {
    'type': type,
    'webhook_id': webhookId,
    'timestamp': encodeDateTime(timestamp),
    'data': data.toJson(),
  };
}

/// A message was received and queued (`message.reception`).
///
/// This is the first event of every message, inbound or outbound.
final class const MessageReceptionEvent({
  required super.timestamp,
  required super.webhookId,
  required super.data,
  super.raw,
}) extends MessageWebhookEvent {
  /// Creates the event.
  this : super(type: eventType);

  /// The value of [type] for this event.
  static const String eventType = 'message.reception';
}

/// The recipient's mail server accepted the message (`message.delivered`).
///
/// This does not guarantee that the message reached the inbox.
final class const MessageDeliveredEvent({
  required super.timestamp,
  required super.webhookId,
  required super.data,
  super.raw,
}) extends MessageWebhookEvent {
  /// Creates the event.
  this : super(type: eventType);

  /// The value of [type] for this event.
  static const String eventType = 'message.delivered';
}

/// Delivery was deferred by a temporary problem and will be retried
/// (`message.transient_error`).
final class const MessageTransientErrorEvent({
  required super.timestamp,
  required super.webhookId,
  required super.data,
  super.raw,
}) extends MessageWebhookEvent {
  /// Creates the event.
  this : super(type: eventType);

  /// The value of [type] for this event.
  static const String eventType = 'message.transient_error';
}

/// The message ran out of retries without being delivered
/// (`message.failed`). It carries no delivery attempt.
final class const MessageFailedEvent({
  required super.timestamp,
  required super.webhookId,
  required super.data,
  super.raw,
}) extends MessageWebhookEvent {
  /// Creates the event.
  this : super(type: eventType);

  /// The value of [type] for this event.
  static const String eventType = 'message.failed';
}

/// The message bounced, either rejected permanently during SMTP or
/// reported later by a bounce notification (`message.bounced`).
final class const MessageBouncedEvent({
  required super.timestamp,
  required super.webhookId,
  required super.data,
  super.raw,
}) extends MessageWebhookEvent {
  /// Creates the event.
  this : super(type: eventType);

  /// The value of [type] for this event.
  static const String eventType = 'message.bounced';
}

/// The message was not sent because the recipient is suppressed
/// (`message.suppressed`).
final class const MessageSuppressedEvent({
  required super.timestamp,
  required super.webhookId,
  required super.data,
  super.raw,
}) extends MessageWebhookEvent {
  /// Creates the event.
  this : super(type: eventType);

  /// The value of [type] for this event.
  static const String eventType = 'message.suppressed';
}

/// The recipient opened the message (`message.opened`).
///
/// [MessageEventData.userAgent], [MessageEventData.ip] and
/// [MessageEventData.isBot] describe the open.
final class const MessageOpenedEvent({
  required super.timestamp,
  required super.webhookId,
  required super.data,
  super.raw,
}) extends MessageWebhookEvent {
  /// Creates the event.
  this : super(type: eventType);

  /// The value of [type] for this event.
  static const String eventType = 'message.opened';
}

/// The recipient clicked a tracked link (`message.clicked`).
final class const MessageClickedEvent({
  required super.timestamp,

  /// The ID of the webhook this event was sent to.
  required final String webhookId,

  /// The click data of the event.
  @override required final MessageClickedEventData data,
  super.raw,
}) extends WebhookEvent {
  /// Creates the event.
  this : super(type: eventType);

  /// The value of [type] for this event.
  static const String eventType = 'message.clicked';

  @override
  JsonMap toJson() => {
    'type': type,
    'webhook_id': webhookId,
    'timestamp': encodeDateTime(timestamp),
    'data': data.toJson(),
  };
}

/// An address was added to the suppression list (`suppression.created`).
final class const SuppressionCreatedEvent({
  required super.timestamp,

  /// The ID of the webhook this event was sent to.
  required final String webhookId,

  /// The suppression data of the event.
  @override required final SuppressionCreatedEventData data,
  super.raw,
}) extends WebhookEvent {
  /// Creates the event.
  this : super(type: eventType);

  /// The value of [type] for this event.
  static const String eventType = 'suppression.created';

  @override
  JsonMap toJson() => {
    'type': type,
    'webhook_id': webhookId,
    'timestamp': encodeDateTime(timestamp),
    'data': data.toJson(),
  };
}

/// The periodic DNS check found problems that block sending for a domain
/// (`domain.dns_error`).
final class const DomainDnsErrorEvent({
  required super.timestamp,

  /// The ID of the webhook this event was sent to.
  required final String webhookId,

  /// The DNS check data of the event.
  @override required final DomainDnsErrorEventData data,
  super.raw,
}) extends WebhookEvent {
  /// Creates the event.
  this : super(type: eventType);

  /// The value of [type] for this event.
  static const String eventType = 'domain.dns_error';

  @override
  JsonMap toJson() => {
    'type': type,
    'webhook_id': webhookId,
    'timestamp': encodeDateTime(timestamp),
    'data': data.toJson(),
  };
}

/// An inbound message matched a route (`message.routing`).
///
/// Route deliveries are signed with the route's secret, not a webhook's.
final class const MessageRoutingEvent({
  required super.timestamp,

  /// The ID of the route this message matched.
  required final String routeId,

  /// The inbound message of the event.
  @override required final MessageRoutingEventData data,
  super.raw,
}) extends WebhookEvent {
  /// Creates the event.
  this : super(type: eventType);

  /// The value of [type] for this event.
  static const String eventType = 'message.routing';

  @override
  JsonMap toJson() => {
    'type': type,
    'route_id': routeId,
    'timestamp': encodeDateTime(timestamp),
    'data': data.toJson(),
  };
}

/// An event whose type this version of the package does not know.
///
/// Read [type], [data] and [raw] to handle it yourself. A later version of
/// the package may decode the same type into its own subclass, so match on
/// [type] instead of on this class.
final class const UnknownWebhookEvent({
  required super.type,
  required super.timestamp,

  /// The undecoded `data` value of the payload.
  @override required final Object? data,
  super.raw,
}) extends WebhookEvent {
  /// Creates the event.
  this;

  @override
  JsonMap toJson() => raw;
}

/// The trigger reported in [MessageEventData.event].
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const MessageEventTrigger(
  /// The string the API uses for this value.
  String value,
) {
  /// `message.reception`.
  static const MessageEventTrigger onReception = MessageEventTrigger(
    'on_reception',
  );

  /// `message.delivered`.
  static const MessageEventTrigger onDelivered = MessageEventTrigger(
    'on_delivered',
  );

  /// `message.transient_error`.
  static const MessageEventTrigger onTransientError = MessageEventTrigger(
    'on_transient_error',
  );

  /// `message.failed`.
  static const MessageEventTrigger onFailed = MessageEventTrigger('on_failed');

  /// `message.bounced`.
  static const MessageEventTrigger onBounced = MessageEventTrigger(
    'on_bounced',
  );

  /// `message.suppressed`.
  static const MessageEventTrigger onSuppressed = MessageEventTrigger(
    'on_suppressed',
  );

  /// `message.opened`.
  static const MessageEventTrigger onOpened = MessageEventTrigger('on_opened');

  /// `message.clicked`.
  static const MessageEventTrigger onClicked = MessageEventTrigger(
    'on_clicked',
  );

  /// Every value this version of the package knows.
  static const List<MessageEventTrigger> values = [
    onReception,
    onDelivered,
    onTransientError,
    onFailed,
    onBounced,
    onSuppressed,
    onOpened,
    onClicked,
  ];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// The data of a [MessageWebhookEvent].
final class const MessageEventData({
  /// The ID of the account that sent the message.
  required final String accountId,

  /// The trigger of the event.
  required final MessageEventTrigger event,

  /// The sender address. For campaign messages it includes the name, as
  /// `Name <address>`.
  required final String from,

  /// The recipient address.
  required final String recipient,

  /// The subject line.
  required final String subject,

  /// The Message-ID header, as returned in
  /// `CreateSingleMessageResponse.messageIdHeader` when the message was
  /// created.
  ///
  /// It never changes for a message, so use it to group the events of a
  /// message and to match them with the send.
  required final String messageIdHeader,

  /// The API message ID, the same value as `CreateSingleMessageResponse.id`
  /// and the ID `messages.get` takes.
  ///
  /// Since 9 November 2026 this is a hyphenated UUID of 36 characters.
  /// Before, it was the internal AhaSend ID, a different value of 32 hex
  /// characters without hyphens. A message sent before that date can
  /// receive events with either ID for up to 30 days, so group events by
  /// [messageIdHeader], not by this ID. `messages.get` accepts both.
  ///
  /// Campaign messages send the same events with an ID of the same format,
  /// which groups their events too. `messages.get` cannot fetch campaign
  /// messages by it.
  required final String id,

  /// The user agent of the client, for opens.
  final String? userAgent,

  /// The IP address of the client, for opens.
  final String? ip,

  /// Whether the open was made by a bot, such as a security scanner.
  ///
  /// Meaningful for [MessageOpenedEvent] and `false` elsewhere. Older
  /// deliveries may omit it; `null` carries no signal.
  final bool? isBot,

  /// Diagnostics of the SMTP attempt this event reports on.
  ///
  /// Often `null`, even for deliveries, bounces and transient errors; never
  /// treat its absence as an error.
  final WebhookDeliveryAttempt? deliveryAttempt,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates message event data.
  this;

  /// Decodes message event data from JSON.
  factory fromJson(JsonMap json) => MessageEventData(
    accountId: json['account_id'] as String? ?? '',
    event: decodeEnum(json['event'], MessageEventTrigger.new),
    from: json['from'] as String? ?? '',
    recipient: json['recipient'] as String? ?? '',
    subject: json['subject'] as String? ?? '',
    messageIdHeader: json['message_id_header'] as String? ?? '',
    id: json['id'] as String? ?? '',
    userAgent: json['user_agent'] as String?,
    ip: json['ip'] as String?,
    isBot: json['is_bot'] as bool?,
    deliveryAttempt: switch (json['delivery_attempt']) {
      null => null,
      final attempt => WebhookDeliveryAttempt.fromJson(asJsonMap(attempt)),
    },
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'account_id': accountId,
    'event': event.value,
    'from': from,
    'recipient': recipient,
    'subject': subject,
    'message_id_header': messageIdHeader,
    'id': id,
    'user_agent': ?userAgent,
    'ip': ?ip,
    'is_bot': ?isBot,
    'delivery_attempt': ?deliveryAttempt?.toJson(),
  };

  @override
  String toString() =>
      'MessageEventData(id: $id, event: ${event.value}, '
      'recipient: $recipient)';
}

/// Diagnostics from a single delivery attempt.
final class const WebhookDeliveryAttempt({
  /// The SMTP status code. `0` means a response without an SMTP code was
  /// recorded, typically an internal error.
  required final int smtpCode,

  /// The bucket the bounce classifier assigned, for failures.
  ///
  /// Known values include `InvalidRecipient`, `BadDomain`,
  /// `InactiveMailbox`, `InvalidSender`, `QuotaIssues`, `NoAnswerFromHost`,
  /// `BadConnection`, `DNSFailure`, `RoutingErrors`, `TransientFailure`,
  /// `MessageExpired`, `ProtocolErrors`, `AuthenticationFailed`,
  /// `PolicyRelated` and `Uncategorized`. The set is open: keep a fallback
  /// for other values.
  final String? classification,

  /// The RFC 3463 enhanced status code, for example `5.1.1`.
  final String? enhancedStatusCode,

  /// The response text as recorded by the MTA. Human-readable; do not
  /// parse it.
  final String? response,

  /// A human-readable translation of [response], when it differs. Do not
  /// compare or parse it.
  final String? description,

  /// The SMTP command in flight, for example `RCPT TO` or `DATA`.
  final String? command,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates delivery attempt diagnostics.
  this;

  /// Decodes delivery attempt diagnostics from JSON.
  factory fromJson(JsonMap json) => WebhookDeliveryAttempt(
    smtpCode: decodeIntOrNull(json['smtp_code']) ?? 0,
    classification: json['classification'] as String?,
    enhancedStatusCode: json['enhanced_status_code'] as String?,
    response: json['response'] as String?,
    description: json['description'] as String?,
    command: json['command'] as String?,
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'classification': ?classification,
    'smtp_code': smtpCode,
    'enhanced_status_code': ?enhancedStatusCode,
    'response': ?response,
    'description': ?description,
    'command': ?command,
  };

  @override
  String toString() =>
      'WebhookDeliveryAttempt(smtpCode: $smtpCode'
      '${classification == null ? '' : ', classification: $classification'}'
      '${enhancedStatusCode == null ? '' : ', enhanced: $enhancedStatusCode'})';
}

/// The data of a [MessageClickedEvent].
final class const MessageClickedEventData({
  /// The ID of the account that sent the message.
  required final String accountId,

  /// The trigger of the event, normally [MessageEventTrigger.onClicked].
  required final MessageEventTrigger event,

  /// The sender address. For campaign messages it includes the name, as
  /// `Name <address>`.
  required final String from,

  /// The recipient address.
  required final String recipient,

  /// The subject line.
  required final String subject,

  /// The Message-ID header, as returned in
  /// `CreateSingleMessageResponse.messageIdHeader` when the message was
  /// created.
  ///
  /// It never changes for a message, so use it to group the events of a
  /// message and to match them with the send.
  required final String messageIdHeader,

  /// The URL that was clicked.
  required final String url,

  /// The user agent of the client that clicked.
  required final String userAgent,

  /// The IP address of the client that clicked.
  required final String ip,

  /// The API message ID, as in [MessageEventData.id]: since 9 November
  /// 2026 a hyphenated UUID of 36 characters, before the internal AhaSend
  /// ID of 32 hex characters. Group events by [messageIdHeader], not by
  /// this ID. `messages.get` cannot fetch campaign messages by it.
  required final String id,

  /// Whether the click was made by a bot. `null` carries no signal.
  final bool? isBot,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates click event data.
  this;

  /// Decodes click event data from JSON.
  factory fromJson(JsonMap json) => MessageClickedEventData(
    accountId: json['account_id'] as String? ?? '',
    event: decodeEnum(json['event'], MessageEventTrigger.new),
    from: json['from'] as String? ?? '',
    recipient: json['recipient'] as String? ?? '',
    subject: json['subject'] as String? ?? '',
    messageIdHeader: json['message_id_header'] as String? ?? '',
    url: json['url'] as String? ?? '',
    userAgent: json['user_agent'] as String? ?? '',
    ip: json['ip'] as String? ?? '',
    id: json['id'] as String? ?? '',
    isBot: json['is_bot'] as bool?,
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'account_id': accountId,
    'event': event.value,
    'from': from,
    'recipient': recipient,
    'subject': subject,
    'message_id_header': messageIdHeader,
    'url': url,
    'user_agent': userAgent,
    'ip': ip,
    'id': id,
    'is_bot': ?isBot,
  };

  @override
  String toString() =>
      'MessageClickedEventData(id: $id, recipient: $recipient, url: $url)';
}

/// The data of a [SuppressionCreatedEvent].
final class const SuppressionCreatedEventData({
  /// The account ID.
  required final String accountId,

  /// The suppressed address.
  required final String recipient,

  /// When the suppression was created.
  required final DateTime createdAt,

  /// When the suppression expires, typically 30 days after creation.
  required final DateTime expiresAt,

  /// Why the address was suppressed, for example `Too many hard bounces`.
  required final String reason,

  /// The domain the failed messages were sent from.
  required final String sendingDomain,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates suppression event data.
  this;

  /// Decodes suppression event data from JSON.
  factory fromJson(JsonMap json) => SuppressionCreatedEventData(
    accountId: json['account_id'] as String? ?? '',
    recipient: json['recipient'] as String? ?? '',
    createdAt: decodeDateTime(json['created_at']),
    expiresAt: decodeDateTime(json['expires_at']),
    reason: json['reason'] as String? ?? '',
    sendingDomain: json['sending_domain'] as String? ?? '',
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'account_id': accountId,
    'recipient': recipient,
    'created_at': encodeDateTime(createdAt),
    'expires_at': encodeDateTime(expiresAt),
    'reason': reason,
    'sending_domain': sendingDomain,
  };

  @override
  String toString() =>
      'SuppressionCreatedEventData(recipient: $recipient, '
      'reason: $reason, expiresAt: $expiresAt)';
}

/// The data of a [DomainDnsErrorEvent].
final class const DomainDnsErrorEventData({
  /// The domain with DNS problems.
  required final String domain,

  /// The account ID.
  required final String accountId,

  /// Whether the SPF record is valid.
  required final bool spfValid,

  /// Whether the DKIM record is valid.
  required final bool dkimValid,

  /// Whether the DMARC record is valid.
  required final bool dmarcValid,

  /// When DNS was last checked.
  required final DateTime dnsLastCheckedAt,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates DNS error event data.
  this;

  /// Decodes DNS error event data from JSON.
  factory fromJson(JsonMap json) => DomainDnsErrorEventData(
    domain: json['domain'] as String? ?? '',
    accountId: json['account_id'] as String? ?? '',
    spfValid: json['spf_valid'] as bool? ?? false,
    dkimValid: json['dkim_valid'] as bool? ?? false,
    dmarcValid: json['dmarc_valid'] as bool? ?? false,
    dnsLastCheckedAt: decodeDateTime(json['dns_last_checked_at']),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'domain': domain,
    'account_id': accountId,
    'spf_valid': spfValid,
    'dkim_valid': dkimValid,
    'dmarc_valid': dmarcValid,
    'dns_last_checked_at': encodeDateTime(dnsLastCheckedAt),
  };

  @override
  String toString() =>
      'DomainDnsErrorEventData(domain: $domain, '
      'spf: $spfValid, dkim: $dkimValid, dmarc: $dmarcValid)';
}

/// The inbound message of a [MessageRoutingEvent].
final class const MessageRoutingEventData({
  /// The route message ID.
  required final String id,

  /// The sender mailbox text.
  required final String from,

  /// The Reply-To header as received. Empty when there is none.
  required final String replyTo,

  /// The recipient address the route matched. On a route that groups by
  /// Message-ID, the To header as received.
  required final String to,

  /// The subject line.
  required final String subject,

  /// The original Message-ID header.
  required final String messageId,

  /// The message size in bytes.
  required final int size,

  /// The spam score. Higher means more likely spam; `0` when unchecked.
  required final double spamScore,

  /// Whether this is a bounce message.
  required final bool bounce,

  /// The CC header.
  required final String cc,

  /// The Date header, as received.
  required final String date,

  /// The In-Reply-To header.
  required final String inReplyTo,

  /// The References header.
  required final String references,

  /// The Auto-Submitted header.
  required final String autoSubmitted,

  /// The HTML body.
  required final String htmlBody,

  /// The plain text body.
  required final String plainBody,

  /// The reply text extracted from the plain text body.
  required final String replyFromPlainBody,

  /// The MIME attachments and inline parts, if the route includes them.
  required final List<MessageRoutingAttachment> attachments,

  /// The headers, if the route includes them.
  final Map<String, String>? headers,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates routed message data.
  this;

  /// Decodes routed message data from JSON.
  factory fromJson(JsonMap json) => MessageRoutingEventData(
    id: json['id'] as String? ?? '',
    from: json['from'] as String? ?? '',
    replyTo: json['reply_to'] as String? ?? '',
    to: json['to'] as String? ?? '',
    subject: json['subject'] as String? ?? '',
    messageId: json['message_id'] as String? ?? '',
    size: decodeIntOrNull(json['size']) ?? 0,
    spamScore: decodeDoubleOrNull(json['spam_score']) ?? 0,
    bounce: json['bounce'] as bool? ?? false,
    cc: json['cc'] as String? ?? '',
    date: json['date'] as String? ?? '',
    inReplyTo: json['in_reply_to'] as String? ?? '',
    references: json['references'] as String? ?? '',
    autoSubmitted: json['auto_submitted'] as String? ?? '',
    htmlBody: json['html_body'] as String? ?? '',
    plainBody: json['plain_body'] as String? ?? '',
    replyFromPlainBody: json['reply_from_plain_body'] as String? ?? '',
    attachments: decodeList(
      json['attachments'],
      MessageRoutingAttachment.fromJson,
    ),
    headers: decodeStringMapOrNull(json['headers']),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'id': id,
    'from': from,
    'reply_to': replyTo,
    'to': to,
    'subject': subject,
    'message_id': messageId,
    'size': size,
    'spam_score': spamScore,
    'bounce': bounce,
    'cc': cc,
    'date': date,
    'in_reply_to': inReplyTo,
    'references': references,
    'auto_submitted': autoSubmitted,
    'html_body': htmlBody,
    'plain_body': plainBody,
    'reply_from_plain_body': replyFromPlainBody,
    'attachments': [for (final a in attachments) a.toJson()],
    'headers': ?headers,
  };

  @override
  String toString() =>
      'MessageRoutingEventData(id: $id, from: $from, '
      'to: $to, subject: $subject)';
}

/// A MIME part of a routed message: an attachment or an inline part.
final class const MessageRoutingAttachment({
  /// The file name.
  required final String filename,

  /// The MIME type.
  required final String contentType,

  /// The Content-ID without angle brackets, percent-decoded. Empty when
  /// the part has none.
  ///
  /// A non-empty value marks a part embedded in the HTML body through a
  /// `cid:` URL; use it rather than [disposition] to tell embedded parts
  /// from real attachments.
  required final String contentId,

  /// The Content-Disposition type, usually `attachment` or `inline`, and
  /// empty when the part has no such header. Other values occur; treat
  /// unrecognised ones as `attachment`.
  required final String disposition,

  /// The base64-encoded content. Use [decodeData] for the bytes.
  required final String data,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a routed attachment.
  this;

  /// Decodes a routed attachment from JSON.
  factory fromJson(JsonMap json) => MessageRoutingAttachment(
    filename: json['filename'] as String? ?? '',
    contentType: json['content_type'] as String? ?? '',
    contentId: json['content_id'] as String? ?? '',
    disposition: json['disposition'] as String? ?? '',
    data: json['data'] as String? ?? '',
    raw: json,
  );

  /// Decodes [data] into bytes. Throws a [FormatException] when [data] is
  /// not valid base64.
  Uint8List decodeData() => base64.decode(data);

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'filename': filename,
    'content_type': contentType,
    'content_id': contentId,
    'disposition': disposition,
    'data': data,
  };

  @override
  String toString() =>
      'MessageRoutingAttachment(filename: $filename, '
      'contentType: $contentType, contentId: $contentId)';
}
