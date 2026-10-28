import '../json.dart';
import 'common.dart';

/// A recipient of a message sent with `messages.create` or
/// `messages.createFromTemplate`.
final class const Recipient({
  /// The recipient's email address.
  required final String email,

  /// The recipient's display name.
  final String? name,

  /// Template values for this recipient. They override the request's
  /// global substitutions.
  final Map<String, Object?>? substitutions,
}) {
  /// Creates a recipient.
  this;

  /// Decodes a recipient from JSON.
  factory fromJson(JsonMap json) => Recipient(
    email: json['email'] as String,
    name: json['name'] as String?,
    substitutions: asJsonMapOrNull(json['substitutions']),
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'email': email,
    'name': ?name,
    'substitutions': ?substitutions,
  };

  @override
  String toString() => name == null ? email : '$name <$email>';
}

/// A file attached to a message.
final class const Attachment({
  /// The attachment content, as text or base64.
  required final String data,

  /// The MIME type, for example `application/pdf`.
  required final String contentType,

  /// The file name.
  required final String fileName,

  /// Whether [data] is base64-encoded. Otherwise it is sent as UTF-8 text.
  final bool? base64,

  /// The content disposition, for example `inline`.
  final String? contentDisposition,

  /// The Content-ID for an inline image, wrapped in angle brackets, for
  /// example `<logo@example.com>`. Reference it from HTML without the
  /// brackets: `<img src="cid:logo@example.com">`.
  final String? contentId,
}) {
  /// Creates an attachment.
  this;

  /// Decodes an attachment from JSON.
  factory fromJson(JsonMap json) => Attachment(
    data: json['data'] as String,
    contentType: json['content_type'] as String,
    fileName: json['file_name'] as String,
    base64: json['base64'] as bool?,
    contentDisposition: json['content_disposition'] as String?,
    contentId: json['content_id'] as String?,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'base64': ?base64,
    'data': data,
    'content_type': contentType,
    'content_disposition': ?contentDisposition,
    'content_id': ?contentId,
    'file_name': fileName,
  };
}

/// Open and click tracking settings that override the account defaults.
final class const Tracking({
  /// Whether to track opens.
  final bool? open,

  /// Whether to track clicks.
  final bool? click,
}) {
  /// Creates tracking settings.
  this;

  /// Decodes tracking settings from JSON.
  factory fromJson(JsonMap json) =>
      Tracking(open: json['open'] as bool?, click: json['click'] as bool?);

  /// Encodes this object as JSON.
  JsonMap toJson() => {'open': ?open, 'click': ?click};
}

