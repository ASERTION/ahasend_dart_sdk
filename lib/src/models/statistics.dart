import 'package:meta/meta.dart';

import '../json.dart';
import '../pagination.dart';

/// The time period statistics are grouped by.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const StatisticsGroupBy(
  /// The string the API uses for this value.
  String value,
) {
  /// One bucket per hour.
  static const StatisticsGroupBy hour = StatisticsGroupBy('hour');

  /// One bucket per day. This is the API default.
  static const StatisticsGroupBy day = StatisticsGroupBy('day');

  /// One bucket per week.
  static const StatisticsGroupBy week = StatisticsGroupBy('week');

  /// One bucket per month.
  static const StatisticsGroupBy month = StatisticsGroupBy('month');

  /// Every value this version of the package knows.
  static const List<StatisticsGroupBy> values = [hour, day, week, month];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// Message counts by delivery status for one time bucket.
final class const DeliverabilityStatistics({
  /// The start of the bucket.
  required final DateTime fromTimestamp,

  /// The end of the bucket.
  required final DateTime toTimestamp,

  /// The number of messages accepted for delivery.
  required final int receptionCount,

  /// The number of messages delivered.
  required final int deliveredCount,

  /// The number of messages deferred.
  required final int deferredCount,

  /// The number of messages bounced.
  required final int bouncedCount,

  /// The number of messages that failed.
  required final int failedCount,

  /// The number of messages suppressed.
  required final int suppressedCount,

  /// The number of messages opened at least once.
  required final int openedCount,

  /// The number of messages with at least one clicked link.
  required final int clickedCount,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates deliverability statistics.
  this;

  /// Decodes deliverability statistics from JSON.
  factory fromJson(JsonMap json) => DeliverabilityStatistics(
    fromTimestamp: decodeDateTime(json['from_timestamp']),
    toTimestamp: decodeDateTime(json['to_timestamp']),
    receptionCount: decodeIntOrNull(json['reception_count']) ?? 0,
    deliveredCount: decodeIntOrNull(json['delivered_count']) ?? 0,
    deferredCount: decodeIntOrNull(json['deferred_count']) ?? 0,
    bouncedCount: decodeIntOrNull(json['bounced_count']) ?? 0,
    failedCount: decodeIntOrNull(json['failed_count']) ?? 0,
    suppressedCount: decodeIntOrNull(json['suppressed_count']) ?? 0,
    openedCount: decodeIntOrNull(json['opened_count']) ?? 0,
    clickedCount: decodeIntOrNull(json['clicked_count']) ?? 0,
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'from_timestamp': encodeDateTime(fromTimestamp),
    'to_timestamp': encodeDateTime(toTimestamp),
    'reception_count': receptionCount,
    'delivered_count': deliveredCount,
    'deferred_count': deferredCount,
    'bounced_count': bouncedCount,
    'failed_count': failedCount,
    'suppressed_count': suppressedCount,
    'opened_count': openedCount,
    'clicked_count': clickedCount,
  };

  @override
  String toString() =>
      'DeliverabilityStatistics(from: $fromTimestamp, '
      'to: $toTimestamp, reception: $receptionCount, '
      'delivered: $deliveredCount, bounced: $bouncedCount)';
}

/// The number of bounces with one classification.
final class const Bounce({
  /// The bounce classification, for example `InvalidRecipient`.
  required final String classification,

  /// The number of bounces.
  required final int count,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a bounce count.
  this;

  /// Decodes a bounce count from JSON.
  factory fromJson(JsonMap json) => Bounce(
    classification: json['classification'] as String? ?? '',
    count: decodeIntOrNull(json['count']) ?? 0,
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {'classification': classification, 'count': count};

  @override
  String toString() => 'Bounce($classification: $count)';
}

/// Bounce counts by classification for one time bucket.
final class const BounceStatistics({
  /// The start of the bucket.
  required final DateTime fromTimestamp,

  /// The end of the bucket.
  required final DateTime toTimestamp,

  /// The bounce count per classification.
  required final List<Bounce> bounces,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates bounce statistics.
  this;

  /// Decodes bounce statistics from JSON.
  factory fromJson(JsonMap json) => BounceStatistics(
    fromTimestamp: decodeDateTime(json['from_timestamp']),
    toTimestamp: decodeDateTime(json['to_timestamp']),
    bounces: decodeList(json['bounces'], Bounce.fromJson),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'from_timestamp': encodeDateTime(fromTimestamp),
    'to_timestamp': encodeDateTime(toTimestamp),
    'bounces': [for (final b in bounces) b.toJson()],
  };

  @override
  String toString() =>
      'BounceStatistics(from: $fromTimestamp, to: $toTimestamp, '
      'bounces: $bounces)';
}

/// The average delivery time to one recipient domain.
final class const DeliveryTime({
  /// The recipient domain.
  required final String recipientDomain,

  /// The average time from reception to delivery, in seconds.
  required final double deliveryTime,

  /// The number of delivered messages in the average.
  required final int count,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a delivery time entry.
  this;

  /// Decodes a delivery time entry from JSON.
  factory fromJson(JsonMap json) => DeliveryTime(
    recipientDomain: json['recipient_domain'] as String? ?? '',
    deliveryTime: decodeDoubleOrNull(json['delivery_time']) ?? 0,
    count: decodeIntOrNull(json['count']) ?? 0,
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'recipient_domain': recipientDomain,
    'delivery_time': deliveryTime,
    'count': count,
  };

  @override
  String toString() =>
      'DeliveryTime($recipientDomain: ${deliveryTime}s, count: $count)';
}

/// Delivery times for one time bucket.
final class const DeliveryTimeStatistics({
  /// The start of the bucket.
  required final DateTime fromTimestamp,

  /// The end of the bucket.
  required final DateTime toTimestamp,

  /// The average delivery time, in seconds.
  required final double avgDeliveryTime,

  /// The number of delivered messages.
  required final int deliveredCount,

  /// The delivery times per recipient domain.
  required final List<DeliveryTime> deliveryTimes,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates delivery time statistics.
  this;

  /// Decodes delivery time statistics from JSON.
  factory fromJson(JsonMap json) => DeliveryTimeStatistics(
    fromTimestamp: decodeDateTime(json['from_timestamp']),
    toTimestamp: decodeDateTime(json['to_timestamp']),
    avgDeliveryTime: decodeDoubleOrNull(json['avg_delivery_time']) ?? 0,
    deliveredCount: decodeIntOrNull(json['delivered_count']) ?? 0,
    deliveryTimes: decodeList(json['delivery_times'], DeliveryTime.fromJson),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'from_timestamp': encodeDateTime(fromTimestamp),
    'to_timestamp': encodeDateTime(toTimestamp),
    'avg_delivery_time': avgDeliveryTime,
    'delivered_count': deliveredCount,
    'delivery_times': [for (final d in deliveryTimes) d.toJson()],
  };

  @override
  String toString() =>
      'DeliveryTimeStatistics(from: $fromTimestamp, to: $toTimestamp, '
      'avg: ${avgDeliveryTime}s, delivered: $deliveredCount)';
}

/// How email statistics are broken down.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const EmailStatisticsBreakdown(
  /// The string the API uses for this value.
  String value,
) {
  /// One row per domain and period, paged by domain.
  static const EmailStatisticsBreakdown domain = EmailStatisticsBreakdown(
    'domain',
  );

  /// Every value this version of the package knows.
  static const List<EmailStatisticsBreakdown> values = [domain];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// Email counts: the totals of an email statistics request.
///
/// Every counter is at least 0. [deferredCount], [openedCount] and
/// [clickedCount] count events, so one message can add more than one. The
/// other counters count a message at most once.
///
/// [EmailStatistics], one row of the response, has the same counters.
final class const EmailStatisticsTotals({
  /// The number of messages accepted, inbound mail included.
  required final int receptionCount,

  /// The number of messages delivered.
  required final int deliveredCount,

  /// The number of messages bounced.
  required final int bouncedCount,

  /// The number of messages not sent because the recipient was suppressed.
  required final int suppressedCount,

  /// The number of spam complaints.
  required final int complainedCount,

  /// The number of temporary delivery failures. Counts events, not
  /// messages.
  required final int deferredCount,

  /// The number of opens. Counts events, not messages. AhaSend makes a
  /// reasonable effort to filter out bots and scanners.
  required final int openedCount,

  /// The number of clicks. Counts events, not messages. AhaSend makes a
  /// reasonable effort to filter out bots and scanners.
  required final int clickedCount,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates email statistics totals.
  this;

  /// Decodes email statistics totals from JSON.
  factory fromJson(JsonMap json) => EmailStatisticsTotals(
    receptionCount: decodeIntOrNull(json['reception_count']) ?? 0,
    deliveredCount: decodeIntOrNull(json['delivered_count']) ?? 0,
    bouncedCount: decodeIntOrNull(json['bounced_count']) ?? 0,
    suppressedCount: decodeIntOrNull(json['suppressed_count']) ?? 0,
    complainedCount: decodeIntOrNull(json['complained_count']) ?? 0,
    deferredCount: decodeIntOrNull(json['deferred_count']) ?? 0,
    openedCount: decodeIntOrNull(json['opened_count']) ?? 0,
    clickedCount: decodeIntOrNull(json['clicked_count']) ?? 0,
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'reception_count': receptionCount,
    'delivered_count': deliveredCount,
    'bounced_count': bouncedCount,
    'suppressed_count': suppressedCount,
    'complained_count': complainedCount,
    'deferred_count': deferredCount,
    'opened_count': openedCount,
    'clicked_count': clickedCount,
  };

  @override
  String toString() =>
      'EmailStatisticsTotals(reception: $receptionCount, '
      'delivered: $deliveredCount, bounced: $bouncedCount)';
}

/// Email counts for one period, and for one domain in a breakdown.
final class const EmailStatistics({
  /// The start of the period.
  required final DateTime fromTimestamp,

  /// The end of the period, which is the start of the next one.
  required final DateTime toTimestamp,

  /// The domain of this row in a breakdown by domain, otherwise `null`.
  final String? senderDomain,
  required super.receptionCount,
  required super.deliveredCount,
  required super.bouncedCount,
  required super.suppressedCount,
  required super.complainedCount,
  required super.deferredCount,
  required super.openedCount,
  required super.clickedCount,
  super.raw,
}) extends EmailStatisticsTotals {
  /// Creates a row of email statistics.
  this;

  /// Decodes a row of email statistics from JSON.
  factory fromJson(JsonMap json) => EmailStatistics(
    fromTimestamp: decodeDateTime(json['from_timestamp']),
    toTimestamp: decodeDateTime(json['to_timestamp']),
    senderDomain: json['sender_domain'] as String?,
    receptionCount: decodeIntOrNull(json['reception_count']) ?? 0,
    deliveredCount: decodeIntOrNull(json['delivered_count']) ?? 0,
    bouncedCount: decodeIntOrNull(json['bounced_count']) ?? 0,
    suppressedCount: decodeIntOrNull(json['suppressed_count']) ?? 0,
    complainedCount: decodeIntOrNull(json['complained_count']) ?? 0,
    deferredCount: decodeIntOrNull(json['deferred_count']) ?? 0,
    openedCount: decodeIntOrNull(json['opened_count']) ?? 0,
    clickedCount: decodeIntOrNull(json['clicked_count']) ?? 0,
    raw: json,
  );

  /// Encodes this object as JSON.
  @override
  JsonMap toJson() => {
    'from_timestamp': encodeDateTime(fromTimestamp),
    'to_timestamp': encodeDateTime(toTimestamp),
    'sender_domain': senderDomain,
    ...super.toJson(),
  };

  @override
  String toString() =>
      'EmailStatistics(from: $fromTimestamp, to: $toTimestamp, '
      '${senderDomain == null ? '' : 'domain: $senderDomain, '}'
      'reception: $receptionCount, delivered: $deliveredCount, '
      'bounced: $bouncedCount)';
}

/// The response of `statistics.emails`.
///
/// Without a breakdown, [data] has one row per period of the range, in time
/// order. With [EmailStatisticsBreakdown.domain], it has the rows of up to
/// `limit` domains, ordered by domain name and then by time; fetch the
/// next domains with [nextPage]. [totals] covers the whole request on
/// every page.
final class EmailStatisticsResponse({
  /// The start of the range after rounding, included.
  required final DateTime fromTime,

  /// The end of the range after rounding, excluded.
  required final DateTime toTime,

  /// The length of each period.
  required final StatisticsGroupBy groupBy,

  /// The breakdown, or `null` when the rows cover every selected domain.
  final EmailStatisticsBreakdown? breakdown,

  /// The counts of the whole request: the whole range and every selected
  /// domain. They are not always the sum of the rows, because AhaSend keeps
  /// the counts of the account and of its domains apart, and because a
  /// counter below 0 is returned as 0.
  required final EmailStatisticsTotals totals,

  /// The rows on this page.
  required final List<EmailStatistics> data,

  /// The cursor for the next page of a breakdown.
  required final PaginationInfo pagination,

  final Future<EmailStatisticsResponse> Function(String cursor)? _fetchAfter,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates an email statistics response. Used by the resource classes.
  @internal
  this;

  /// Decodes an email statistics response. Used by the resource classes.
  @internal
  factory fromJson(
    JsonMap json, {
    Future<EmailStatisticsResponse> Function(String cursor)? fetchAfter,
  }) => EmailStatisticsResponse(
    fromTime: decodeDateTime(json['from_time']),
    toTime: decodeDateTime(json['to_time']),
    groupBy: decodeEnum(json['group_by'], StatisticsGroupBy.new),
    breakdown: decodeEnumOrNull(
      json['breakdown'],
      EmailStatisticsBreakdown.new,
    ),
    totals: EmailStatisticsTotals.fromJson(asJsonMap(json['totals'] ?? {})),
    data: decodeList(json['data'], EmailStatistics.fromJson),
    pagination: switch (json['pagination']) {
      null => const PaginationInfo(hasMore: false),
      final pagination => PaginationInfo.fromJson(asJsonMap(pagination)),
    },
    fetchAfter: fetchAfter,
    raw: json,
  );

  /// Whether another page of domains follows this one.
  bool get hasMore => pagination.hasMore && pagination.nextCursor != null;

  /// Fetches the next page of domains, or returns `null` when this is the
  /// last page.
  Future<EmailStatisticsResponse?> nextPage() async {
    final cursor = pagination.nextCursor;
    final fetch = _fetchAfter;
    if (!hasMore || cursor == null || fetch == null) return null;
    return await fetch(cursor);
  }

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'email_statistics',
    'from_time': encodeDateTime(fromTime),
    'to_time': encodeDateTime(toTime),
    'group_by': groupBy.value,
    'breakdown': breakdown?.value,
    'totals': totals.toJson(),
    'data': [for (final row in data) row.toJson()],
    'pagination': pagination.toJson(),
  };

  @override
  String toString() =>
      'EmailStatisticsResponse(from: $fromTime, to: $toTime, '
      'groupBy: ${groupBy.value}, ${data.length} rows, hasMore: $hasMore)';
}
