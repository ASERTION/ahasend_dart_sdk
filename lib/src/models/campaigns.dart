import 'dart:convert';

import '../errors.dart';
import '../json.dart';
import 'common.dart';
import 'templates.dart';

/// Where a campaign is in its life. Only a [draft] can be changed or
/// deleted.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const CampaignStatus(
  /// The string the API uses for this value.
  String value,
) {
  /// Being prepared.
  static const CampaignStatus draft = CampaignStatus('draft');

  /// Scheduled, and its lists are being checked.
  static const CampaignStatus validating = CampaignStatus('validating');

  /// Held for a review before it sends.
  static const CampaignStatus waitingForReview = CampaignStatus(
    'waiting_for_review',
  );

  /// Accepted, waiting for its send time.
  static const CampaignStatus scheduled = CampaignStatus('scheduled');

  /// Sending now.
  static const CampaignStatus sending = CampaignStatus('sending');

  /// Sending stopped for now; `statusReason` says why.
  static const CampaignStatus paused = CampaignStatus('paused');

  /// Every message was sent.
  static const CampaignStatus sent = CampaignStatus('sent');

  /// Stopped before it finished; `statusReason` says why.
  static const CampaignStatus canceled = CampaignStatus('canceled');

  /// Could not be sent; `statusReason` says why.
  static const CampaignStatus failed = CampaignStatus('failed');

  /// Every value this version of the package knows.
  static const List<CampaignStatus> values = [
    draft,
    validating,
    waitingForReview,
    scheduled,
    sending,
    paused,
    sent,
    canceled,
    failed,
  ];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// Why a campaign cannot be sent yet.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const CampaignIssueCode(
  /// The string the API uses for this value.
  String value,
) {
  /// The campaign has no complete sender, or its domain was deleted.
  static const CampaignIssueCode senderMissing = CampaignIssueCode(
    'sender_missing',
  );

  /// The campaign has no list that still exists.
  static const CampaignIssueCode listsMissing = CampaignIssueCode(
    'lists_missing',
  );

  /// The campaign has no subject.
  static const CampaignIssueCode subjectMissing = CampaignIssueCode(
    'subject_missing',
  );

  /// The campaign has no preview text.
  static const CampaignIssueCode preheaderMissing = CampaignIssueCode(
    'preheader_missing',
  );

  /// The campaign has no design, or its design has no HTML.
  static const CampaignIssueCode designMissing = CampaignIssueCode(
    'design_missing',
  );

  /// The subject, preview text or design holds template syntax that cannot
  /// be rendered.
  static const CampaignIssueCode textBroken = CampaignIssueCode('text_broken');

  /// The subject, preview text and design could not be checked right now;
  /// try again in a moment.
  static const CampaignIssueCode textUnchecked = CampaignIssueCode(
    'text_unchecked',
  );

  /// The HTML does not use `{{ unsubscribe_url }}`.
  static const CampaignIssueCode unsubscribeLinkMissing = CampaignIssueCode(
    'unsubscribe_link_missing',
  );

  /// Every value this version of the package knows.
  static const List<CampaignIssueCode> values = [
    senderMissing,
    listsMissing,
    subjectMissing,
    preheaderMissing,
    designMissing,
    textBroken,
    textUnchecked,
    unsubscribeLinkMissing,
  ];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// A reason a campaign cannot be sent yet.
final class const CampaignIssue({
  /// The issue code.
  required final CampaignIssueCode code,

  /// What to do, in the words the dashboard uses.
  required final String message,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a campaign issue.
  this;

  /// Decodes a campaign issue from JSON.
  factory fromJson(JsonMap json) => CampaignIssue(
    code: decodeEnum(json['code'], CampaignIssueCode.new),
    message: json['message'] as String? ?? '',
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {'code': code.value, 'message': message};

  @override
  String toString() => 'CampaignIssue(${code.value}: $message)';
}

/// A campaign as `campaigns.list` returns it, without its lists, content
/// and issues.
final class const CampaignListItem({
  /// The campaign ID.
  required final String id,

  /// When the campaign was created.
  required final DateTime createdAt,

  /// When the campaign's own fields last changed.
  required final DateTime updatedAt,

  /// The campaign name, as shown in the dashboard. Recipients do not see
  /// it.
  required final String name,

  /// The campaign status.
  required final CampaignStatus status,

  /// The subject line, or `null` until one is set.
  final String? subject,

  /// The preview text, or `null` until one is set.
  final String? preheader,

  /// The sender, or `null` until a complete sender is set or when its
  /// domain was deleted. `name` is empty when there is no sender name.
  final Address? from,

  /// The reply-to address, or `null` when none is set.
  final String? replyTo,

  /// Why the campaign is in its status, when there is a reason to give.
  final String? statusReason,

  /// When the campaign sends or sent, or `null` until it is scheduled.
  final DateTime? sendAt,

  /// When a send that reached the daily marketing limit continues.
  final DateTime? sendResumesAt,

  /// When the send ended, or `null` until then.
  final DateTime? finishedAt,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a campaign list item.
  this;

  /// Decodes a campaign list item from JSON.
  factory fromJson(JsonMap json) => CampaignListItem(
    id: json['id'] as String,
    createdAt: decodeDateTime(json['created_at']),
    updatedAt: decodeDateTime(json['updated_at']),
    name: json['name'] as String,
    subject: json['subject'] as String?,
    preheader: json['preheader'] as String?,
    from: switch (json['from']) {
      null => null,
      final from => Address.fromJson(asJsonMap(from)),
    },
    replyTo: json['reply_to'] as String?,
    status: decodeEnum(json['status'], CampaignStatus.new),
    statusReason: json['status_reason'] as String?,
    sendAt: decodeDateTimeOrNull(json['send_at']),
    sendResumesAt: decodeDateTimeOrNull(json['send_resumes_at']),
    finishedAt: decodeDateTimeOrNull(json['finished_at']),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'campaign',
    'id': id,
    'created_at': encodeDateTime(createdAt),
    'updated_at': encodeDateTime(updatedAt),
    'name': name,
    'subject': subject,
    'preheader': preheader,
    'from': from?.toJson(),
    'reply_to': replyTo,
    'status': status.value,
    'status_reason': statusReason,
    'send_at': encodeDateTimeOrNull(sendAt),
    'send_resumes_at': encodeDateTimeOrNull(sendResumesAt),
    'finished_at': encodeDateTimeOrNull(finishedAt),
  };

  @override
  String toString() {
    final className = switch (this) {
      CampaignSend() => 'CampaignSend',
      Campaign() => 'Campaign',
      _ => 'CampaignListItem',
    };
    return '$className(id: $id, name: $name, status: ${status.value})';
  }
}

/// A campaign with its lists, content and issues.
final class const Campaign({
  required super.id,
  required super.createdAt,
  required super.updatedAt,
  required super.name,
  required super.status,

  /// The lists the campaign sends to, in the order they were saved.
  required final List<String> listIds,
  super.subject,
  super.preheader,
  super.from,
  super.replyTo,
  super.statusReason,
  super.sendAt,
  super.sendResumesAt,
  super.finishedAt,

  /// The editor of the design, or `null` while there is no design.
  final TemplateEditor? editor,

  /// The content of the design, or `null` while there is no design or it
  /// has neither HTML nor text.
  final TemplateContent? content,

  /// Whether the draft has no issue and can be sent. `null` unless the
  /// campaign is a draft.
  final bool? ready,

  /// Why the draft cannot be sent yet; empty when it is ready. `null`
  /// unless the campaign is a draft.
  final List<CampaignIssue>? issues,
  super.raw,
}) extends CampaignListItem {
  /// Creates a campaign.
  this;

  /// Decodes a campaign from JSON.
  factory fromJson(JsonMap json) {
    final c = CampaignListItem.fromJson(json);
    return Campaign(
      id: c.id,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
      name: c.name,
      subject: c.subject,
      preheader: c.preheader,
      from: c.from,
      replyTo: c.replyTo,
      status: c.status,
      statusReason: c.statusReason,
      sendAt: c.sendAt,
      sendResumesAt: c.sendResumesAt,
      finishedAt: c.finishedAt,
      listIds: decodeScalarList<String>(json['list_ids']),
      editor: decodeEnumOrNull(json['editor'], TemplateEditor.new),
      content: switch (json['content']) {
        null => null,
        final content => TemplateContent.fromJson(asJsonMap(content)),
      },
      ready: json['ready'] as bool?,
      issues: decodeListOrNull(json['issues'], CampaignIssue.fromJson),
      raw: json,
    );
  }

  @override
  JsonMap toJson() => {
    ...super.toJson(),
    'list_ids': listIds,
    'editor': editor?.value,
    'content': content?.toJson(),
    'ready': ready,
    'issues': issues?.map((i) => i.toJson()).toList(),
  };
}

/// A request to create a draft campaign.
///
/// The design comes from at most one source: [editor], [content], both, or
/// [templateId].
final class const CreateCampaignRequest({
  /// The campaign name (1 to 255 characters).
  required final String name,

  /// The subject line. It may contain `{{ variables }}`.
  final String? subject,

  /// The preview text.
  final String? preheader,

  /// The sender. Must be on a domain of the account with valid DNS.
  final TemplateAddressInput? from,

  /// The reply-to address, without a display name.
  final String? replyTo,

  /// The lists to send to, in order (1 to 50).
  final List<String>? listIds,

  /// The editor of the design. Not accepted with [templateId].
  final TemplateEditor? editor,

  /// The content of the design. Not accepted with [templateId].
  final TemplateContentInput? content,

  /// A campaign template whose design the campaign copies. Later changes to
  /// the template do not reach the campaign.
  final String? templateId,
}) {
  /// Creates a campaign create request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'name': name,
    'subject': ?subject,
    'preheader': ?preheader,
    'from': ?from?.toJson(),
    'reply_to': ?replyTo,
    'list_ids': ?listIds,
    'editor': ?editor?.value,
    'content': ?content?.toJson(),
    'template_id': ?templateId,
  };
}

/// Changes to a draft campaign. A field left `null` is not changed.
final class const UpdateCampaignRequest({
  /// The campaign name (1 to 255 characters).
  final String? name,

  /// The subject line. `Patch.clear()` clears it.
  final Patch<String>? subject,

  /// The preview text. `Patch.clear()` clears it.
  final Patch<String>? preheader,

  /// The sender. `Patch.clear()` clears it; the reply-to stays.
  final Patch<TemplateAddressInput>? from,

  /// The reply-to address. `Patch.clear()` clears it.
  final Patch<String>? replyTo,

  /// The lists to send to, replacing the campaign's lists (1 to 50).
  final List<String>? listIds,

  /// The content of the design, in the design's editor. For a `simple`
  /// design, send only `text`.
  final TemplateContentInput? content,
}) {
  /// Creates a campaign update request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'name': ?name,
    if (subject case final p?) 'subject': p.value,
    if (preheader case final p?) 'preheader': p.value,
    if (from case final p?) 'from': p.value?.toJson(),
    if (replyTo case final p?) 'reply_to': p.value,
    'list_ids': ?listIds,
    'content': ?content?.toJson(),
  };
}

/// A request to duplicate a campaign.
final class const DuplicateCampaignRequest({
  /// The name of the copy (1 to 255 characters).
  final String? name,
}) {
  /// Creates a duplicate request. Without [name] the copy is named
  /// `Copy of` and the source's name.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {'name': ?name};
}

/// A request to send a campaign.
final class const SendCampaignRequest({
  /// The time to send, at least 1 minute ahead.
  final DateTime? sendAt,
}) {
  /// Creates a send request. Without [sendAt] the campaign is sent now.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {'send_at': ?encodeDateTimeOrNull(sendAt)};
}

/// A campaign as a send left it, with warnings.
final class const CampaignSend({
  required super.id,
  required super.createdAt,
  required super.updatedAt,
  required super.name,
  required super.status,
  required super.listIds,

  /// Things the send accepted but you should know, such as an account that
  /// cannot send right now. Empty when there is none.
  required final List<String> warnings,
  super.subject,
  super.preheader,
  super.from,
  super.replyTo,
  super.statusReason,
  super.sendAt,
  super.sendResumesAt,
  super.finishedAt,
  super.editor,
  super.content,
  super.ready,
  super.issues,
  super.raw,
}) extends Campaign {
  /// Creates a campaign send result.
  this;

  /// Decodes a campaign send result from JSON.
  factory fromJson(JsonMap json) {
    final c = Campaign.fromJson(json);
    return CampaignSend(
      id: c.id,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
      name: c.name,
      subject: c.subject,
      preheader: c.preheader,
      from: c.from,
      replyTo: c.replyTo,
      status: c.status,
      statusReason: c.statusReason,
      sendAt: c.sendAt,
      sendResumesAt: c.sendResumesAt,
      finishedAt: c.finishedAt,
      listIds: c.listIds,
      editor: c.editor,
      content: c.content,
      ready: c.ready,
      issues: c.issues,
      warnings: decodeScalarList<String>(json['warnings']),
      raw: json,
    );
  }

  @override
  JsonMap toJson() => {...super.toJson(), 'warnings': warnings};
}

/// The body of a refused campaign send or test (HTTP 400).
///
/// A campaign with issues is refused with the message
/// `campaign is not ready to send` and the blocking [issues]; every other
/// refusal has only [message]. Use [CampaignNotReady.fromException] to read
/// it from a [BadRequestException].
final class const CampaignNotReady({
  /// The error message.
  required final String message,

  /// The issues that block the request, or `null` for other refusals.
  final List<CampaignIssue>? issues,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a refusal.
  this;

  /// Decodes a refusal from JSON.
  factory fromJson(JsonMap json) => CampaignNotReady(
    message: json['message'] as String? ?? '',
    issues: decodeListOrNull(json['issues'], CampaignIssue.fromJson),
    raw: json,
  );

  /// Decodes the refusal carried by [error], or returns `null` when [error]
  /// is not a [BadRequestException] with a JSON object body.
  ///
  /// ```dart
  /// try {
  ///   await client.campaigns.send(id);
  /// } on BadRequestException catch (e) {
  ///   final issues = CampaignNotReady.fromException(e)?.issues;
  /// }
  /// ```
  static CampaignNotReady? fromException(Object error) {
    if (error is! BadRequestException) return null;
    final body = error.body;
    if (body == null || body.isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      return CampaignNotReady.fromJson(asJsonMap(decoded));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'message': message,
    'issues': ?issues?.map((i) => i.toJson()).toList(),
  };

  @override
  String toString() => 'CampaignNotReady(message: $message, issues: $issues)';
}

/// A request to send a test of a draft campaign.
final class const TestCampaignRequest({
  /// 1 to 5 addresses. An entry may carry a display name, such as
  /// `Ann <ann@example.com>`.
  required final List<String> to,
}) {
  /// Creates a test request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {'to': to};
}

/// An address the mail server refused during a test send.
final class const CampaignTestFailure({
  /// The address as the mail server reported it.
  required final String email,

  /// Why the address was refused.
  required final String message,
}) {
  /// Creates a test failure.
  this;

  /// Decodes a test failure from JSON.
  factory fromJson(JsonMap json) => CampaignTestFailure(
    email: json['email'] as String,
    message: json['message'] as String? ?? '',
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {'email': email, 'message': message};

  @override
  String toString() => 'CampaignTestFailure($email: $message)';
}

/// What a test send did.
final class const CampaignTest({
  /// The addresses the mail server accepted.
  required final List<String> sentTo,

  /// The addresses the mail server refused.
  required final List<CampaignTestFailure> failed,

  /// Whether the mail server's answer could not be read. The test may have
  /// gone out; check the inboxes before sending another.
  required final bool resultUnknown,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a test result.
  this;

  /// Decodes a test result from JSON.
  factory fromJson(JsonMap json) => CampaignTest(
    sentTo: decodeScalarList<String>(json['sent_to']),
    failed: decodeList(json['failed'], CampaignTestFailure.fromJson),
    resultUnknown: json['result_unknown'] as bool? ?? false,
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'campaign_test',
    'sent_to': sentTo,
    'failed': [for (final f in failed) f.toJson()],
    'result_unknown': resultUnknown,
  };

  @override
  String toString() =>
      'CampaignTest(sentTo: $sentTo, failed: $failed, '
      'resultUnknown: $resultUnknown)';
}

/// A campaign's stored report, recounted from its recipients from time to
/// time.
final class const CampaignStatsReport({
  /// When the report was counted.
  required final DateTime computedAt,

  /// The recipients the report counted.
  required final int recipients,

  /// Contacts who opened, each once, without bots.
  required final int openers,

  /// Contacts who clicked, each once, without bots.
  required final int clickers,

  /// Recipients that bounced or failed.
  required final int bounces,

  /// Recipients whose delivery was deferred.
  required final int deferrals,

  /// Recipients by status, such as `Delivered` or `Bounced`. Each key is a
  /// `status` filter of `campaigns.listRecipients`.
  required final Map<String, int> byStatus,

  /// Bounces by bounce classification. Each key but `Unknown` is a
  /// `bounceClassification` filter of `campaigns.listRecipients`.
  required final Map<String, int> byBounceClassification,
}) {
  /// Creates a report.
  this;

  /// Decodes a report from JSON.
  factory fromJson(JsonMap json) => CampaignStatsReport(
    computedAt: decodeDateTime(json['computed_at']),
    recipients: decodeIntOrNull(json['recipients']) ?? 0,
    openers: decodeIntOrNull(json['openers']) ?? 0,
    clickers: decodeIntOrNull(json['clickers']) ?? 0,
    bounces: decodeIntOrNull(json['bounces']) ?? 0,
    deferrals: decodeIntOrNull(json['deferrals']) ?? 0,
    byStatus: _decodeCounts(json['by_status']),
    byBounceClassification: _decodeCounts(json['by_bounce_classification']),
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'computed_at': encodeDateTime(computedAt),
    'recipients': recipients,
    'openers': openers,
    'clickers': clickers,
    'bounces': bounces,
    'deferrals': deferrals,
    'by_status': byStatus,
    'by_bounce_classification': byBounceClassification,
  };

  static Map<String, int> _decodeCounts(Object? value) => Map.unmodifiableOf({
    for (final MapEntry(:key, :value)
        in (asJsonMapOrNull(value) ?? const {}).entries)
      key: decodeInt(value),
  });
}

/// Campaign rates as percentages from 0 to 100 with two decimals. Each is
/// `null` while the report is `null` or its base is zero.
final class const CampaignStatsRates({
  /// Openers out of delivered messages.
  final double? openRate,

  /// Clickers out of delivered messages.
  final double? clickRate,

  /// Bounces out of the report's recipients.
  final double? bounceRate,

  /// Deferrals out of the report's recipients.
  final double? deferralRate,
}) {
  /// Creates rates.
  this;

  /// Decodes rates from JSON.
  factory fromJson(JsonMap json) => CampaignStatsRates(
    openRate: decodeDoubleOrNull(json['open_rate']),
    clickRate: decodeDoubleOrNull(json['click_rate']),
    bounceRate: decodeDoubleOrNull(json['bounce_rate']),
    deferralRate: decodeDoubleOrNull(json['deferral_rate']),
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'open_rate': openRate,
    'click_rate': clickRate,
    'bounce_rate': bounceRate,
    'deferral_rate': deferralRate,
  };
}

/// The numbers of a campaign.
///
/// The counters are live; [report] is recounted from time to time. A
/// request never counts: when the report is missing or old, it asks for a
/// recount, so read again later for new numbers.
final class const CampaignStats({
  /// The campaign ID.
  required final String campaignId,

  /// Recipients the campaign sends to.
  required final int recipients,

  /// Messages delivered.
  required final int delivered,

  /// Opens, without bots.
  required final int opens,

  /// Clicks, without bots.
  required final int clicks,

  /// Recipients who unsubscribed.
  required final int unsubscribes,

  /// Recipients who marked the message as spam.
  required final int complaints,

  /// The rates.
  required final CampaignStatsRates rates,

  /// Whether the last recount failed, so [report] may be old.
  required final bool recountFailed,

  /// The stored report, or `null` until the first recount.
  final CampaignStatsReport? report,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates campaign stats.
  this;

  /// Decodes campaign stats from JSON.
  factory fromJson(JsonMap json) => CampaignStats(
    campaignId: json['campaign_id'] as String,
    recipients: decodeIntOrNull(json['recipients']) ?? 0,
    delivered: decodeIntOrNull(json['delivered']) ?? 0,
    opens: decodeIntOrNull(json['opens']) ?? 0,
    clicks: decodeIntOrNull(json['clicks']) ?? 0,
    unsubscribes: decodeIntOrNull(json['unsubscribes']) ?? 0,
    complaints: decodeIntOrNull(json['complaints']) ?? 0,
    report: switch (json['report']) {
      null => null,
      final report => CampaignStatsReport.fromJson(asJsonMap(report)),
    },
    rates: CampaignStatsRates.fromJson(
      asJsonMapOrNull(json['rates']) ?? const {},
    ),
    recountFailed: json['recount_failed'] as bool? ?? false,
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'campaign_stats',
    'campaign_id': campaignId,
    'recipients': recipients,
    'delivered': delivered,
    'opens': opens,
    'clicks': clicks,
    'unsubscribes': unsubscribes,
    'complaints': complaints,
    'report': report?.toJson(),
    'rates': rates.toJson(),
    'recount_failed': recountFailed,
  };

  @override
  String toString() =>
      'CampaignStats(campaignId: $campaignId, '
      'recipients: $recipients, delivered: $delivered)';
}

/// A recipient of a campaign.
final class const CampaignRecipient({
  /// The contact ID.
  required final String contactId,

  /// The address the campaign sent to.
  required final String email,

  /// The name of the list the contact was sent to from.
  required final String listName,

  /// The status, as a key of [CampaignStatsReport.byStatus].
  required final String status,

  /// Delivery attempts.
  required final int attempts,

  /// When the recipient was added to the send.
  required final DateTime createdAt,

  /// When the recipient last changed.
  required final DateTime updatedAt,

  /// The bounce classification, or `null` when there is none.
  final String? bounceClassification,

  /// The bounce reason, or `null` when there is none.
  final String? bounceReason,

  /// The receiving server's bounce message, or `null` when there is none.
  final String? bounceMessage,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a campaign recipient.
  this;

  /// Decodes a campaign recipient from JSON.
  factory fromJson(JsonMap json) => CampaignRecipient(
    contactId: json['contact_id'] as String,
    email: json['email'] as String,
    listName: json['list_name'] as String? ?? '',
    status: json['status'] as String,
    bounceClassification: json['bounce_classification'] as String?,
    bounceReason: json['bounce_reason'] as String?,
    bounceMessage: json['bounce_message'] as String?,
    attempts: decodeIntOrNull(json['attempts']) ?? 0,
    createdAt: decodeDateTime(json['created_at']),
    updatedAt: decodeDateTime(json['updated_at']),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'campaign_recipient',
    'contact_id': contactId,
    'email': email,
    'list_name': listName,
    'status': status,
    'bounce_classification': bounceClassification,
    'bounce_reason': bounceReason,
    'bounce_message': bounceMessage,
    'attempts': attempts,
    'created_at': encodeDateTime(createdAt),
    'updated_at': encodeDateTime(updatedAt),
  };

  @override
  String toString() =>
      'CampaignRecipient(contactId: $contactId, email: $email, '
      'status: $status)';
}