/// Retention settings that override the account defaults.
final class const Retention({
  /// Days to keep message metadata (1 to 30).
  final int? metadata,

  /// Days to keep message content (0 to 30).
  final int? data,
}) {
  /// Creates retention settings.
  this;

  /// Decodes retention settings from JSON.
  factory fromJson(JsonMap json) => Retention(
    metadata: decodeIntOrNull(json['metadata']),
    data: decodeIntOrNull(json['data']),
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {'metadata': ?metadata, 'data': ?data};
}

/// When to deliver a message.
final class const MessageSchedule({
  /// The time of the first delivery attempt. Must be in the future and
  /// within 7 days.
  final DateTime? firstAttempt,

  /// Drop the message if it is not delivered by this time. Must be in the
  /// future and within 8 days.
  final DateTime? expires,
}) {
  /// Creates a schedule.
  this;

  /// Decodes a schedule from JSON.
  factory fromJson(JsonMap json) => MessageSchedule(
    firstAttempt: decodeDateTimeOrNull(json['first_attempt']),
    expires: decodeDateTimeOrNull(json['expires']),
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'first_attempt': ?encodeDateTimeOrNull(firstAttempt),
    'expires': ?encodeDateTimeOrNull(expires),
  };
}

/// The simulated outcome of a sandbox send.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const SandboxResult(
  /// The string the API uses for this value.
  String value,
) {
  /// The message is delivered.
  static const SandboxResult deliver = SandboxResult('deliver');

  /// The message bounces.
  static const SandboxResult bounce = SandboxResult('bounce');

  /// The message is deferred.
  static const SandboxResult defer = SandboxResult('defer');

  /// The message fails.
  static const SandboxResult fail = SandboxResult('fail');

  /// The message is suppressed.
  static const SandboxResult suppress = SandboxResult('suppress');

  /// Every value this version of the package knows.
  static const List<SandboxResult> values = [
    deliver,
    bounce,
    defer,
    fail,
    suppress,
  ];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// A request to send a message to one or more recipients.
///
/// Each recipient gets a separate message. To send one message with several
/// addresses in To, CC or BCC, use [CreateConversationMessageRequest].
/// Provide [textContent], [htmlContent] or both.
final class const CreateMessageRequest({
  /// The sender. Must be on a domain of the account with valid DNS records.
  required final Address from,

  /// The recipients (1 to 100). Each gets a separate message.
  required final List<Recipient> recipients,

  /// The subject line. It may contain `{{ variables }}`.
  required final String subject,

  /// The reply-to address. Do not also set a `reply-to` header.
  final Address? replyTo,

  /// The plain text body.
  final String? textContent,

  /// The HTML body.
  final String? htmlContent,

  /// The AMP HTML body.
  final String? ampContent,

  /// File attachments.
  final List<Attachment>? attachments,

  /// Custom email headers.
  final Map<String, String>? headers,

  /// Global template values. Recipient substitutions override them.
  final Map<String, Object?>? substitutions,

  /// Tags for categorizing messages.
  final List<String>? tags,

  /// Whether to send to the sandbox instead of delivering.
  final bool? sandbox,

  /// The simulated outcome of a sandbox send.
  final SandboxResult? sandboxResult,

  /// Tracking settings that override the account defaults.
  final Tracking? tracking,

  /// Retention settings that override the account defaults.
  final Retention? retention,

  /// When to deliver the message.
  final MessageSchedule? schedule,
}) {
  /// Creates a send request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'from': from.toJson(),
    'recipients': [for (final r in recipients) r.toJson()],
    'reply_to': ?replyTo?.toJson(),
    'subject': subject,
    'text_content': ?textContent,
    'html_content': ?htmlContent,
    'amp_content': ?ampContent,
    'attachments': ?attachments?.map((a) => a.toJson()).toList(),
    'headers': ?headers,
    'substitutions': ?substitutions,
    'tags': ?tags,
    'sandbox': ?sandbox,
    'sandbox_result': ?sandboxResult?.value,
    'tracking': ?tracking?.toJson(),
    'retention': ?retention?.toJson(),
    'schedule': ?schedule?.toJson(),
  };
}

/// A request to send a message rendered from a transactional template.
final class const CreateTemplateMessageRequest({
  /// The ID of one of the account's transactional templates.
  required final String templateId,

  /// The recipients (1 to 100). Their `substitutions` fill the template's
  /// variables.
  required final List<Recipient> recipients,

  /// The sender. Leave it out to use the template's default sender.
  final Address? from,

  /// The reply-to address. Leave it out to use the template's reply-to.
  final Address? replyTo,

  /// The subject line. Leave it out to use the template's subject.
  final String? subject,

  /// File attachments.
  final List<Attachment>? attachments,

  /// Custom email headers.
  final Map<String, String>? headers,

  /// Tags for categorizing messages.
  final List<String>? tags,

  /// Whether to send to the sandbox instead of delivering.
  final bool? sandbox,

  /// The simulated outcome of a sandbox send.
  final SandboxResult? sandboxResult,

  /// Tracking settings that override the account defaults.
  final Tracking? tracking,

  /// Retention settings that override the account defaults.
  final Retention? retention,

  /// When to deliver the message.
  final MessageSchedule? schedule,
}) {
  /// Creates a template send request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'template_id': templateId,
    'from': ?from?.toJson(),
    'recipients': [for (final r in recipients) r.toJson()],
    'reply_to': ?replyTo?.toJson(),
    'subject': ?subject,
    'attachments': ?attachments?.map((a) => a.toJson()).toList(),
    'headers': ?headers,
    'tags': ?tags,
    'sandbox': ?sandbox,
    'sandbox_result': ?sandboxResult?.value,
    'tracking': ?tracking?.toJson(),
    'retention': ?retention?.toJson(),
    'schedule': ?schedule?.toJson(),
  };
}

