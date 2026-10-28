import '../http/request_options.dart';
import '../models/statistics.dart';
import 'resource.dart';

/// Read transactional email statistics.
///
/// Access it through [AhaSendClient.statistics]. The statistics endpoints
/// are rate limited to one request per second.
///
/// Every method takes the same filters:
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

  /// Returns message counts by delivery status, one entry per time bucket.
  ///
  /// Requires the `statistics-transactional:read:all` or
  /// `statistics-transactional:read:{domain}` scope.
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
  /// Requires the `statistics-transactional:read:all` or
  /// `statistics-transactional:read:{domain}` scope.
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
  /// Requires the `statistics-transactional:read:all` or
  /// `statistics-transactional:read:{domain}` scope.
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
