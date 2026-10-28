import '../http/request_options.dart';
import '../models/api_keys.dart';
import '../models/common.dart';
import '../pagination.dart';
import 'resource.dart';

/// Create, list, update and delete API keys.
///
/// Access it through [AhaSendClient.apiKeys].
interface class ApiKeysResource(super.transport, super.accountId)
    extends Resource {
  /// Creates the resource. Use [AhaSendClient.apiKeys] instead.
  this;

  /// Lists the API keys of the account.
  ///
  /// Requires the `api-keys:read` scope.
  Future<CursorPage<ApiKey>> list({
    int? limit,
    String? after,
    String? before,
    RequestOptions? options,
  }) async => await fetchPage(
    '$accountPath/api-keys',
    ApiKey.fromJson,
    query: {'limit': limit},
    after: after,
    before: before,
    options: options,
  );

  /// Iterates over every API key of the account, fetching pages as needed.
  ///
  /// Requires the `api-keys:read` scope.
  Stream<ApiKey> listAll({int? limit, RequestOptions? options}) async* {
    yield* fetchAll(
      '$accountPath/api-keys',
      ApiKey.fromJson,
      query: {'limit': limit},
      options: options,
    );
  }

  /// Creates an API key. The response holds the one-time
  /// [CreatedApiKey.secretKey].
  ///
  /// Requires the `api-keys:write` scope.
  Future<CreatedApiKey> create(
    CreateApiKeyRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '$accountPath/api-keys',
    CreatedApiKey.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Fetches an API key.
  ///
  /// Requires the `api-keys:read` scope.
  Future<ApiKey> get(String keyId, {RequestOptions? options}) async =>
      await sendAndDecode(
        'GET',
        '$accountPath/api-keys/${segment(keyId)}',
        ApiKey.fromJson,
        options: options,
      );

  /// Updates the label, scopes or IP allow list of an API key.
  ///
  /// Requires the `api-keys:write` scope.
  Future<ApiKey> update(
    String keyId,
    UpdateApiKeyRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'PUT',
    '$accountPath/api-keys/${segment(keyId)}',
    ApiKey.fromJson,
    body: requireFields(request.toJson()),
    options: options,
  );

  /// Deletes an API key.
  ///
  /// Requires the `api-keys:delete` scope.
  Future<SuccessResponse> delete(
    String keyId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'DELETE',
    '$accountPath/api-keys/${segment(keyId)}',
    SuccessResponse.fromJson,
    options: options,
  );
}
