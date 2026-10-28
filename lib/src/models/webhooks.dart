import '../json.dart';

/// Which domains a webhook receives events for.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const WebhookScope(
  /// The string the API uses for this value.
  String value,
) {
  /// Events for every domain of the account.
  static const WebhookScope global = WebhookScope('global');

  /// Events for the domains in [Webhook.domains] only.
  static const WebhookScope scoped = WebhookScope('scoped');

  /// Every value this version of the package knows.
  static const List<WebhookScope> values = [global, scoped];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// A webhook endpoint that receives event notifications.
final class const Webhook({
  /// The webhook ID.
  required final String id,

  /// When the webhook was created.
  required final DateTime createdAt,

  /// When the webhook was last updated.
  required final DateTime updatedAt,

  /// The webhook name.
  required final String name,

  /// The URL events are posted to.
  required final String url,

  /// Whether the webhook is enabled.
  required final bool enabled,

  /// Whether `message.reception` events are sent.
  required final bool onReception,

  /// Whether `message.delivered` events are sent.
  required final bool onDelivered,

  /// Whether `message.transient_error` events are sent.
  required final bool onTransientError,

  /// Whether `message.failed` events are sent.
  required final bool onFailed,

  /// Whether `message.bounced` events are sent.
  required final bool onBounced,

  /// Whether `message.suppressed` events are sent.
  required final bool onSuppressed,

  /// Whether `message.opened` events are sent.
  required final bool onOpened,

  /// Whether `message.clicked` events are sent.
  required final bool onClicked,

  /// Whether `suppression.created` events are sent.
  required final bool onSuppressionCreated,

  /// Whether `domain.dns_error` events are sent.
  required final bool onDnsError,

  /// Whether the webhook covers all domains or only [domains].
  required final WebhookScope scope,

  /// The domains a scoped webhook applies to. Empty for global webhooks.
  required final List<String> domains,

  /// The number of successful calls.
  required final int successCount,

  /// The number of failed calls.
  required final int errorCount,

  /// The number of consecutive failed calls since the last success.
  required final int errorsSinceLastSuccess,

  /// When the webhook was last called.
  final DateTime? lastRequestAt,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a webhook.
  this;

  /// Decodes a webhook from JSON.
  factory fromJson(JsonMap json) => Webhook(
    id: json['id'] as String,
    createdAt: decodeDateTime(json['created_at']),
    updatedAt: decodeDateTime(json['updated_at']),
    name: json['name'] as String? ?? '',
    url: json['url'] as String,
    enabled: json['enabled'] as bool? ?? false,
    onReception: json['on_reception'] as bool? ?? false,
    onDelivered: json['on_delivered'] as bool? ?? false,
    onTransientError: json['on_transient_error'] as bool? ?? false,
    onFailed: json['on_failed'] as bool? ?? false,
    onBounced: json['on_bounced'] as bool? ?? false,
    onSuppressed: json['on_suppressed'] as bool? ?? false,
    onOpened: json['on_opened'] as bool? ?? false,
    onClicked: json['on_clicked'] as bool? ?? false,
    onSuppressionCreated: json['on_suppression_created'] as bool? ?? false,
    onDnsError: json['on_dns_error'] as bool? ?? false,
    scope: decodeEnum(json['scope'], WebhookScope.new),
    domains: decodeScalarList<String>(json['domains']),
    successCount: decodeIntOrNull(json['success_count']) ?? 0,
    errorCount: decodeIntOrNull(json['error_count']) ?? 0,
    errorsSinceLastSuccess:
        decodeIntOrNull(json['errors_since_last_success']) ?? 0,
    lastRequestAt: decodeDateTimeOrNull(json['last_request_at']),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'webhook',
    'id': id,
    'created_at': encodeDateTime(createdAt),
    'updated_at': encodeDateTime(updatedAt),
    'name': name,
    'url': url,
    'enabled': enabled,
    'on_reception': onReception,
    'on_delivered': onDelivered,
    'on_transient_error': onTransientError,
    'on_failed': onFailed,
    'on_bounced': onBounced,
    'on_suppressed': onSuppressed,
    'on_opened': onOpened,
    'on_clicked': onClicked,
    'on_suppression_created': onSuppressionCreated,
    'on_dns_error': onDnsError,
    'scope': scope.value,
    'domains': domains,
    'success_count': successCount,
    'error_count': errorCount,
    'errors_since_last_success': errorsSinceLastSuccess,
    'last_request_at': encodeDateTimeOrNull(lastRequestAt),
  };

  @override
  String toString() {
    final className = this is CreatedWebhook ? 'CreatedWebhook' : 'Webhook';
    return '$className(id: $id, name: $name, url: $url, '
        'enabled: $enabled, scope: ${scope.value})';
  }
}

/// A webhook as returned by `webhooks.create`, including its signing secret.
///
/// The secret is returned only once. Store it to verify deliveries with
/// `WebhookVerifier` from `package:ahasend/webhooks.dart`.
final class const CreatedWebhook({
  required super.id,
  required super.createdAt,
  required super.updatedAt,
  required super.name,
  required super.url,
  required super.enabled,
  required super.onReception,
  required super.onDelivered,
  required super.onTransientError,
  required super.onFailed,
  required super.onBounced,
  required super.onSuppressed,
  required super.onOpened,
  required super.onClicked,
  required super.onSuppressionCreated,
  required super.onDnsError,
  required super.scope,
  required super.domains,
  required super.successCount,
  required super.errorCount,
  required super.errorsSinceLastSuccess,

  /// The webhook signing secret, including its `aha-whsec-` prefix. It is
  /// returned only when the webhook is created and cannot be changed.
  required final String secret,
  super.lastRequestAt,
  super.raw,
}) extends Webhook {
  /// Creates a created webhook.
  this;

  /// Decodes a created webhook from JSON.
  factory fromJson(JsonMap json) {
    final w = Webhook.fromJson(json);
    return CreatedWebhook(
      id: w.id,
      createdAt: w.createdAt,
      updatedAt: w.updatedAt,
      name: w.name,
      url: w.url,
      enabled: w.enabled,
      onReception: w.onReception,
      onDelivered: w.onDelivered,
      onTransientError: w.onTransientError,
      onFailed: w.onFailed,
      onBounced: w.onBounced,
      onSuppressed: w.onSuppressed,
      onOpened: w.onOpened,
      onClicked: w.onClicked,
      onSuppressionCreated: w.onSuppressionCreated,
      onDnsError: w.onDnsError,
      scope: w.scope,
      domains: w.domains,
      successCount: w.successCount,
      errorCount: w.errorCount,
      errorsSinceLastSuccess: w.errorsSinceLastSuccess,
      lastRequestAt: w.lastRequestAt,
      secret: json['secret'] as String,
      raw: json,
    );
  }

  @override
  JsonMap toJson() => {...super.toJson(), 'secret': secret};
}

/// A request to create a webhook.
final class const CreateWebhookRequest({
  /// The webhook name (at most 255 characters).
  required final String name,

  /// The URL events are posted to.
  required final String url,

  /// Whether the webhook covers all domains or only [domains].
  /// [WebhookScope.global] requires `webhooks:write:all`.
  required final WebhookScope scope,

  /// The domains of a scoped webhook. Ignored for global webhooks.
  final List<String>? domains,

  /// Whether the webhook is enabled.
  final bool? enabled,

  /// Whether to send `message.reception` events.
  final bool? onReception,

  /// Whether to send `message.delivered` events.
  final bool? onDelivered,

  /// Whether to send `message.transient_error` events.
  final bool? onTransientError,

  /// Whether to send `message.failed` events.
  final bool? onFailed,

  /// Whether to send `message.bounced` events.
  final bool? onBounced,

  /// Whether to send `message.suppressed` events.
  final bool? onSuppressed,

  /// Whether to send `message.opened` events.
  final bool? onOpened,

  /// Whether to send `message.clicked` events.
  final bool? onClicked,

  /// Whether to send `suppression.created` events.
  final bool? onSuppressionCreated,

  /// Whether to send `domain.dns_error` events.
  final bool? onDnsError,
}) {
  /// Creates a webhook creation request.
  ///
  /// A [WebhookScope.scoped] webhook needs at least one entry in [domains].
  /// Event flags default to `false`; [enabled] defaults to `true`.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'name': name,
    'url': url,
    'enabled': ?enabled,
    'on_reception': ?onReception,
    'on_delivered': ?onDelivered,
    'on_transient_error': ?onTransientError,
    'on_failed': ?onFailed,
    'on_bounced': ?onBounced,
    'on_suppressed': ?onSuppressed,
    'on_opened': ?onOpened,
    'on_clicked': ?onClicked,
    'on_suppression_created': ?onSuppressionCreated,
    'on_dns_error': ?onDnsError,
    'scope': scope.value,
    'domains': ?domains,
  };
}

/// A request to update a webhook. Fields left `null` keep their value.
///
/// The signing secret cannot be changed.
final class const UpdateWebhookRequest({
  /// The webhook name (at most 255 characters).
  final String? name,

  /// The URL events are posted to.
  final String? url,

  /// Whether the webhook is enabled.
  final bool? enabled,

  /// Whether to send `message.reception` events.
  final bool? onReception,

  /// Whether to send `message.delivered` events.
  final bool? onDelivered,

  /// Whether to send `message.transient_error` events.
  final bool? onTransientError,

  /// Whether to send `message.failed` events.
  final bool? onFailed,

  /// Whether to send `message.bounced` events.
  final bool? onBounced,

  /// Whether to send `message.suppressed` events.
  final bool? onSuppressed,

  /// Whether to send `message.opened` events.
  final bool? onOpened,

  /// Whether to send `message.clicked` events.
  final bool? onClicked,

  /// Whether to send `suppression.created` events.
  final bool? onSuppressionCreated,

  /// Whether to send `domain.dns_error` events.
  final bool? onDnsError,

  /// The new scope. Changing to [WebhookScope.scoped] requires a non-empty
  /// [domains] list in the same request; changing to [WebhookScope.global]
  /// clears the domain associations and requires `webhooks:write:all`.
  final WebhookScope? scope,

  /// The domains of a scoped webhook. A list replaces the associations;
  /// an empty list clears them. Ignored when the resulting scope is global.
  final List<String>? domains,
}) {
  /// Creates a webhook update request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'name': ?name,
    'url': ?url,
    'enabled': ?enabled,
    'on_reception': ?onReception,
    'on_delivered': ?onDelivered,
    'on_transient_error': ?onTransientError,
    'on_failed': ?onFailed,
    'on_bounced': ?onBounced,
    'on_suppressed': ?onSuppressed,
    'on_opened': ?onOpened,
    'on_clicked': ?onClicked,
    'on_suppression_created': ?onSuppressionCreated,
    'on_dns_error': ?onDnsError,
    'scope': ?scope?.value,
    'domains': ?domains,
  };
}
