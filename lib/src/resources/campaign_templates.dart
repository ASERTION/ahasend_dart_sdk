import '../http/request_options.dart';
import '../models/campaign_templates.dart';
import '../models/common.dart';
import '../pagination.dart';
import 'resource.dart';

/// Manage campaign templates.
///
/// Access it through [AhaSendClient.campaignTemplates].
interface class CampaignTemplatesResource(super.transport, super.accountId)
    extends Resource {
  /// Creates the resource. Use [AhaSendClient.campaignTemplates] instead.
  this;

  String get _base => '$accountPath/campaign-templates';

  String _template(String templateId) => '$_base/${segment(templateId)}';

  /// Lists the account's campaign templates, each without its `content`.
  ///
  /// Requires the `templates:read` scope.
  Future<CursorPage<CampaignTemplate>> list({
    int? limit,
    String? after,
    String? before,
    RequestOptions? options,
  }) async => await fetchPage(
    _base,
    CampaignTemplate.fromJson,
    query: {'limit': limit},
    after: after,
    before: before,
    options: options,
  );

  /// Iterates over every campaign template, fetching pages as needed.
  ///
  /// Requires the `templates:read` scope.
  Stream<CampaignTemplate> listAll({
    int? limit,
    RequestOptions? options,
  }) async* {
    yield* fetchAll(
      _base,
      CampaignTemplate.fromJson,
      query: {'limit': limit},
      options: options,
    );
  }

  /// Creates a campaign template.
  ///
  /// Requires the `templates:write` scope.
  Future<CampaignTemplate> create(
    CreateCampaignTemplateRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    _base,
    CampaignTemplate.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Fetches a campaign template with its content.
  ///
  /// Requires the `templates:read` scope.
  Future<CampaignTemplate> get(
    String templateId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'GET',
    _template(templateId),
    CampaignTemplate.fromJson,
    options: options,
  );

  /// Changes a campaign template. Campaigns made from it earlier keep their
  /// own copy of the design.
  ///
  /// Requires the `templates:write` scope.
  Future<CampaignTemplate> update(
    String templateId,
    UpdateCampaignTemplateRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'PUT',
    _template(templateId),
    CampaignTemplate.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Deletes a campaign template.
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
}
