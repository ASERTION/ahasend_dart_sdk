import '../http/request_options.dart';
import '../models/common.dart';
import '../models/messages.dart';
import '../pagination.dart';
import 'resource.dart';

/// Send, list, fetch and cancel messages.
///
/// Access it through [AhaSendClient.messages].
interface class MessagesResource(super.transport, super.accountId)
    extends Resource {
  /// Creates the resource. Use [AhaSendClient.messages] instead.
  this;

  /// Sends a message to one or more recipients.
  ///
  /// Each recipient gets a separate message. The request carries an
  /// idempotency key, so the client retries it safely.
  ///
  /// Requires the `messages:send:all` or `messages:send:{domain}` scope.
  Future<CreateMessageResponse> create(
    CreateMessageRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '$accountPath/messages',
    CreateMessageResponse.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Sends a message rendered from a transactional template.
  ///
  /// Requires the `messages:send:all` or `messages:send:{domain}` scope.
  Future<CreateMessageResponse> createFromTemplate(
    CreateTemplateMessageRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '$accountPath/messages/template',
    CreateMessageResponse.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Sends one message with several addresses in To, CC or BCC.
  ///
  /// Requires the `messages:send:all` or `messages:send:{domain}` scope.
  Future<CreateMessageResponse> createConversation(
    CreateConversationMessageRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '$accountPath/messages/conversation',
    CreateMessageResponse.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Lists message summaries, newest first.
  ///
  /// [status] filters by statuses such as `Delivered`, `Bounced` or
  /// `Sandbox Delivered`. [tags] holds at most 20 tags.
  ///
  /// Requires the `messages:read:all` or `messages:read:{domain}` scope.
  Future<CursorPage<MessageSummary>> list({
    List<String>? status,
    String? sender,
    String? recipient,
    String? subject,
    String? messageIdHeader,
    List<String>? tags,
    DateTime? fromTime,
    DateTime? toTime,
    int? limit,
    String? after,
    String? before,
    RequestOptions? options,
  }) async => await fetchPage(
    '$accountPath/messages',
    MessageSummary.fromJson,
    query: _listQuery(
      status: status,
      sender: sender,
      recipient: recipient,
      subject: subject,
      messageIdHeader: messageIdHeader,
      tags: tags,
      fromTime: fromTime,
      toTime: toTime,
      limit: limit,
    ),
    after: after,
    before: before,
    options: options,
  );

  /// Iterates over every message summary matching the filters, fetching
  /// pages as needed. Takes the same filters as [list].
  Stream<MessageSummary> listAll({
    List<String>? status,
    String? sender,
    String? recipient,
    String? subject,
    String? messageIdHeader,
    List<String>? tags,
    DateTime? fromTime,
    DateTime? toTime,
    int? limit,
    RequestOptions? options,
  }) async* {
    yield* fetchAll(
      '$accountPath/messages',
      MessageSummary.fromJson,
      query: _listQuery(
        status: status,
        sender: sender,
        recipient: recipient,
        subject: subject,
        messageIdHeader: messageIdHeader,
        tags: tags,
        fromTime: fromTime,
        toTime: toTime,
        limit: limit,
      ),
      options: options,
    );
  }

  /// Fetches a message with its content.
  ///
  /// [messageId] is the API message ID or the Message-ID header value
  /// returned when the message was created.
  ///
  /// Requires the `messages:read:all` or `messages:read:{domain}` scope.
  Future<Message> get(String messageId, {RequestOptions? options}) async =>
      await sendAndDecode(
        'GET',
        '$accountPath/messages/${segment(messageId)}',
        Message.fromJson,
        options: options,
      );

  /// Cancels a scheduled message that has not been delivered yet.
  ///
  /// Requires the `messages:cancel:all` or `messages:cancel:{domain}`
  /// scope.
  Future<SuccessResponse> cancel(
    String messageId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'DELETE',
    '$accountPath/messages/${segment(messageId)}/cancel',
    SuccessResponse.fromJson,
    options: options,
  );

  Map<String, Object?> _listQuery({
    List<String>? status,
    String? sender,
    String? recipient,
    String? subject,
    String? messageIdHeader,
    List<String>? tags,
    DateTime? fromTime,
    DateTime? toTime,
    int? limit,
  }) => {
    'status': status,
    'sender': sender,
    'recipient': recipient,
    'subject': subject,
    'message_id_header': messageIdHeader,
    'tags': tags,
    'from_time': fromTime,
    'to_time': toTime,
    'limit': limit,
  };
}
