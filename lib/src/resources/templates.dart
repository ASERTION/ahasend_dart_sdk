import '../http/request_options.dart';
import '../models/common.dart';
import '../models/templates.dart';
import '../pagination.dart';
import 'resource.dart';

/// Manage transactional templates, drafts and versions.
///
/// Access it through [AhaSendClient.templates].
interface class TemplatesResource(super.transport, super.accountId)
    extends Resource {
  /// Creates the resource. Use [AhaSendClient.templates] instead.
  this;

  String get _base => '$accountPath/templates';

  String _template(String templateId) => '$_base/${segment(templateId)}';

  /// Lists the account's transactional templates, each without its
  /// `content`.
  ///
  /// Requires the `templates:read` scope.
  Future<CursorPage<Template>> list({
    int? limit,
    String? after,
    String? before,
    RequestOptions? options,
  }) async => await fetchPage(
    _base,
    Template.fromJson,
    query: {'limit': limit},
    after: after,
    before: before,
    options: options,
  );

  /// Iterates over every transactional template, fetching pages as needed.
  ///
  /// Requires the `templates:read` scope.
  Stream<Template> listAll({int? limit, RequestOptions? options}) async* {
    yield* fetchAll(
      _base,
      Template.fromJson,
      query: {'limit': limit},
      options: options,
    );
  }

  /// Creates a transactional template. The returned template is the
  /// published copy; `hasDraft` says whether a draft was left.
  ///
  /// Requires the `templates:write` scope.
  Future<Template> create(
    CreateTemplateRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    _base,
    Template.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Fetches a transactional template with its published content.
  ///
  /// Requires the `templates:read` scope.
  Future<Template> get(String templateId, {RequestOptions? options}) async =>
      await sendAndDecode(
        'GET',
        _template(templateId),
        Template.fromJson,
        options: options,
      );

  /// Changes a transactional template. Every field but the name goes to the
  /// draft.
  ///
  /// Requires the `templates:write` scope.
  Future<Template> update(
    String templateId,
    UpdateTemplateRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'PUT',
    _template(templateId),
    Template.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Deletes a transactional template.
  ///
  /// Requires the `templates:delete` scope.
  Future<SuccessResponse> delete(
    String templateId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'DELETE',
    _template(templateId),
    SuccessResponse.fromJson,
    options: options,
  );

  /// Fetches a template's draft: saved changes that are not published.
  ///
  /// Requires the `templates:read` scope.
  Future<TemplateDraft> getDraft(
    String templateId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'GET',
    '${_template(templateId)}/draft',
    TemplateDraft.fromJson,
    options: options,
  );

  /// Discards a template's draft and returns the template.
  ///
  /// Requires the `templates:write` scope.
  Future<Template> discardDraft(
    String templateId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'DELETE',
    '${_template(templateId)}/draft',
    Template.fromJson,
    options: options,
  );

  /// Publishes a template's draft, so sends use it.
  ///
  /// Requires the `templates:write` scope.
  Future<Template> publish(
    String templateId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '${_template(templateId)}/publish',
    Template.fromJson,
    idempotent: true,
    options: options,
  );

  /// Lists a template's published versions, newest first. A template keeps
  /// its 50 most recent versions, so the list is not paginated.
  ///
  /// Requires the `templates:read` scope.
  Future<List<TemplateVersion>> listVersions(
    String templateId, {
    RequestOptions? options,
  }) async => await fetchList(
    '${_template(templateId)}/versions',
    TemplateVersion.fromJson,
    options: options,
  );

  /// Fetches a published version of a template with its content.
  ///
  /// Requires the `templates:read` scope.
  Future<TemplateVersionDetail> getVersion(
    String templateId,
    String versionId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'GET',
    '${_template(templateId)}/versions/${segment(versionId)}',
    TemplateVersionDetail.fromJson,
    options: options,
  );

  /// Restores a published version into the template's draft. Pass a
  /// [request] with `publish: true` to publish the draft afterwards.
  ///
  /// Requires the `templates:write` scope.
  Future<Template> restoreVersion(
    String templateId,
    String versionId, {
    RestoreTemplateVersionRequest request =
        const RestoreTemplateVersionRequest(),
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '${_template(templateId)}/versions/${segment(versionId)}/restore',
    Template.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );
}
