import '../http/request_options.dart';
import '../models/campaigns.dart';
import '../models/common.dart';
import '../pagination.dart';
import 'resource.dart';

/// Create, schedule, send and report on campaigns.
///
/// Access it through [AhaSendClient.campaigns].
interface class CampaignsResource(super.transport, super.accountId)
    extends Resource {
  /// Creates the resource. Use [AhaSendClient.campaigns] instead.
  this;

  String get _base => '$accountPath/campaigns';

  String _campaign(String campaignId) => '$_base/${segment(campaignId)}';

  /// Lists the account's campaigns, newest first, without their lists,
  /// content and issues.
  ///
  /// Requires the `campaigns:read` scope.
  Future<CursorPage<CampaignListItem>> list({
    CampaignStatus? status,
    int? limit,
    String? after,
    String? before,
    RequestOptions? options,
  }) async => await fetchPage(
    _base,
    CampaignListItem.fromJson,
    query: {'status': status, 'limit': limit},
    after: after,
    before: before,
    options: options,
  );

  /// Iterates over every campaign matching the filters, fetching pages as
  /// needed. Takes the same filters as [list].
  ///
  /// Requires the `campaigns:read` scope.
  Stream<CampaignListItem> listAll({
    CampaignStatus? status,
    int? limit,
    RequestOptions? options,
  }) async* {
    yield* fetchAll(
      _base,
      CampaignListItem.fromJson,
      query: {'status': status, 'limit': limit},
      options: options,
    );
  }

  /// Creates a draft campaign.
  ///
  /// Requires the `campaigns:write` scope.
  Future<Campaign> create(
    CreateCampaignRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    _base,
    Campaign.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Fetches a campaign with its lists, content and issues.
  ///
  /// Requires the `campaigns:read` scope.
  Future<Campaign> get(String campaignId, {RequestOptions? options}) async =>
      await sendAndDecode(
        'GET',
        _campaign(campaignId),
        Campaign.fromJson,
        options: options,
      );

  /// Changes a draft campaign.
  ///
  /// Requires the `campaigns:write` scope.
  Future<Campaign> update(
    String campaignId,
    UpdateCampaignRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'PUT',
    _campaign(campaignId),
    Campaign.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Deletes a draft campaign.
  ///
  /// Requires the `campaigns:delete` scope.
  Future<SuccessResponse> delete(
    String campaignId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'DELETE',
    _campaign(campaignId),
    SuccessResponse.fromJson,
    options: options,
  );

  /// Copies a campaign into a new draft. Without a name in [request] the
  /// copy is named `Copy of` and the source's name.
  ///
  /// Requires the `campaigns:write` scope.
  Future<Campaign> duplicate(
    String campaignId, {
    DuplicateCampaignRequest request = const DuplicateCampaignRequest(),
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '${_campaign(campaignId)}/duplicate',
    Campaign.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Sends a draft campaign now, or at `sendAt` in [request].
  ///
  /// A campaign with issues is refused with a [BadRequestException]; read
  /// the issues with [CampaignNotReady.fromException].
  ///
  /// Requires the `campaigns:send` scope.
  Future<CampaignSend> send(
    String campaignId, {
    SendCampaignRequest request = const SendCampaignRequest(),
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '${_campaign(campaignId)}/send',
    CampaignSend.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Returns a `validating` or `scheduled` campaign to `draft`.
  ///
  /// Requires the `campaigns:send` scope.
  Future<Campaign> unschedule(
    String campaignId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '${_campaign(campaignId)}/unschedule',
    Campaign.fromJson,
    idempotent: true,
    options: options,
  );

  /// Sends a test of a draft campaign to up to 5 addresses.
  ///
  /// A campaign with issues (other than `unsubscribe_link_missing`) is
  /// refused with a [BadRequestException]; read the issues with
  /// [CampaignNotReady.fromException].
  ///
  /// Requires the `campaigns:send` scope.
  Future<CampaignTest> test(
    String campaignId,
    TestCampaignRequest request, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'POST',
    '${_campaign(campaignId)}/test',
    CampaignTest.fromJson,
    body: request.toJson(),
    idempotent: true,
    options: options,
  );

  /// Fetches the numbers of a campaign.
  ///
  /// Requires the `campaigns:read` scope.
  Future<CampaignStats> stats(
    String campaignId, {
    RequestOptions? options,
  }) async => await sendAndDecode(
    'GET',
    '${_campaign(campaignId)}/stats',
    CampaignStats.fromJson,
    options: options,
  );

  /// Lists a campaign's recipients in one [status] or with one
  /// [bounceClassification], by contact ID, the highest first. Pass exactly
  /// one of the two filters, using keys of [CampaignStatsReport.byStatus]
  /// or [CampaignStatsReport.byBounceClassification].
  ///
  /// Requires the `campaigns:read` scope.
  Future<CursorPage<CampaignRecipient>> listRecipients(
    String campaignId, {
    String? status,
    String? bounceClassification,
    int? limit,
    String? after,
    String? before,
    RequestOptions? options,
  }) async => await fetchPage(
    '${_campaign(campaignId)}/recipients',
    CampaignRecipient.fromJson,
    query: {
      'status': status,
      'bounce_classification': bounceClassification,
      'limit': limit,
    },
    after: after,
    before: before,
    options: options,
  );

  /// Iterates over every recipient matching the filter, fetching pages as
  /// needed. Takes the same filters as [listRecipients].
  ///
  /// Requires the `campaigns:read` scope.
  Stream<CampaignRecipient> listAllRecipients(
    String campaignId, {
    String? status,
    String? bounceClassification,
    int? limit,
    RequestOptions? options,
  }) async* {
    yield* fetchAll(
      '${_campaign(campaignId)}/recipients',
      CampaignRecipient.fromJson,
      query: {
        'status': status,
        'bounce_classification': bounceClassification,
        'limit': limit,
      },
      options: options,
    );
  }
}
