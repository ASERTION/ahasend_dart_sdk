import '../json.dart';

/// The type of email sent from a domain. It affects deliverability:
/// marketing email from a transactional domain can get the account paused.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const DomainSendingType(
  /// The string the API uses for this value.
  String value,
) {
  /// Transactional email.
  static const DomainSendingType transactional = DomainSendingType(
    'transactional',
  );

  /// Marketing email.
  static const DomainSendingType marketing = DomainSendingType('marketing');

  /// Every value this version of the package knows.
  static const List<DomainSendingType> values = [transactional, marketing];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// Why sending from a domain was paused.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const DomainPauseReason(
  /// The string the API uses for this value.
  String value,
) {
  /// Too many recent emails from the domain bounced.
  static const DomainPauseReason bounceRate = DomainPauseReason('bounce_rate');

  /// Every value this version of the package knows.
  static const List<DomainPauseReason> values = [bounceRate];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// A DNS record needed to verify a domain.
final class const DnsRecord({
  /// The record type, for example `CNAME`, `TXT` or `MX`.
  required final String type,

  /// The record host name.
  required final String host,

  /// The record value.
  required final String content,

  /// Whether the record is required for verification.
  required final bool required,

  /// Whether the record has propagated and was verified.
  required final bool propagated,

  /// A human-readable label for the record.
  final String? label,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a DNS record.
  this;

  /// Decodes a DNS record from JSON.
  factory fromJson(JsonMap json) => DnsRecord(
    type: json['type'] as String,
    label: json['label'] as String?,
    host: json['host'] as String,
    content: json['content'] as String,
    required: json['required'] as bool? ?? false,
    propagated: json['propagated'] as bool? ?? false,
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'type': type,
    'label': ?label,
    'host': host,
    'content': content,
    'required': required,
    'propagated': propagated,
  };

  @override
  String toString() =>
      'DnsRecord($type $host: $content, '
      'propagated: $propagated)';
}

/// A sending domain of an account.
final class const Domain({
  /// The ID of the domain.
  required final String id,

  /// When the domain was created.
  required final DateTime createdAt,

  /// When the domain was last updated.
  required final DateTime updatedAt,

  /// The domain name.
  required final String domain,

  /// The ID of the account the domain belongs to.
  required final String accountId,

  /// The DNS records needed to verify the domain.
  required final List<DnsRecord> dnsRecords,

  /// Whether all required DNS records are configured correctly.
  required final bool dnsValid,

  /// Whether the standby DKIM slot is ready for rotation.
  required final bool rotationReady,

  /// The type of email sent from the domain.
  required final DomainSendingType sendingType,

  /// Whether sending from the domain is paused. A paused domain refuses new
  /// email and cannot be deleted or renamed.
  required final bool paused,

  /// When the DNS records were last checked.
  final DateTime? lastDnsCheckAt,

  /// The custom tracking subdomain; `null` uses the default.
  final String? trackingSubdomain,

  /// The custom return-path subdomain; `null` uses the default.
  final String? returnPathSubdomain,

  /// The custom subscription management subdomain; `null` uses the default.
  final String? subscriptionSubdomain,

  /// The custom media subdomain; `null` uses the default.
  final String? mediaSubdomain,

  /// The custom DKIM rotation interval in days; `null` uses the account
  /// default. Only for managed DNS domains.
  final int? dkimRotationIntervalDays,

  /// The configured per-domain DKIM selector override, if any. This is not
  /// necessarily the selector used for signing.
  final String? dkimSelector,

  /// The recipient address for delivery status notifications.
  final String? dsnRecipient,

  /// When sending was paused; `null` when not paused.
  final DateTime? pausedAt,

  /// Why sending was paused; `null` when not paused.
  final DomainPauseReason? pauseReason,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a domain.
  this;

  /// Decodes a domain from JSON.
  factory fromJson(JsonMap json) => Domain(
    id: json['id'] as String,
    createdAt: decodeDateTime(json['created_at']),
    updatedAt: decodeDateTime(json['updated_at']),
    domain: json['domain'] as String,
    accountId: json['account_id'] as String,
    dnsRecords: decodeList(json['dns_records'], DnsRecord.fromJson),
    lastDnsCheckAt: decodeDateTimeOrNull(json['last_dns_check_at']),
    dnsValid: json['dns_valid'] as bool? ?? false,
    trackingSubdomain: json['tracking_subdomain'] as String?,
    returnPathSubdomain: json['return_path_subdomain'] as String?,
    subscriptionSubdomain: json['subscription_subdomain'] as String?,
    mediaSubdomain: json['media_subdomain'] as String?,
    dkimRotationIntervalDays: decodeIntOrNull(
      json['dkim_rotation_interval_days'],
    ),
    dkimSelector: json['dkim_selector'] as String?,
    rotationReady: json['rotation_ready'] as bool? ?? false,
    dsnRecipient: json['dsn_recipient'] as String?,
    sendingType: decodeEnum(json['sending_type'], DomainSendingType.new),
    paused: json['paused'] as bool? ?? false,
    pausedAt: decodeDateTimeOrNull(json['paused_at']),
    pauseReason: decodeEnumOrNull(json['pause_reason'], DomainPauseReason.new),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'domain',
    'id': id,
    'created_at': encodeDateTime(createdAt),
    'updated_at': encodeDateTime(updatedAt),
    'domain': domain,
    'account_id': accountId,
    'dns_records': [for (final e in dnsRecords) e.toJson()],
    'last_dns_check_at': encodeDateTimeOrNull(lastDnsCheckAt),
    'dns_valid': dnsValid,
    'tracking_subdomain': trackingSubdomain,
    'return_path_subdomain': returnPathSubdomain,
    'subscription_subdomain': subscriptionSubdomain,
    'media_subdomain': mediaSubdomain,
    'dkim_rotation_interval_days': dkimRotationIntervalDays,
    'dkim_selector': dkimSelector,
    'rotation_ready': rotationReady,
    'dsn_recipient': dsnRecipient,
    'sending_type': sendingType.value,
    'paused': paused,
    'paused_at': encodeDateTimeOrNull(pausedAt),
    'pause_reason': pauseReason?.value,
  };

  @override
  String toString() =>
      'Domain(id: $id, domain: $domain, dnsValid: $dnsValid, '
      'sendingType: ${sendingType.value}, paused: $paused)';
}

/// A request to add a domain.
final class const CreateDomainRequest({
  /// The fully qualified domain name.
  required final String domain,

  /// An RSA DKIM private key of at least 1024 bits (2048 recommended).
  /// Only for Platform Partner accounts.
  final String? dkimPrivateKey,

  /// A custom tracking subdomain. Omit to use the default.
  final String? trackingSubdomain,

  /// A custom return-path subdomain. Omit to use the default.
  final String? returnPathSubdomain,

  /// A custom subscription management subdomain. Omit to use the default.
  final String? subscriptionSubdomain,

  /// A custom media subdomain. Omit to use the default.
  final String? mediaSubdomain,

  /// A custom DKIM rotation interval in days. Only for managed DNS domains
  /// on eligible plans.
  final int? dkimRotationIntervalDays,

  /// A custom DKIM selector: a single lowercase DNS label of 1 to 62
  /// characters. Omit or pass an empty string for the default selector.
  /// Only for Platform Partner accounts.
  final String? dkimSelector,

  /// The type of email sent from the domain. Defaults to transactional.
  final DomainSendingType? sendingType,
}) {
  /// Creates a request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'domain': domain,
    'dkim_private_key': ?dkimPrivateKey,
    'tracking_subdomain': ?trackingSubdomain,
    'return_path_subdomain': ?returnPathSubdomain,
    'subscription_subdomain': ?subscriptionSubdomain,
    'media_subdomain': ?mediaSubdomain,
    'dkim_rotation_interval_days': ?dkimRotationIntervalDays,
    'dkim_selector': ?dkimSelector,
    'sending_type': ?sendingType?.value,
  };
}

/// A request to update a domain's settings. Fields left `null` are not
/// changed.
final class const UpdateDomainRequest({
  /// A custom tracking subdomain.
  final String? trackingSubdomain,

  /// A custom return-path subdomain.
  final String? returnPathSubdomain,

  /// A custom subscription management subdomain.
  final String? subscriptionSubdomain,

  /// A custom media subdomain.
  final String? mediaSubdomain,

  /// A custom DKIM rotation interval in days. Only for managed DNS domains
  /// on eligible plans.
  final int? dkimRotationIntervalDays,

  /// A custom DKIM selector. Pass an empty string to clear the override and
  /// use the default selector. It cannot change once locked after DNS
  /// verification or during a key rotation. Only for Platform Partner
  /// accounts.
  final String? dkimSelector,

  /// The type of email sent from the domain. Applies to new messages within
  /// five minutes.
  final DomainSendingType? sendingType,
}) {
  /// Creates a request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'tracking_subdomain': ?trackingSubdomain,
    'return_path_subdomain': ?returnPathSubdomain,
    'subscription_subdomain': ?subscriptionSubdomain,
    'media_subdomain': ?mediaSubdomain,
    'dkim_rotation_interval_days': ?dkimRotationIntervalDays,
    'dkim_selector': ?dkimSelector,
    'sending_type': ?sendingType?.value,
  };
}
