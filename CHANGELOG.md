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
