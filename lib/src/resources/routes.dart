import '../http/request_options.dart';
import '../models/common.dart';
import '../models/routes.dart';
import '../pagination.dart';
import 'resource.dart';

/// Manage inbound routes.
///
/// Access it through [AhaSendClient.routes].
interface class RoutesResource(super.transport, super.accountId)
    extends Resource {
  /// Creates the resource. Use [AhaSendClient.routes] instead.
  this;

  /// Lists the account's routes.
  ///
  /// A key with only `routes:read:{domain}` must pass the matching
  /// [domain].
  ///
  /// Requires the `routes:read:all` or `routes:read:{domain}` scope.
  Future<CursorPage<InboundRoute>> list({
    String? domain,
    int? limit,
    String? after,
    String? before,
    RequestOptions? options,
  }) async => await fetchPage(
    '$accountPath/routes',
    InboundRoute.fromJson,
    query: {'domain': domain, 'limit': limit},
    after: after,
    before: before,
    options: options,
  );

  /// Iterates over every route, fetching pages as needed. Takes the same
  /// filters as [list].
  Stream<InboundRoute> listAll({
    String? domain,
    int? limit,
    RequestOptions? options,
  }) async* {
    yield* fetchAll(
      '$accountPath/routes',
      InboundRoute.fromJson,
      query: {'domain': domain, 'limit': limit},
      options: options,
    );
  }

  /// Creates a route for inbound email.
  ///
  /// The response holds the signing secret, which is returned only once.
  /// The request carries an idempotency key, so the client retries it
  /// safely.
  ///
  /// Requires the `routes:write:all` scope or `routes:write:{domain}` for
  /// the recipient's domain.
  Future<CreatedInboundRoute> create(
    CreateRouteRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '$accountPath/routes',
    CreatedInboundRoute.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Fetches a route.
  ///
  /// Requires the `routes:read:all` or `routes:read:{domain}` scope.
  Future<InboundRoute> get(String routeId, {RequestOptions? options}) async =>
      await sendAndDecode(
        'GET',
        '$accountPath/routes/${segment(routeId)}',
        InboundRoute.fromJson,
        options: options,
      );

  /// Updates a route.
  ///
  /// A domain-scoped key must cover the current recipient domain and, if
  /// [UpdateRouteRequest.recipient] changes it, the new one.
  ///
  /// Requires the `routes:write:all` or `routes:write:{domain}` scope.
  Future<InboundRoute> update(
    String routeId,
    UpdateRouteRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'PUT',
    '$accountPath/routes/${segment(routeId)}',
    InboundRoute.fromJson,
    body: request.toJson(),
    options: options,
  );

  /// Deletes a route.
  ///
  /// Requires the `routes:delete:all` or `routes:delete:{domain}` scope.
  Future<SuccessResponse> delete(
    String routeId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'DELETE',
    '$accountPath/routes/${segment(routeId)}',
    SuccessResponse.fromJson,
    options: options,
  );
}
