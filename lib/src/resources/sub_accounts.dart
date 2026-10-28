import '../http/request_options.dart';
import '../models/api_keys.dart';
import '../models/common.dart';
import '../models/domains.dart';
import '../models/sub_accounts.dart';
import '../pagination.dart';
import 'resource.dart';

/// Create and manage sub-accounts and their API keys.
///
/// To act inside a sub-account, create a key with [apiKeys] and use
/// `AhaSendClient.forAccount` with the sub-account ID.
///
/// Access it through [AhaSendClient.subAccounts].
interface class SubAccountsResource(super.transport, super.accountId)
    extends Resource {
  /// Creates the resource. Use [AhaSendClient.subAccounts] instead.
  this;

  /// The API keys owned by sub-accounts.
  late final SubAccountApiKeysResource apiKeys = SubAccountApiKeysResource(
    transport,
    accountId,
  );

  /// Lists the sub-accounts of the parent account. Deleted sub-accounts are
  /// not included.
  ///
  /// Requires the `sub-accounts:read` scope.
  Future<CursorPage<SubAccount>> list({
    int? limit,
    String? after,
    String? before,
    RequestOptions? options,
  }) async => await fetchPage(
    '$accountPath/sub-accounts',
    SubAccount.fromJson,
    query: {'limit': limit},
    after: after,
    before: before,
    options: options,
  );

  /// Iterates over every sub-account, fetching pages as needed.
  ///
  /// Requires the `sub-accounts:read` scope.
  Stream<SubAccount> listAll({int? limit, RequestOptions? options}) async* {
    yield* fetchAll(
      '$accountPath/sub-accounts',
      SubAccount.fromJson,
      query: {'limit': limit},
      options: options,
    );
  }

  /// Creates a sub-account.
  ///
  /// Requires the `sub-accounts:write` scope.
  Future<SubAccount> create(
    CreateSubAccountRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '$accountPath/sub-accounts',
    SubAccount.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Fetches a sub-account.
  ///
  /// Requires the `sub-accounts:read` scope.
  Future<SubAccount> get(
    String subAccountId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'GET',
    _path(subAccountId),
    SubAccount.fromJson,
    options: options,
  );

  /// Updates a sub-account's name, website or monthly cap.
  ///
  /// Requires the `sub-accounts:write` scope.
  Future<SubAccount> update(
    String subAccountId,
    UpdateSubAccountRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'PUT',
    _path(subAccountId),
    SubAccount.fromJson,
    body: requireFields(request.toJson()),
    options: options,
  );

  /// Soft-deletes a sub-account.
  ///
  /// Requires the `sub-accounts:delete` scope.
  Future<SuccessResponse> delete(
    String subAccountId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'DELETE',
    _path(subAccountId),
    SuccessResponse.fromJson,
    options: options,
  );

  /// Pauses sending on a sub-account. Its status becomes
  /// [SubAccountStatus.suspended].
  ///
  /// Requires the `sub-accounts:suspend` scope.
  Future<SubAccount> suspend(
    String subAccountId,
    SuspendSubAccountRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '${_path(subAccountId)}/suspend',
    SubAccount.fromJson,
    body: request.toJson(),
    options: options,
  );

  /// Resumes sending on a paused sub-account.
  ///
  /// Requires the `sub-accounts:suspend` scope.
  Future<SubAccount> unsuspend(
    String subAccountId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '${_path(subAccountId)}/unsuspend',
    SubAccount.fromJson,
    options: options,
  );

  /// Lifts the pause on a domain of a sub-account so it can send again.
  ///
  /// Does nothing if the domain is not paused. The change can take some
  /// minutes to apply to new email.
  ///
  /// Requires the `sub-accounts:suspend` scope.
  Future<Domain> unpauseDomain(
    String subAccountId,
    String domain, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '${_path(subAccountId)}/domains/${segment(domain)}/unpause',
    Domain.fromJson,
    options: options,
  );

  /// Fetches the current billing-period usage and allocated cost of the
  /// parent and its active sub-accounts.
  ///
  /// Requires the `sub-accounts:usage` scope.
  Future<SubAccountUsageResponse> usage({RequestOptions? options}) async =>
      await sendAndDecode(
        'GET',
        '$accountPath/sub-accounts/usage',
        SubAccountUsageResponse.fromJson,
        options: options,
      );

  String _path(String subAccountId) =>
      '$accountPath/sub-accounts/${segment(subAccountId)}';
}

/// Create, list, update and delete the API keys owned by sub-accounts.
///
/// Access it through `client.subAccounts.apiKeys`. Only credentials of the
/// parent account can manage these keys.
interface class SubAccountApiKeysResource(super.transport, super.accountId)
    extends Resource {
  /// Creates the resource. Use `client.subAccounts.apiKeys` instead.
  this;

  /// Lists the API keys of a sub-account.
  ///
  /// Requires the `sub-account-api-keys:read` scope.
  Future<CursorPage<ApiKey>> list(
    String subAccountId, {
    int? limit,
    String? after,
    String? before,
    RequestOptions? options,
  }) async => await fetchPage(
    _path(subAccountId),
    ApiKey.fromJson,
    query: {'limit': limit},
    after: after,
    before: before,
    options: options,
  );

  /// Iterates over every API key of a sub-account, fetching pages as
  /// needed.
  ///
  /// Requires the `sub-account-api-keys:read` scope.
  Stream<ApiKey> listAll(
    String subAccountId, {
    int? limit,
    RequestOptions? options,
  }) async* {
    yield* fetchAll(
      _path(subAccountId),
      ApiKey.fromJson,
      query: {'limit': limit},
      options: options,
    );
  }

  /// Creates an API key owned by a sub-account. Its one-time
  /// [CreatedApiKey.secretKey] authenticates as the sub-account.
  ///
  /// Requires the `sub-account-api-keys:write` scope.
  Future<CreatedApiKey> create(
    String subAccountId,
    CreateApiKeyRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    _path(subAccountId),
    CreatedApiKey.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Fetches an API key of a sub-account.
  ///
  /// Requires the `sub-account-api-keys:read` scope.
  Future<ApiKey> get(
    String subAccountId,
    String keyId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'GET',
    '${_path(subAccountId)}/${segment(keyId)}',
    ApiKey.fromJson,
    options: options,
  );

  /// Updates an API key of a sub-account. Scopes are validated against the
  /// sub-account.
  ///
  /// Requires the `sub-account-api-keys:write` scope.
  Future<ApiKey> update(
    String subAccountId,
    String keyId,
    UpdateApiKeyRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'PUT',
    '${_path(subAccountId)}/${segment(keyId)}',
    ApiKey.fromJson,
    body: requireFields(request.toJson()),
    options: options,
  );

  /// Deletes an API key of a sub-account.
  ///
  /// Requires the `sub-account-api-keys:delete` scope.
  Future<SuccessResponse> delete(
    String subAccountId,
    String keyId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'DELETE',
    '${_path(subAccountId)}/${segment(keyId)}',
    SuccessResponse.fromJson,
    options: options,
  );

  String _path(String subAccountId) =>
      '$accountPath/sub-accounts/${segment(subAccountId)}/api-keys';
}
