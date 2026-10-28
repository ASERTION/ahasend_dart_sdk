import '../json.dart';

/// The status of a sub-account.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const SubAccountStatus(
  /// The string the API uses for this value.
  String value,
) {
  /// The sub-account can send.
  static const SubAccountStatus active = SubAccountStatus('active');

  /// Sending is paused on the sub-account.
  static const SubAccountStatus suspended = SubAccountStatus('suspended');

  /// Sending is paused because the parent account is suspended.
  static const SubAccountStatus parentSuspended = SubAccountStatus(
    'parent-suspended',
  );

  /// The sub-account was deleted.
  static const SubAccountStatus deleted = SubAccountStatus('deleted');

  /// Every value this version of the package knows.
  static const List<SubAccountStatus> values = [
    active,
    suspended,
    parentSuspended,
    deleted,
  ];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// How the parent's pooled invoice cost is allocated to sub-accounts.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const SubAccountAllocationMethod(
  /// The string the API uses for this value.
  String value,
) {
  /// In proportion to usage.
  static const SubAccountAllocationMethod proportional =
      SubAccountAllocationMethod('proportional');

  /// Every value this version of the package knows.
  static const List<SubAccountAllocationMethod> values = [proportional];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// A sub-account under a parent account.
final class const SubAccount({
  /// The ID of the sub-account. Use it as the account ID with
  /// `AhaSendClient.forAccount` and a sub-account API key.
  required final String id,

  /// The ID of the parent account.
  required final String parentAccountId,

  /// When the sub-account was created.
  required final DateTime createdAt,

  /// The sub-account name.
  required final String name,

  /// The website, as a bare domain such as `acme.com`.
  required final String website,

  /// The current status.
  required final SubAccountStatus status,

  /// The monthly cap; 0 means no cap.
  required final int monthlyCredit,

  /// The number of domains of the sub-account.
  required final int domainCount,

  /// The number of direct members of the sub-account.
  required final int memberCount,

  /// When the sub-account last sent or received email.
  final DateTime? lastActivityAt,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a sub-account.
  this;

  /// Decodes a sub-account from JSON.
  factory fromJson(JsonMap json) => SubAccount(
    id: json['id'] as String,
    parentAccountId: json['parent_account_id'] as String,
    createdAt: decodeDateTime(json['created_at']),
    name: json['name'] as String,
    website: json['website'] as String? ?? '',
    status: decodeEnum(json['status'], SubAccountStatus.new),
    monthlyCredit: decodeIntOrNull(json['monthly_credit']) ?? 0,
    domainCount: decodeIntOrNull(json['domain_count']) ?? 0,
    memberCount: decodeIntOrNull(json['member_count']) ?? 0,
    lastActivityAt: decodeDateTimeOrNull(json['last_activity_at']),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'sub_account',
    'id': id,
    'parent_account_id': parentAccountId,
    'created_at': encodeDateTime(createdAt),
    'name': name,
    'website': website,
    'status': status.value,
    'monthly_credit': monthlyCredit,
    'domain_count': domainCount,
    'member_count': memberCount,
    'last_activity_at': encodeDateTimeOrNull(lastActivityAt),
  };

  @override
  String toString() =>
      'SubAccount(id: $id, name: $name, status: ${status.value})';
}

/// A request to create a sub-account.
final class const CreateSubAccountRequest({
  /// The name, 1 to 255 characters. Surrounding whitespace is trimmed.
  required final String name,

  /// The website, as a domain or an http(s) URL. Only the host is stored.
  required final String website,

  /// The monthly cap, 0 to 1,000,000,000; 0 (the default) means no cap.
  final int? monthlyCredit,
}) {
  /// Creates a request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'name': name,
    'website': website,
    'monthly_credit': ?monthlyCredit,
  };
}

/// A request to update a sub-account.
///
/// Fields left `null` are not changed. Provide at least one field, and at
/// least one value must differ from the current one.
final class const UpdateSubAccountRequest({
  /// The name, 1 to 255 characters. Surrounding whitespace is trimmed.
  final String? name,

  /// The website, as a domain or an http(s) URL. Only the host is stored.
  final String? website,

  /// The monthly cap, 0 to 1,000,000,000; 0 means no cap.
  final int? monthlyCredit,
}) {
  /// Creates a request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'name': ?name,
    'website': ?website,
    'monthly_credit': ?monthlyCredit,
  };
}