/// A request to send one message with several addresses in To, CC or BCC.
///
/// Provide [textContent], [htmlContent] or both.
final class const CreateConversationMessageRequest({
  /// The sender.
  required final Address from,

  /// The To addresses. To, CC and BCC together hold at most 50 addresses.
  required final List<Address> to,

  /// The subject line.
  required final String subject,

  /// The CC addresses.
  final List<Address>? cc,

  /// The BCC addresses.
  final List<Address>? bcc,

  /// The reply-to address.
  final Address? replyTo,

  /// The plain text body.
  final String? textContent,

  /// The HTML body.
  final String? htmlContent,

  /// The AMP HTML body.
  final String? ampContent,

  /// File attachments.
  final List<Attachment>? attachments,

  /// Custom email headers.
  final Map<String, String>? headers,

  /// Tags for categorizing messages.
  final List<String>? tags,

  /// Whether to send to the sandbox instead of delivering.
  final bool? sandbox,

  /// The simulated outcome of a sandbox send.
  final SandboxResult? sandboxResult,

  /// Tracking settings that override the account defaults.
  final Tracking? tracking,

  /// Retention settings that override the account defaults.
  final Retention? retention,

  /// When to deliver the message.
  final MessageSchedule? schedule,
}) {
  /// Creates a conversation send request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'from': from.toJson(),
    'to': [for (final a in to) a.toJson()],
    'cc': ?cc?.map((a) => a.toJson()).toList(),
    'bcc': ?bcc?.map((a) => a.toJson()).toList(),
    'reply_to': ?replyTo?.toJson(),
    'subject': subject,
    'text_content': ?textContent,
    'html_content': ?htmlContent,
    'amp_content': ?ampContent,
    'attachments': ?attachments?.map((a) => a.toJson()).toList(),
    'headers': ?headers,
    'tags': ?tags,
    'sandbox': ?sandbox,
    'sandbox_result': ?sandboxResult?.value,
    'tracking': ?tracking?.toJson(),
    'retention': ?retention?.toJson(),
    'schedule': ?schedule?.toJson(),
  };
}

