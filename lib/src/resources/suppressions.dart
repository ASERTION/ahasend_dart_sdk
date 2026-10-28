import '../http/request_options.dart';
import '../models/common.dart';
import '../models/suppressions.dart';
import '../pagination.dart';
import 'resource.dart';

/// List, add and remove suppressed addresses.
///
/// Access it through [AhaSendClient.suppressions].
interface class SuppressionsResource(super.transport, super.accountId)
    extends Resource {
  /// Creates the resource. Use [AhaSendClient.suppressions] instead.
  this;

  /// Lists suppressions.
  ///
  /// [fromTime] and [toTime] bound the creation time. [limit] is 1 to 100.
  ///
  /// Requires the `suppressions:read` scope.
  Future<CursorPage<Suppression>> list({
    String? domain,
    String? email,
    DateTime? fromTime,
    DateTime? toTime,
    int? limit,
    String? after,
    String? before,
    RequestOptions? options,
  }) async => await fetchPage(
    '$accountPath/suppressions',
    Suppression.fromJson,
    query: _listQuery(
      domain: domain,
      email: email,
      fromTime: fromTime,
      toTime: toTime,
      limit: limit,
    ),
    after: after,
    before: before,
    options: options,
  );

  /// Iterates over every suppression matching the filters, fetching pages
  /// as needed. Takes the same filters as [list].
  Stream<Suppression> listAll({
    String? domain,
    String? email,
    DateTime? fromTime,
    DateTime? toTime,
    int? limit,
    RequestOptions? options,
  }) async* {
    yield* fetchAll(
      '$accountPath/suppressions',
      Suppression.fromJson,
      query: _listQuery(
        domain: domain,
        email: email,
        fromTime: fromTime,
        toTime: toTime,
        limit: limit,
      ),
      options: options,
    );
  }

  /// Suppresses an email address for one domain, or for all account
  /// domains when [CreateSuppressionRequest.domain] is omitted.
  ///
  /// The request carries an idempotency key.
  ///
  /// Requires the `suppressions:write` scope.
  Future<CreateSuppressionResponse> create(
    CreateSuppressionRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '$accountPath/suppressions',
    CreateSuppressionResponse.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Deletes the suppressions of [email], optionally only for [domain].
  ///
  /// Requires the `suppressions:delete` scope.
  Future<SuccessResponse> delete(
    String email, {
    String? domain,
    RequestOptions? options,
  }) async => await sendAndDecode(
    'DELETE',
    '$accountPath/suppressions',
    SuccessResponse.fromJson,
    query: {'email': email, 'domain': domain},
    options: options,
  );

  /// Deletes all of the account's suppressions, optionally only for
  /// [domain]. Protected suppressions are kept; the response message says
  /// how many.
  ///
  /// Requires the `suppressions:wipe` scope.
  Future<SuccessResponse> deleteAll({
    String? domain,
    RequestOptions? options,
  }) async => await sendAndDecode(
    'DELETE',
    '$accountPath/suppressions/all',
    SuccessResponse.fromJson,
    query: {'domain': domain},
    options: options,
  );

  Map<String, Object?> _listQuery({
    String? domain,
    String? email,
    DateTime? fromTime,
    DateTime? toTime,
    int? limit,
  }) => {
    'domain': domain,
    'email': email,
    'from_time': fromTime,
    'to_time': toTime,
    'limit': limit,
  };
}
