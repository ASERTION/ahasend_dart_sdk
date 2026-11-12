## Unreleased

AhaSend changed the templates API in October 2026 and added email
statistics in November 2026. See the
[AhaSend changelog](https://ahasend.com/docs/changelog).

### Changes

- New `templates.getPublished`: the published copy of a template, the one
  sends use. Read the variables a send has to supply from it.
- `templates.get` returns the working copy: the draft while the template
  has one, and the published copy otherwise. Before, the API returned the
  published copy. `Template.hasDraft` says which copy you got. The
  documentation of `Template` and of the template methods describes the
  copy each one returns.
- `templates.getDraft` and `TemplateDraft` are deprecated. The API removed
  `GET /templates/{template_id}/draft`, so `getDraft` of 1.0.0 no longer
  works. It now reads the template with `templates.get` and returns its
  draft, and throws a `NotFoundException` when there is none, as before.
  Use `templates.get` instead.
- New `statistics.emails`: stored email counts of transactional, campaign
  and inbound mail for the account or per domain, in hourly, daily, weekly
  or monthly periods, for any time in the account's history. It returns an
  `EmailStatisticsResponse` with `totals`, one `EmailStatistics` row per
  period (and domain, with `breakdown: EmailStatisticsBreakdown.domain`)
  and `nextPage()` for breakdowns. See
  [Get Email Statistics](https://ahasend.com/docs/api-reference/reports/get-email-statistics).
- The documentation of `StatisticsResource` names the new statistics
  scopes, `statistics:read:all` and `statistics:read:{domain}`. The API
  still accepts the old `statistics-transactional:read:*` names, but
  refuses an API key that lists the same access under both names.
- `tool/spec/openapi.yaml` is updated to the current AhaSend API.

## 1.0.0

AhaSend changes message IDs in the API and in webhooks on
**9 November 2026**. This release follows those changes. See
[Important: two changes to message IDs in the AhaSend API and webhooks](https://ahasend.com/blog/important-two-changes-message-ids-ahasend-api-and-webhooks).

### Breaking changes

These come from the API, not from the package's Dart API: code built
against 0.1.0 still compiles, but values change from 9 November 2026.

- `CreateSingleMessageResponse.id` (from `messages.create`,
  `messages.createFromTemplate` and `messages.createConversation`) is a
  bare UUID instead of the Message-ID header (`<…@…>`). If you compare it
  with `MessageEventData.messageIdHeader` of webhook events, or pass it as
  the `messageIdHeader` filter of `messages.list`, use the new
  `CreateSingleMessageResponse.messageIdHeader` instead, or
  `messageIdHeader ?? id` to also cover responses from before the change.
  `messages.get` and `messages.cancel` accept both forms, so stored IDs
  keep working.
- `MessageEventData.id` and `MessageClickedEventData.id` in message
  webhook events are the API message ID (a hyphenated UUID of 36
  characters, the same value as `CreateSingleMessageResponse.id`) instead
  of the internal AhaSend ID (32 hex characters). A message sent before
  9 November 2026 can receive events with both IDs for up to 30 days:
  group events by `messageIdHeader`, which does not change. If you
  validate the format of `id`, accept the new one. The old and the new ID
  are different values, not the same UUID in two spellings. Campaign
  messages send the same events with the same ID format, but
  `messages.get` cannot fetch campaign messages by it.

### Changes

- New `CreateSingleMessageResponse.messageIdHeader`: the Message-ID header
  of the sent email exactly as sent, including the angle brackets. The
  `messageIdHeader` filter of `messages.list` is an exact match on it. It
  is `null` when the message was not sent, in responses from before
  9 November 2026, and in idempotent replays of such requests (for up to
  24 hours).
- Documentation of `CreateSingleMessageResponse.id`,
  `MessageEventData.id`, `MessageEventData.messageIdHeader`, the click
  event data, `messages.get`, `messages.cancel` and the `messageIdHeader`
  filter of `messages.list` describes the new IDs, the forms each
  accepts, and which one to use for matching sends with webhook events.
- Bundled OpenAPI and webhook specs updated for the new fields and ID
  formats.

## 0.1.0

- Initial release.
- Client for the complete AhaSend API v2 (101 operations): messages,
  templates, campaigns, campaign templates, contacts, lists, suppressions,
  domains, webhooks, routes, SMTP credentials, API keys, accounts,
  sub-accounts and statistics.
- Automatic retries with exponential backoff and `Retry-After` support.
- Automatic idempotency keys for operations that support them.
- Cursor pagination with `CursorPage` and `listAll` streams.
- Typed exception hierarchy.
- Forward compatible: enums are extension types that keep values the API
  adds later, and new webhook event types arrive as `UnknownWebhookEvent`,
  so neither breaks existing code.
- `client.forAccount(id, apiKey: ...)` to work inside sub-accounts over the
  same connection.
- `AhaSendClient` and its resources are interface classes, so they can be
  faked or mocked in tests.
- `package:ahasend/webhooks.dart`: webhook and route signature verification
  and typed event models. Verification failures
  (`WebhookVerificationException`) are kept apart from authentic payloads
  that cannot be decoded (`InvalidPayloadException`).