/// The status of a message right after it was submitted.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const CreatedMessageStatus(
  /// The string the API uses for this value.
  String value,
) {
  /// The message is queued for delivery.
  static const CreatedMessageStatus queued = CreatedMessageStatus('queued');

  /// The message is scheduled for later delivery.
  static const CreatedMessageStatus scheduled = CreatedMessageStatus(
    'scheduled',
  );

  /// The message was not sent; see [CreateSingleMessageResponse.error].
  static const CreatedMessageStatus error = CreatedMessageStatus('error');

  /// Every value this version of the package knows.
  static const List<CreatedMessageStatus> values = [queued, scheduled, error];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// The outcome of submitting a message for one recipient.
final class const CreateSingleMessageResponse({
  /// The message ID, or `null` when the message was not sent.
  required final String? id,

  /// The recipient.
  required final Recipient recipient,

  /// The submission status.
  required final CreatedMessageStatus status,

  /// Why the message was not sent, if it was not.
  final String? error,

  /// The schedule, if the request had one.
  final MessageSchedule? schedule,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a submission outcome.
  this;

  /// Decodes a submission outcome from JSON.
  factory fromJson(JsonMap json) => CreateSingleMessageResponse(
    id: json['id'] as String?,
    recipient: Recipient.fromJson(asJsonMap(json['recipient'])),
    status: decodeEnum(json['status'], CreatedMessageStatus.new),
    error: json['error'] as String?,
    schedule: switch (json['schedule']) {
      null => null,
      final schedule => MessageSchedule.fromJson(asJsonMap(schedule)),
    },
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'message',
    'id': id,
    'recipient': recipient.toJson(),
    'status': status.value,
    'error': error,
    'schedule': ?schedule?.toJson(),
  };

  @override
  String toString() =>
      'CreateSingleMessageResponse(id: $id, recipient: $recipient, '
      'status: ${status.value}${error == null ? '' : ', error: $error'})';
}

/// The response to a send request: one entry per recipient.
final class const CreateMessageResponse({
  /// The outcome for each recipient.
  required final List<CreateSingleMessageResponse> data,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a send response.
  this;

  /// Decodes a send response from JSON.
  factory fromJson(JsonMap json) => CreateMessageResponse(
    data: decodeList(json['data'], CreateSingleMessageResponse.fromJson),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'list',
    'data': [for (final m in data) m.toJson()],
  };

  @override
  String toString() => 'CreateMessageResponse($data)';
}

/// A delivery attempt of a message.
final class const DeliveryEvent({
  /// When the attempt happened.
  required final DateTime time,

  /// The log line of the attempt.
  required final String log,

  /// The status of the attempt.
  required final String status,
}) {
  /// Creates a delivery event.
  this;

  /// Decodes a delivery event from JSON.
  factory fromJson(JsonMap json) => DeliveryEvent(
    time: decodeDateTime(json['time']),
    log: json['log'] as String? ?? '',
    status: json['status'] as String? ?? '',
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'time': encodeDateTime(time),
    'log': log,
    'status': status,
  };
}

/// One MIME part of a parsed message.
final class const MessageContentPart({
  /// The MIME type, for example `text/html`.
  required final String contentType,

  /// The content of the part.
  required final String content,
}) {
  /// Creates a content part.
  this;

  /// Decodes a content part from JSON.
  factory fromJson(JsonMap json) => MessageContentPart(
    contentType: json['content_type'] as String,
    content: json['content'] as String,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {'content_type': contentType, 'content': content};
}

/// An attachment of a parsed message.
final class const MessageAttachment({
  /// The original file name.
  required final String filename,

  /// The base64-encoded content.
  required final String content,

  /// The MIME type.
  required final String contentType,

  /// The Content-ID for inline attachments.
  required final String contentId,
}) {
  /// Creates a message attachment.
  this;

  /// Decodes a message attachment from JSON.
  factory fromJson(JsonMap json) => MessageAttachment(
    filename: json['filename'] as String,
    content: json['content'] as String,
    contentType: json['content_type'] as String,
    contentId: json['content_id'] as String? ?? '',
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'filename': filename,
    'content': content,
    'content_type': contentType,
    'content_id': contentId,
  };
}

/// The parsed content of a message.
final class const MessageContentParsed({
  /// The MIME parts, such as the text and HTML bodies.
  required final List<MessageContentPart> parts,

  /// The attachments.
  required final List<MessageAttachment> attachments,

  /// The headers. A header that appears several times has several values.
  required final Map<String, List<String>> headers,
}) {
  /// Creates parsed content.
  this;

  /// Decodes parsed content from JSON.
  factory fromJson(JsonMap json) => MessageContentParsed(
    parts: decodeList(json['parts'], MessageContentPart.fromJson),
    attachments: decodeList(json['attachments'], MessageAttachment.fromJson),
    headers: Map.unmodifiableOf({
      for (final MapEntry(:key, :value)
          in (asJsonMapOrNull(json['headers']) ?? const {}).entries)
        key: decodeScalarList<String>(value),
    }),
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'parts': [for (final p in parts) p.toJson()],
    'attachments': [for (final a in attachments) a.toJson()],
    'headers': headers,
  };
}

/// The direction of a message.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const MessageDirection(
  /// The string the API uses for this value.
  String value,
) {
  /// A message received by the account.
  static const MessageDirection inbound = MessageDirection('inbound');

  /// A message sent by the account.
  static const MessageDirection outbound = MessageDirection('outbound');

  /// Every value this version of the package knows.
  static const List<MessageDirection> values = [inbound, outbound];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// A message without its content, as returned by `messages.list`.
final class const MessageSummary({
  /// When the message was created.
  required final DateTime createdAt,

  /// When the message was last updated.
  required final DateTime updatedAt,

  /// When the message data will be purged.
  required final DateTime retainUntil,

  /// Whether the message was sent or received.
  required final MessageDirection direction,

  /// Whether this is a bounce notification.
  required final bool isBounceNotification,

  /// The delivery attempts.
  required final List<DeliveryEvent> deliveryAttempts,

  /// The value of the Message-ID header. Use it with `messages.get`.
  required final String messageId,

  /// The subject line.
  required final String subject,

  /// The tags.
  required final List<String> tags,

  /// The sender's email address.
  required final String sender,

  /// The recipient's email address.
  required final String recipient,

  /// The current status, for example `Delivered` or `Bounced`.
  required final String status,

  /// The number of delivery attempts.
  required final int numAttempts,

  /// The number of tracked clicks.
  required final int clickCount,

  /// The number of tracked opens.
  required final int openCount,

  /// The ID of the sending domain.
  required final String domainId,

  /// The ID of the account.
  required final String accountId,

  /// The API-generated message ID.
  final String? id,

  /// When the message was sent.
  final DateTime? sentAt,

  /// When the message was delivered.
  final DateTime? deliveredAt,

  /// The bounce classification, if the message bounced.
  final String? bounceClassification,

  /// The ID of the original message, for bounce notifications.
  final int? referenceMessageId,

  /// The template the message was sent from, if any.
  final String? templateId,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a message summary.
  this;

  /// Decodes a message summary from JSON.
  factory fromJson(JsonMap json) => MessageSummary(
    createdAt: decodeDateTime(json['created_at']),
    updatedAt: decodeDateTime(json['updated_at']),
    sentAt: decodeDateTimeOrNull(json['sent_at']),
    deliveredAt: decodeDateTimeOrNull(json['delivered_at']),
    retainUntil: decodeDateTime(json['retain_until']),
    direction: decodeEnum(json['direction'], MessageDirection.new),
    isBounceNotification: json['is_bounce_notification'] as bool? ?? false,
    bounceClassification: json['bounce_classification'] as String?,
    deliveryAttempts: decodeList(
      json['delivery_attempts'],
      DeliveryEvent.fromJson,
    ),
    messageId: json['message_id'] as String,
    id: json['id'] as String?,
    subject: json['subject'] as String? ?? '',
    tags: decodeScalarList<String>(json['tags']),
    sender: json['sender'] as String,
    recipient: json['recipient'] as String,
    status: json['status'] as String,
    numAttempts: decodeIntOrNull(json['num_attempts']) ?? 0,
    clickCount: decodeIntOrNull(json['click_count']) ?? 0,
    openCount: decodeIntOrNull(json['open_count']) ?? 0,
    referenceMessageId: decodeIntOrNull(json['reference_message_id']),
    domainId: json['domain_id'] as String,
    accountId: json['account_id'] as String,
    templateId: json['template_id'] as String?,
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'message',
    'created_at': encodeDateTime(createdAt),
    'updated_at': encodeDateTime(updatedAt),
    'sent_at': encodeDateTimeOrNull(sentAt),
    'delivered_at': encodeDateTimeOrNull(deliveredAt),
    'retain_until': encodeDateTime(retainUntil),
    'direction': direction.value,
    'is_bounce_notification': isBounceNotification,
    'bounce_classification': bounceClassification,
    'delivery_attempts': [for (final e in deliveryAttempts) e.toJson()],
    'message_id': messageId,
    'id': id,
    'subject': subject,
    'tags': tags,
    'sender': sender,
    'recipient': recipient,
    'status': status,
    'num_attempts': numAttempts,
    'click_count': clickCount,
    'open_count': openCount,
    'reference_message_id': referenceMessageId,
    'domain_id': domainId,
    'account_id': accountId,
    'template_id': templateId,
  };

  @override
  String toString() {
    final className = this is Message ? 'Message' : 'MessageSummary';
    return '$className(id: $id, messageId: $messageId, '
        'recipient: $recipient, status: $status)';
  }
}

/// A message with its content, as returned by `messages.get`.
final class const Message({
  required super.createdAt,
  required super.updatedAt,
  required super.retainUntil,
  required super.direction,
  required super.isBounceNotification,
  required super.deliveryAttempts,
  required super.messageId,
  required super.subject,
  required super.tags,
  required super.sender,
  required super.recipient,
  required super.status,
  required super.numAttempts,
  required super.clickCount,
  required super.openCount,
  required super.domainId,
  required super.accountId,
  super.id,
  super.sentAt,
  super.deliveredAt,
  super.bounceClassification,
  super.referenceMessageId,
  super.templateId,

  /// The raw RFC 822 content, if it is still retained.
  final String? content,

  /// The parsed content, if it is still retained.
  final MessageContentParsed? contentParsed,
  super.raw,
}) extends MessageSummary {
  /// Creates a message.
  this;

  /// Decodes a message from JSON.
  factory fromJson(JsonMap json) {
    final s = MessageSummary.fromJson(json);
    return Message(
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
      sentAt: s.sentAt,
      deliveredAt: s.deliveredAt,
      retainUntil: s.retainUntil,
      direction: s.direction,
      isBounceNotification: s.isBounceNotification,
      bounceClassification: s.bounceClassification,
      deliveryAttempts: s.deliveryAttempts,
      messageId: s.messageId,
      id: s.id,
      subject: s.subject,
      tags: s.tags,
      sender: s.sender,
      recipient: s.recipient,
      status: s.status,
      numAttempts: s.numAttempts,
      clickCount: s.clickCount,
      openCount: s.openCount,
      referenceMessageId: s.referenceMessageId,
      domainId: s.domainId,
      accountId: s.accountId,
      templateId: s.templateId,
      content: json['content'] as String?,
      contentParsed: switch (json['content_parsed']) {
        null => null,
        final parsed => MessageContentParsed.fromJson(asJsonMap(parsed)),
      },
      raw: json,
    );
  }

  @override
  JsonMap toJson() => {
    ...super.toJson(),
    'content': ?content,
    'content_parsed': ?contentParsed?.toJson(),
  };
}
