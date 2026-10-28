import '../http/request_options.dart';
import '../models/common.dart';
import '../models/domains.dart';
import '../pagination.dart';
import 'resource.dart';

/// Add, verify, update and delete sending domains.
///
/// Access it through [AhaSendClient.domains].
interface class DomainsResource(super.transport, super.accountId)
    extends Resource {
  /// Creates the resource. Use [AhaSendClient.domains] instead.
  this;

  /// Lists the domains of the account.
  ///
  /// [dnsValid] filters by DNS validation status, [sendingType] by sending
  /// type.
  ///
  /// Requires the `domains:read` scope.
  Future<CursorPage<Domain>> list({
    bool? dnsValid,
    DomainSendingType? sendingType,
    int? limit,
    String? after,
    String? before,
    RequestOptions? options,
  }) async => await fetchPage(
    '$accountPath/domains',
    Domain.fromJson,
    query: {'dns_valid': dnsValid, 'sending_type': sendingType, 'limit': limit},
    after: after,
    before: before,
    options: options,
  );

  /// Iterates over every domain matching the filters, fetching pages as
  /// needed. Takes the same filters as [list].
  ///
  /// Requires the `domains:read` scope.
  Stream<Domain> listAll({
    bool? dnsValid,
    DomainSendingType? sendingType,
    int? limit,
    RequestOptions? options,
  }) async* {
    yield* fetchAll(
      '$accountPath/domains',
      Domain.fromJson,
      query: {
        'dns_valid': dnsValid,
        'sending_type': sendingType,
        'limit': limit,
      },
      options: options,
    );
  }

  /// Adds a domain. Configure its [Domain.dnsRecords], then call
  /// [checkDns].
  ///
  /// Requires the `domains:write` scope.
  Future<Domain> create(
    CreateDomainRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '$accountPath/domains',
    Domain.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Fetches a domain by name.
  ///
  /// Requires the `domains:read` scope.
  Future<Domain> get(String domain, {RequestOptions? options}) async =>
      await sendAndDecode(
        'GET',
        '$accountPath/domains/${segment(domain)}',
        Domain.fromJson,
        options: options,
      );

  /// Updates a domain's settings, such as custom subdomains and the DKIM
  /// rotation interval.
  ///
  /// Requires the `domains:write` scope.
  Future<Domain> update(
    String domain,
    UpdateDomainRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'PUT',
    '$accountPath/domains/${segment(domain)}',
    Domain.fromJson,
    body: request.toJson(),
    options: options,
  );

  /// Deletes a domain. Paused domains cannot be deleted.
  ///
  /// Requires the `domains:delete:all` or `domains:delete:{domain}` scope.
  Future<SuccessResponse> delete(
    String domain, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'DELETE',
    '$accountPath/domains/${segment(domain)}',
    SuccessResponse.fromJson,
    options: options,
  );

  /// Checks the domain's DNS records and returns the updated domain.
  ///
  /// A check within the last 60 seconds returns the cached result.
  ///
  /// Requires the `domains:write` scope.
  Future<Domain> checkDns(String domain, {RequestOptions? options}) async =>
      await sendAndDecode(
        'POST',
        '$accountPath/domains/${segment(domain)}/check-dns',
        Domain.fromJson,
        options: options,
      );
}
