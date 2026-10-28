import '../http/request_options.dart';
import '../models/common.dart';
import '../models/webhooks.dart';
import '../pagination.dart';
import 'resource.dart';

/// Manage webhook endpoints.
///
/// Access it through [AhaSendClient.webhooks]. To verify deliveries, use
/// `WebhookVerifier` from `package:ahasend/webhooks.dart`.
interface class WebhooksResource(super.transport, super.accountId)
    extends Resource {
  /// Creates the resource. Use [AhaSendClient.webhooks] instead.
  this;

  /// Lists the account's webhooks.
  ///
  /// Each filter, when set, only returns webhooks whose flag has that
  /// value. Domain-scoped keys only see webhooks associated with an
  /// authorized domain.
  ///
  /// Requires the `webhooks:read:all` or `webhooks:read:{domain}` scope.
  Future<CursorPage<Webhook>> list({
    bool? enabled,
    bool? onReception,
    bool? onDelivered,
    bool? onTransientError,
    bool? onFailed,
    bool? onBounced,
    bool? onSuppressed,
    bool? onOpened,
    bool? onClicked,
    bool? onSuppressionCreated,
    bool? onDnsError,
    int? limit,
    String? after,
    String? before,
    RequestOptions? options,
  }) async => await fetchPage(
    '$accountPath/webhooks',
    Webhook.fromJson,
    query: _listQuery(
      enabled: enabled,
      onReception: onReception,
      onDelivered: onDelivered,
      onTransientError: onTransientError,
      onFailed: onFailed,
      onBounced: onBounced,
      onSuppressed: onSuppressed,
      onOpened: onOpened,
      onClicked: onClicked,
      onSuppressionCreated: onSuppressionCreated,
      onDnsError: onDnsError,
      limit: limit,
    ),
    after: after,
    before: before,
    options: options,
  );

  /// Iterates over every webhook matching the filters, fetching pages as
  /// needed. Takes the same filters as [list].
  Stream<Webhook> listAll({
    bool? enabled,
    bool? onReception,
    bool? onDelivered,
    bool? onTransientError,
    bool? onFailed,
    bool? onBounced,
    bool? onSuppressed,
    bool? onOpened,
    bool? onClicked,
    bool? onSuppressionCreated,
    bool? onDnsError,
    int? limit,
    RequestOptions? options,
  }) async* {
    yield* fetchAll(
      '$accountPath/webhooks',
      Webhook.fromJson,
      query: _listQuery(
        enabled: enabled,
        onReception: onReception,
        onDelivered: onDelivered,
        onTransientError: onTransientError,
        onFailed: onFailed,
        onBounced: onBounced,
        onSuppressed: onSuppressed,
        onOpened: onOpened,
        onClicked: onClicked,
        onSuppressionCreated: onSuppressionCreated,
        onDnsError: onDnsError,
        limit: limit,
      ),
      options: options,
    );
  }

  /// Creates a webhook.
  ///
  /// The response holds the signing secret, which is returned only once.
  /// The request carries an idempotency key, so the client retries it
  /// safely.
  ///
  /// Requires the `webhooks:write:all` scope, or `webhooks:write:{domain}`
  /// for every domain of a scoped webhook.
  Future<CreatedWebhook> create(
    CreateWebhookRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '$accountPath/webhooks',
    CreatedWebhook.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Fetches a webhook.
  ///
  /// Requires the `webhooks:read:all` or `webhooks:read:{domain}` scope.
  Future<Webhook> get(String webhookId, {RequestOptions? options}) async =>
      await sendAndDecode(
        'GET',
        '$accountPath/webhooks/${segment(webhookId)}',
        Webhook.fromJson,
        options: options,
      );

  /// Updates a webhook. Fields left `null` in [request] are unchanged.
  ///
  /// Requires the `webhooks:write:all` or `webhooks:write:{domain}` scope;
  /// changing to a global scope requires `webhooks:write:all`.
  Future<Webhook> update(
    String webhookId,
    UpdateWebhookRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'PUT',
    '$accountPath/webhooks/${segment(webhookId)}',
    Webhook.fromJson,
    body: request.toJson(),
    options: options,
  );

  /// Deletes a webhook.
  ///
  /// Requires the `webhooks:delete:all` or `webhooks:delete:{domain}` scope.
  Future<SuccessResponse> delete(
    String webhookId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'DELETE',
    '$accountPath/webhooks/${segment(webhookId)}',
    SuccessResponse.fromJson,
    options: options,
  );

  Map<String, Object?> _listQuery({
    bool? enabled,
    bool? onReception,
    bool? onDelivered,
    bool? onTransientError,
    bool? onFailed,
    bool? onBounced,
    bool? onSuppressed,
    bool? onOpened,
    bool? onClicked,
    bool? onSuppressionCreated,
    bool? onDnsError,
    int? limit,
  }) => {
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
    'limit': limit,
  };
}
