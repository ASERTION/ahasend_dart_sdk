import '../http/request_options.dart';
import '../models/common.dart';
import '../models/smtp_credentials.dart';
import '../pagination.dart';
import 'resource.dart';

/// Create, list and delete SMTP credentials. Credentials cannot be
/// updated.
///
/// Access it through [AhaSendClient.smtpCredentials].
interface class SmtpCredentialsResource(super.transport, super.accountId)
    extends Resource {
  /// Creates the resource. Use [AhaSendClient.smtpCredentials] instead.
  this;

  /// Lists the SMTP credentials of the account. Domain-scoped roles only
  /// see credentials with at least one authorized domain.
  ///
  /// Requires the `smtp-credentials:read:all` or
  /// `smtp-credentials:read:{domain}` scope.
  Future<CursorPage<SmtpCredential>> list({
    int? limit,
    String? after,
    String? before,
    RequestOptions? options,
  }) async => await fetchPage(
    '$accountPath/smtp-credentials',
    SmtpCredential.fromJson,
    query: {'limit': limit},
    after: after,
    before: before,
    options: options,
  );

  /// Iterates over every SMTP credential, fetching pages as needed.
  ///
  /// Requires the `smtp-credentials:read:all` or
  /// `smtp-credentials:read:{domain}` scope.
  Stream<SmtpCredential> listAll({int? limit, RequestOptions? options}) async* {
    yield* fetchAll(
      '$accountPath/smtp-credentials',
      SmtpCredential.fromJson,
      query: {'limit': limit},
      options: options,
    );
  }

  /// Creates an SMTP credential. The response holds the one-time
  /// [CreatedSmtpCredential.password].
  ///
  /// Requires the `smtp-credentials:write:all` scope, or for a scoped
  /// credential `smtp-credentials:write:{domain}` for every domain.
  Future<CreatedSmtpCredential> create(
    CreateSmtpCredentialRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '$accountPath/smtp-credentials',
    CreatedSmtpCredential.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Fetches an SMTP credential.
  ///
  /// Requires the `smtp-credentials:read:all` scope or
  /// `smtp-credentials:read:{domain}` for one of its domains.
  Future<SmtpCredential> get(
    String smtpCredentialId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'GET',
    '$accountPath/smtp-credentials/${segment(smtpCredentialId)}',
    SmtpCredential.fromJson,
    options: options,
  );

  /// Deletes an SMTP credential.
  ///
  /// Requires the `smtp-credentials:delete:all` scope or
  /// `smtp-credentials:delete:{domain}` for one of its domains.
  Future<SuccessResponse> delete(
    String smtpCredentialId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'DELETE',
    '$accountPath/smtp-credentials/${segment(smtpCredentialId)}',
    SuccessResponse.fromJson,
    options: options,
  );
}
