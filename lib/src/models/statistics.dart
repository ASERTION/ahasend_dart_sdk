import '../json.dart';

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
