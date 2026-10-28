import '../http/request_options.dart';
import '../models/accounts.dart';
import '../models/common.dart';
import 'resource.dart';

/// Read and update the account and manage its members.
///
/// Access it through [AhaSendClient.accounts].
interface class AccountsResource(super.transport, super.accountId)
    extends Resource {
  /// Creates the resource. Use [AhaSendClient.accounts] instead.
  this;

  /// Fetches the account.
  ///
  /// Requires the `accounts:read` scope.
  Future<Account> get({RequestOptions? options}) async => await sendAndDecode(
    'GET',
    accountPath,
    Account.fromJson,
    options: options,
  );

  /// Updates the account settings.
  ///
  /// Requires the `accounts:write` scope.
  Future<Account> update(
    UpdateAccountRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'PUT',
    accountPath,
    Account.fromJson,
    body: request.toJson(),
    options: options,
  );

  /// Lists the members of the account.
  ///
  /// Requires the `accounts:members:read` scope.
  Future<List<UserAccount>> listMembers({RequestOptions? options}) async =>
      await fetchList(
        '$accountPath/members',
        UserAccount.fromJson,
        options: options,
      );

  /// Adds a member to the account.
  ///
  /// Requires the `accounts:members:add` scope.
  Future<UserAccount> addMember(
    AddMemberRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '$accountPath/members',
    UserAccount.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Removes a member from the account. You cannot remove yourself or the
  /// account owner.
  ///
  /// Requires the `accounts:members:remove` scope.
  Future<SuccessResponse> removeMember(
    String userId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'DELETE',
    '$accountPath/members/${segment(userId)}',
    SuccessResponse.fromJson,
    options: options,
  );
}