/// A request to pause sending on a sub-account.
final class const SuspendSubAccountRequest({
  /// The reason, 1 to 500 characters. It is shown on the sub-account's
  /// dashboard when this call starts the pause.
  required final String reason,
}) {
  /// Creates a request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {'reason': reason};
}

/// Usage and allocated cost of one account, or an aggregate, in a billing
/// period.
final class const SubAccountUsageBreakdown({
  /// The number of received messages in the billing period.
  required final int receptionCount,

  /// The proportional share of the parent's pooled invoice cost.
  required final double allocatedCost,

  /// The account ID. Set for the parent and for sub-accounts; absent for
  /// aggregates.
  final String? accountId,

  /// The sub-account name, for sub-account entries.
  final String? name,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a usage breakdown.
  this;

  /// Decodes a usage breakdown from JSON.
  factory fromJson(JsonMap json) => SubAccountUsageBreakdown(
    accountId: json['account_id'] as String?,
    name: json['name'] as String?,
    receptionCount: decodeIntOrNull(json['reception_count']) ?? 0,
    allocatedCost: decodeDoubleOrNull(json['allocated_cost']) ?? 0,
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'account_id': ?accountId,
    'name': ?name,
    'reception_count': receptionCount,
    'allocated_cost': allocatedCost,
  };

  @override
  String toString() =>
      'SubAccountUsageBreakdown(accountId: $accountId, '
      'receptionCount: $receptionCount, allocatedCost: $allocatedCost)';
}

/// A billing period.
final class const SubAccountBillingPeriod({
  /// The start of the period.
  required final DateTime start,

  /// The end of the period.
  required final DateTime end,
}) {
  /// Creates a billing period.
  this;

  /// Decodes a billing period from JSON.
  factory fromJson(JsonMap json) => SubAccountBillingPeriod(
    start: decodeDateTime(json['start']),
    end: decodeDateTime(json['end']),
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'start': encodeDateTime(start),
    'end': encodeDateTime(end),
  };

  @override
  String toString() => 'SubAccountBillingPeriod($start – $end)';
}

/// Usage and allocated cost of the parent and its sub-accounts in the
/// current billing period.
final class const SubAccountUsageResponse({
  /// The billing period.
  required final SubAccountBillingPeriod billingPeriod,

  /// The currency code of the costs, for example `usd`.
  required final String currency,

  /// How the pooled cost is allocated.
  required final SubAccountAllocationMethod allocationMethod,

  /// A note that the allocated cost is not standalone sub-account pricing.
  required final String allocationNote,

  /// The parent account's own usage.
  required final SubAccountUsageBreakdown parent,

  /// The usage of each active sub-account.
  required final List<SubAccountUsageBreakdown> subAccounts,

  /// The aggregated usage of sub-accounts deleted during the period.
  required final SubAccountUsageBreakdown removedSubAccounts,

  /// The total usage.
  required final SubAccountUsageBreakdown total,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a usage response.
  this;

  /// Decodes a usage response from JSON.
  factory fromJson(JsonMap json) => SubAccountUsageResponse(
    billingPeriod: SubAccountBillingPeriod.fromJson(
      asJsonMap(json['billing_period']),
    ),
    currency: json['currency'] as String,
    allocationMethod: decodeEnum(
      json['allocation_method'],
      SubAccountAllocationMethod.new,
    ),
    allocationNote: json['allocation_note'] as String? ?? '',
    parent: SubAccountUsageBreakdown.fromJson(asJsonMap(json['parent'])),
    subAccounts: decodeList(
      json['sub_accounts'],
      SubAccountUsageBreakdown.fromJson,
    ),
    removedSubAccounts: SubAccountUsageBreakdown.fromJson(
      asJsonMap(json['removed_sub_accounts']),
    ),
    total: SubAccountUsageBreakdown.fromJson(asJsonMap(json['total'])),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'billing_period': billingPeriod.toJson(),
    'currency': currency,
    'allocation_method': allocationMethod.value,
    'allocation_note': allocationNote,
    'parent': parent.toJson(),
    'sub_accounts': [for (final e in subAccounts) e.toJson()],
    'removed_sub_accounts': removedSubAccounts.toJson(),
    'total': total.toJson(),
  };

  @override
  String toString() =>
      'SubAccountUsageResponse(total: $total, '
      'subAccounts: ${subAccounts.length})';
}
