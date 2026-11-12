import '../http/request_options.dart';
import '../models/statistics.dart';
import 'resource.dart';

/// Read email statistics.
///
/// Access it through [AhaSendClient.statistics].
///
/// Every method requires the `statistics:read:all` or a
/// `statistics:read:{domain}` scope. The API also accepts the older names
/// `statistics-transactional:read:all` and
/// `statistics-transactional:read:{domain}`.
///
/// [emails] returns stored email counts of transactional, campaign and
/// inbound mail, for any time in the account's history. It uses the
/// general rate limit.
///
/// [deliverability], [bounce] and [deliveryTime] return transactional
/// statistics, limited to the account's message retention period. They are
/// rate limited to one request per second and take the same filters:
///
/// * `fromTime` and `toTime` limit the time range.
/// * `senderDomains` limits the sender domains. A domain-scoped key must
///   cover every domain listed.
/// * `recipientDomains` limits the recipient domains, for example
///   `['gmail.com', 'googlemail.com']`.
/// * `tags` limits the message tags.
/// * `groupBy` sets the bucket size. The API default is
///   [StatisticsGroupBy.day].
interface class StatisticsResource(super.transport, super.accountId)
    extends Resource {
  /// Creates the resource. Use [AhaSendClient.statistics] instead.
  this;

  /// Returns email counts of the account, or of each of its domains, in
  /// hourly, daily, weekly or monthly periods.
  ///
  /// The counts cover transactional, campaign and inbound mail, for any
  /// time in the account's history. Inbound mail counts under the domain
  /// that received it. Sandbox mail is not counted. The numbers differ from
  /// [deliverability], which counts each message once by its current
  /// status, while this method counts events in the period they happened.
  ///
  /// * [fromTime] starts the range, included. It defaults to 30 days before
  ///   [toTime] and cannot be before 2000-01-01.
  /// * [toTime] ends the range, excluded. It defaults to now.
  /// * [groupBy] sets the length of each period, in UTC; weeks start on
  ///   Monday. The API default is [StatisticsGroupBy.day]. The range can be
  ///   at most 31 days for `hour`, 366 days for `day` and `week`, and 5
  ///   calendar years for `month`.
  /// * [senderDomains] limits the domains, at most 50, deleted domains
  ///   included. It defaults to every domain the key can read. The key must
  ///   be able to read every domain listed.
  /// * [breakdown] set to [EmailStatisticsBreakdown.domain] returns rows per
  ///   domain, paged by domain. Use [limit] (1 to 50, API default 25) and
  ///   [after], or [EmailStatisticsResponse.nextPage], to page. [limit] and
  ///   [after] are accepted only with a breakdown.
  ///
  /// The API rounds the range to whole periods; the response gives the
  /// rounded range.
  ///
  /// Requires the `statistics:read:all` or `statistics:read:{domain}`
  /// scope.
  Future<EmailStatisticsResponse> emails({
    DateTime? fromTime,
    DateTime? toTime,
    StatisticsGroupBy? groupBy,
    List<String>? senderDomains,
    EmailStatisticsBreakdown? breakdown,
    int? limit,
    String? after,
    RequestOptions? options,
  }) async {
    final query = <String, Object?>{
      'from_time': fromTime,
      'to_time': toTime,
      'group_by': groupBy,
      'sender_domain': senderDomains,
      'breakdown': breakdown,
      'limit': limit,
    };
    Future<EmailStatisticsResponse> fetch(String? cursor) async {
      final json = await sendRequest(
        'GET',
        '$accountPath/statistics/emails',
        query: {...query, 'after': cursor},
        options: options,
      );
      return decodeResponse<EmailStatisticsResponse>(
        json,
        (map) => EmailStatisticsResponse.fromJson(map, fetchAfter: fetch),
      );
    }

    return await fetch(after);
  }

  /// Returns message counts by delivery status, one entry per time bucket.
  ///
  /// Requires the `statistics:read:all` or `statistics:read:{domain}`
  /// scope.
  Future<List<DeliverabilityStatistics>> deliverability({
    DateTime? fromTime,
    DateTime? toTime,
    List<String>? senderDomains,
    List<String>? recipientDomains,
    List<String>? tags,
    StatisticsGroupBy? groupBy,
    RequestOptions? options,
  }) async => await fetchList(
    '$accountPath/statistics/transactional/deliverability',
    DeliverabilityStatistics.fromJson,
    query: _query(
      fromTime: fromTime,
      toTime: toTime,
      senderDomains: senderDomains,
      recipientDomains: recipientDomains,
      tags: tags,
      groupBy: groupBy,
    ),
    options: options,
  );

  /// Returns bounce counts by classification, one entry per time bucket.
  ///
  /// Requires the `statistics:read:all` or `statistics:read:{domain}`
  /// scope.
  Future<List<BounceStatistics>> bounce({
    DateTime? fromTime,
    DateTime? toTime,
    List<String>? senderDomains,
    List<String>? recipientDomains,
    List<String>? tags,
    StatisticsGroupBy? groupBy,
    RequestOptions? options,
  }) async => await fetchList(
    '$accountPath/statistics/transactional/bounce',
    BounceStatistics.fromJson,
    query: _query(
      fromTime: fromTime,
      toTime: toTime,
      senderDomains: senderDomains,
      recipientDomains: recipientDomains,
      tags: tags,
      groupBy: groupBy,
    ),
    options: options,
  );

  /// Returns delivery times by recipient domain, one entry per time bucket.
  ///
  /// Requires the `statistics:read:all` or `statistics:read:{domain}`
  /// scope.
  Future<List<DeliveryTimeStatistics>> deliveryTime({
    DateTime? fromTime,
    DateTime? toTime,
    List<String>? senderDomains,
    List<String>? recipientDomains,
    List<String>? tags,
    StatisticsGroupBy? groupBy,
    RequestOptions? options,
  }) async => await fetchList(
    '$accountPath/statistics/transactional/delivery-time',
    DeliveryTimeStatistics.fromJson,
    query: _query(
      fromTime: fromTime,
      toTime: toTime,
      senderDomains: senderDomains,
      recipientDomains: recipientDomains,
      tags: tags,
      groupBy: groupBy,
    ),
    options: options,
  );

  Map<String, Object?> _query({
    DateTime? fromTime,
    DateTime? toTime,
    List<String>? senderDomains,
    List<String>? recipientDomains,
    List<String>? tags,
    StatisticsGroupBy? groupBy,
  }) => {
    'from_time': fromTime,
    'to_time': toTime,
    'sender_domain': senderDomains,
    'recipient_domains': recipientDomains,
    'tags': tags,
    'group_by': groupBy,
  };
}
