import '../json.dart';

/// An inbound route that forwards received email to a URL.
final class const InboundRoute({
  /// The route ID.
  required final String id,

  /// When the route was created.
  required final DateTime createdAt,

  /// When the route was last updated.
  required final DateTime updatedAt,

  /// The route name.
  required final String name,

  /// The URL inbound messages are posted to.
  required final String url,

  /// The recipient filter. An empty string means no filter.
  required final String recipient,

  /// Whether attachments are included in the payload.
  required final bool attachments,

  /// Whether headers are included in the payload.
  required final bool headers,

  /// Whether messages are grouped by Message-ID.
  required final bool groupByMessageId,

  /// Whether quoted reply content is stripped.
  required final bool stripReplies,

  /// Whether the route is enabled.
  required final bool enabled,

  /// The number of successful calls.
  required final int successCount,

  /// The number of failed calls.
  required final int errorCount,

  /// The number of consecutive failed calls since the last success.
  required final int errorsSinceLastSuccess,

  /// When the route was last called.
  final DateTime? lastRequestAt,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a route.
  this;

  /// Decodes a route from JSON.
  factory fromJson(JsonMap json) => InboundRoute(
    id: json['id'] as String,
    createdAt: decodeDateTime(json['created_at']),
    updatedAt: decodeDateTime(json['updated_at']),
    name: json['name'] as String? ?? '',
    url: json['url'] as String,
    recipient: json['recipient'] as String? ?? '',
    attachments: json['attachments'] as bool? ?? false,
    headers: json['headers'] as bool? ?? false,
    groupByMessageId: json['group_by_message_id'] as bool? ?? false,
    stripReplies: json['strip_replies'] as bool? ?? false,
    enabled: json['enabled'] as bool? ?? false,
    successCount: decodeIntOrNull(json['success_count']) ?? 0,
    errorCount: decodeIntOrNull(json['error_count']) ?? 0,
    errorsSinceLastSuccess:
        decodeIntOrNull(json['errors_since_last_success']) ?? 0,
    lastRequestAt: decodeDateTimeOrNull(json['last_request_at']),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'route',
    'id': id,
    'created_at': encodeDateTime(createdAt),
    'updated_at': encodeDateTime(updatedAt),
    'name': name,
    'url': url,
    'recipient': recipient,
    'attachments': attachments,
    'headers': headers,
    'group_by_message_id': groupByMessageId,
    'strip_replies': stripReplies,
    'enabled': enabled,
    'success_count': successCount,
    'error_count': errorCount,
    'errors_since_last_success': errorsSinceLastSuccess,
    'last_request_at': encodeDateTimeOrNull(lastRequestAt),
  };

  @override
  String toString() {
    final className = this is CreatedInboundRoute
        ? 'CreatedInboundRoute'
        : 'InboundRoute';
    return '$className(id: $id, name: $name, '
        'recipient: $recipient, url: $url, enabled: $enabled)';
  }
}

/// A route as returned by `routes.create`, including its signing secret.
///
/// The secret is returned only once. Store it to verify route deliveries
/// with `WebhookVerifier` from `package:ahasend/webhooks.dart`.
final class const CreatedInboundRoute({
  required super.id,
  required super.createdAt,
  required super.updatedAt,
  required super.name,
  required super.url,
  required super.recipient,
  required super.attachments,
  required super.headers,
  required super.groupByMessageId,
  required super.stripReplies,
  required super.enabled,
  required super.successCount,
  required super.errorCount,
  required super.errorsSinceLastSuccess,

  /// The route signing secret, including its `aha-rsec-` prefix. It is
  /// returned only when the route is created.
  required final String secret,
  super.lastRequestAt,
  super.raw,
}) extends InboundRoute {
  /// Creates a created route.
  this;

  /// Decodes a created route from JSON.
  factory fromJson(JsonMap json) {
    final r = InboundRoute.fromJson(json);
    return CreatedInboundRoute(
      id: r.id,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      name: r.name,
      url: r.url,
      recipient: r.recipient,
      attachments: r.attachments,
      headers: r.headers,
      groupByMessageId: r.groupByMessageId,
      stripReplies: r.stripReplies,
      enabled: r.enabled,
      successCount: r.successCount,
      errorCount: r.errorCount,
      errorsSinceLastSuccess: r.errorsSinceLastSuccess,
      lastRequestAt: r.lastRequestAt,
      secret: json['secret'] as String,
      raw: json,
    );
  }

  @override
  JsonMap toJson() => {...super.toJson(), 'secret': secret};
}

/// A request to create a route.
final class const CreateRouteRequest({
  /// The route name (at most 255 characters).
  required final String name,

  /// The URL inbound messages are posted to.
  required final String url,

  /// The recipient filter, for example `support@example.com` or
  /// `ticket-*@example.com`.
  required final String recipient,

  /// Whether to include attachments. Defaults to `false`.
  final bool? attachments,

  /// Whether to include headers. Defaults to `false`.
  final bool? headers,

  /// Whether to group by Message-ID. Defaults to `false`.
  final bool? groupByMessageId,

  /// Whether to strip quoted reply content. Defaults to `false`.
  final bool? stripReplies,

  /// Whether the route is enabled. Defaults to `true`.
  final bool? enabled,
}) {
  /// Creates a route creation request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'name': name,
    'url': url,
    'recipient': recipient,
    'attachments': ?attachments,
    'headers': ?headers,
    'group_by_message_id': ?groupByMessageId,
    'strip_replies': ?stripReplies,
    'enabled': ?enabled,
  };
}

/// A request to update a route. Fields left `null` keep their value.
final class const UpdateRouteRequest({
  /// The route name (at most 255 characters).
  final String? name,

  /// The URL inbound messages are posted to.
  final String? url,

  /// The recipient filter.
  final String? recipient,

  /// Whether to include attachments.
  final bool? attachments,

  /// Whether to include headers.
  final bool? headers,

  /// Whether to group by Message-ID.
  final bool? groupByMessageId,

  /// Whether to strip quoted reply content.
  final bool? stripReplies,

  /// Whether the route is enabled.
  final bool? enabled,
}) {
  /// Creates a route update request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'name': ?name,
    'url': ?url,
    'recipient': ?recipient,
    'attachments': ?attachments,
    'headers': ?headers,
    'group_by_message_id': ?groupByMessageId,
    'strip_replies': ?stripReplies,
    'enabled': ?enabled,
  };
}
