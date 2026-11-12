# ahasend

A pure Dart client for the [AhaSend](https://ahasend.com) API v2.

> [!WARNING]
> **Never put an AhaSend API key into a frontend.** A key in a Flutter app,
> a web bundle or any other code that runs on your users' devices can be
> extracted by anyone, who can then send email from your domains and read
> your data. Use this package on your **server** (backend, Cloud Function,
> CLI, job) and let your apps call your server instead. Load the key from
> an environment variable or a secret manager, never commit it.

- Covers the whole v2 API: messages, domains, templates, campaigns, contacts,
  lists, suppressions, webhooks, routes, SMTP credentials, API keys,
  accounts, sub-accounts and statistics.
- Verifies webhook and route deliveries (Standard Webhooks, HMAC-SHA256).
- Retries rate limits, server errors and network failures, with automatic
  idempotency keys so a retry never sends a message twice.
- Typed models, cursor pagination and a sealed exception hierarchy.
- No `dart:io`: runs anywhere Dart runs, including serverless and edge
  runtimes.
- Easy to test: inject an `http.Client`, or fake `AhaSendClient` in your
  own tests.

## Contents

- [Installation](#installation)
- [Quick start](#quick-start)
- [Creating and sharing the client](#creating-and-sharing-the-client)
  - [Using with Serverpod](#using-with-serverpod)
- Guides
  - [Sending email](#sending-email)
  - [Checking what happened to a message](#checking-what-happened-to-a-message)
  - [Domains and DNS](#domains-and-dns)
  - [Sub-accounts](#sub-accounts)
  - [API keys and scopes](#api-keys-and-scopes)
  - [Templates](#templates)
  - [Contacts and lists](#contacts-and-lists)
  - [Campaigns](#campaigns)
  - [Suppressions](#suppressions)
  - [Webhooks](#webhooks)
  - [Inbound email (routes)](#inbound-email-routes)
  - [Statistics](#statistics)
  - [SMTP credentials](#smtp-credentials)
  - [Account and members](#account-and-members)
- Reference
  - [Resources](#resources)
  - [Pagination](#pagination)
  - [Errors](#errors)
  - [Retries and idempotency](#retries-and-idempotency)
  - [Updating fields](#updating-fields)
  - [Enums](#enums)
  - [Testing your code](#testing-your-code)
  - [Flutter, the web and other runtimes](#flutter-the-web-and-other-runtimes)

## Installation

```sh
dart pub add ahasend
```

Requires Dart 3.13 or later.

## Quick start

Create an API key in the AhaSend dashboard under **Credentials** and copy
your account ID. The `from` address must be on a domain you have added and
verified (see [Domains and DNS](#domains-and-dns)).

```dart
import 'dart:io';

import 'package:ahasend/ahasend.dart';

Future<void> main() async {
  final client = AhaSendClient(
    apiKey: Platform.environment['AHASEND_API_KEY']!,
    accountId: Platform.environment['AHASEND_ACCOUNT_ID'],
  );

  final response = await client.messages.create(
    const CreateMessageRequest(
      from: Address(email: 'hello@example.com', name: 'Example'),
      recipients: [
        Recipient(email: 'ada@example.org', substitutions: {'name': 'Ada'}),
      ],
      subject: 'Welcome, {{ name }}!',
      htmlContent: '<p>Hello {{ name }}!</p>',
    ),
  );

  for (final message in response.data) {
    print('${message.recipient.email}: ${message.status.value}');
  }

  client.close(); // Once, when the program is done. See below.
}
```

## Creating and sharing the client

Create **one** `AhaSendClient` when your server starts and reuse it for
every request. Do not create a client per message, and do not call `close()`
after each message: the client keeps HTTP connections open and reuses them,
which saves a TLS handshake on every call. Call `close()` once, when the
process shuts down. (This follows the advice of `package:http`: reuse a
`Client`, and close it when you are done.)

The client holds no per-request state, so one instance can serve
concurrent requests. `client.forAccount(id, apiKey: ...)` returns a
lightweight view on the same connection for another account, such as a
[sub-account](#sub-accounts).

The package deliberately has no built-in global instance. How you share the
client is up to your app, as with any other dependency:

**Pass it in (simplest, and the easiest to test).** Hand the client to the
classes that need it:

```dart
class WelcomeMailer(final AhaSendClient _ahasend) {
  Future<void> send(String email) => _ahasend.messages.create(
    CreateMessageRequest(
      from: const Address(email: 'hello@example.com'),
      recipients: [Recipient(email: email)],
      subject: 'Welcome!',
      textContent: 'Thanks for signing up.',
    ),
  );
}
```

**Register it in your DI container or framework**, for example with
[get_it](https://pub.dev/packages/get_it):

```dart
// At startup:
GetIt.I.registerSingleton<AhaSendClient>(
  AhaSendClient(apiKey: apiKey, accountId: accountId),
  dispose: (client) => client.close(),
);

// Anywhere on the server:
await GetIt.I<AhaSendClient>().messages.create(request);
```

Dart Frog providers, Shelf middleware and Riverpod on the server work the
same way: create the client once, provide it, close it on shutdown. For
Serverpod, see [Using with Serverpod](#using-with-serverpod).

**A top-level variable** is fine for small scripts and single-file
servers:

```dart
final ahasend = AhaSendClient(apiKey: apiKey, accountId: accountId);
```

### Using with Serverpod

Serverpod creates endpoints itself, so there is no constructor to inject
the client into. Create it lazily in one place and read the key from
Serverpod's password store.

Add the key and account ID to `config/passwords.yaml`, which Serverpod
projects keep out of Git:

```yaml
shared:
  ahasendApiKey: 'aha-sk-...'
  ahasendAccountId: 'your-account-id'
```

In production, set them as environment variables instead, for example
`SERVERPOD_PASSWORD_ahasendApiKey`. On Serverpod Cloud, use
`scloud password set`.

Then expose the client from a small file:

```dart
// lib/src/services/ahasend.dart
import 'package:ahasend/ahasend.dart';
import 'package:meta/meta.dart';
import 'package:serverpod/serverpod.dart';

AhaSendClient? _ahasend;

/// The shared AhaSend client, created on first use.
AhaSendClient get ahasend => _ahasend ??= AhaSendClient(
  apiKey: Serverpod.instance.getPassword('ahasendApiKey')!,
  accountId: Serverpod.instance.getPassword('ahasendAccountId'),
);

/// Replaces the client in tests.
@visibleForTesting
set ahasend(AhaSendClient client) => _ahasend = client;
```

- The client is created on first use, after Serverpod has loaded its
  configuration, so the order of initialization does not matter.
- Every endpoint shares one client and its connections.
- Tests can swap in a fake: `ahasend = FakeAhaSend();`.

Keep endpoints thin and put the logic in a class that takes the client, so
you can unit-test it without Serverpod:

```dart
class MailService(final AhaSendClient _ahasend) {
  Future<void> sendWelcome(String email) => _ahasend.messages.create(
    CreateMessageRequest(
      from: const Address(email: 'hello@example.com'),
      recipients: [Recipient(email: email)],
      subject: 'Welcome!',
      textContent: 'Thanks for signing up.',
    ),
  );
}

class AccountEndpoint extends Endpoint {
  Future<void> register(Session session, String email) async {
    // ... create the user ...
    await MailService(ahasend).sendWelcome(email);
  }
}
```

Serverpod has no shutdown hook for your own services, and
`pod.shutdown()` ends the process by default, which closes the
connections. You don't need to call `close()` here.

To receive AhaSend webhooks in Serverpod, store the webhook secret as a
password in the same way and create the `WebhookVerifier` with a lazy
getter (see [Webhooks](#webhooks)).

## Sending email

There are three ways to send:

| Method | Use it for |
| --- | --- |
| `messages.create` | One message **per recipient** (up to 100 per call), with your own content. Each recipient only sees their own address. |
| `messages.createFromTemplate` | The same, with the content of a stored [template](#templates). |
| `messages.createConversation` | **One** message with several addresses in To, CC and BCC (up to 50 in total), like a normal email client. |

Every call returns one result per recipient. A recipient can fail while the
others succeed, so check each status:

```dart
final response = await client.messages.create(request);
for (final result in response.data) {
  switch (result.status) {
    case .queued || .scheduled:
      print('Accepted ${result.recipient.email}: ${result.id}');
    default:
      print('Not sent to ${result.recipient.email}: ${result.error}');
  }
}
```

Keep the returned `id`: it identifies the message when you
[look it up](#checking-what-happened-to-a-message) or cancel it, and
webhook events of messages sent since 9 November 2026 carry it as
`data.id`. To match a send with its
[webhook events](#webhooks), or to filter the message list, use
`result.messageIdHeader` instead: the Message-ID header of the email
(`<…@…>`), which never changes for a message. Responses from before
9 November 2026, and idempotent replays of such requests, have no
`messageIdHeader` but hold the header in `id`, so this works in every case:

```dart
final messageIdHeader = result.messageIdHeader ?? result.id;
```

> Since 9 November 2026, `id` is a bare UUID and the Message-ID header has
> moved to `messageIdHeader`. Before, `id` held the Message-ID header. Both
> forms keep working with `messages.get` and `messages.cancel`. See
> [AhaSend's announcement](https://ahasend.com/blog/important-two-changes-message-ids-ahasend-api-and-webhooks).

### Personalizing with substitutions

Subjects, bodies and headers can use `{{ variables }}`. Values come from
the request's `substitutions` and from each recipient's `substitutions`,
which win. In HTML, values are escaped; write `{{ name|safe }}` to insert
HTML.

```dart
await client.messages.create(
  const CreateMessageRequest(
    from: Address(email: 'orders@example.com', name: 'Example Shop'),
    recipients: [
      Recipient(
        email: 'ada@example.org',
        name: 'Ada',
        substitutions: {'name': 'Ada', 'order': '1042'},
      ),
      Recipient(
        email: 'grace@example.org',
        name: 'Grace',
        substitutions: {'name': 'Grace', 'order': '1043'},
      ),
    ],
    subject: 'Order {{ order }} has shipped',
    htmlContent: '<p>Hi {{ name }}, order {{ order }} is on its way.</p>',
    textContent: 'Hi {{ name }}, order {{ order }} is on its way.',
    substitutions: {'support_email': 'help@example.com'},
  ),
);
```

### CC, BCC and several To addresses

```dart
await client.messages.createConversation(
  const CreateConversationMessageRequest(
    from: Address(email: 'team@example.com', name: 'Example Team'),
    to: [Address(email: 'ada@example.org'), Address(email: 'grace@example.org')],
    cc: [Address(email: 'manager@example.org')],
    bcc: [Address(email: 'archive@example.com')],
    replyTo: Address(email: 'support@example.com'),
    subject: 'Kick-off on Monday',
    textContent: 'See you all on Monday at 10:00.',
  ),
);
```

### Attachments and inline images

Attachment data is UTF-8 text by default. Set `base64: true` for binary
files. For an inline image, set `contentId` with angle brackets and
reference it from the HTML without them:

```dart
final pdf = await File('invoice-1042.pdf').readAsBytes();
final logo = await File('logo.png').readAsBytes();

await client.messages.create(
  CreateMessageRequest(
    from: const Address(email: 'billing@example.com'),
    recipients: const [Recipient(email: 'ada@example.org')],
    subject: 'Your invoice',
    htmlContent: '<img src="cid:logo@example.com"><p>Your invoice is attached.</p>',
    attachments: [
      Attachment(
        fileName: 'invoice-1042.pdf',
        contentType: 'application/pdf',
        data: base64Encode(pdf),
        base64: true,
      ),
      Attachment(
        fileName: 'logo.png',
        contentType: 'image/png',
        data: base64Encode(logo),
        base64: true,
        contentId: '<logo@example.com>',
      ),
    ],
  ),
);
```

### Scheduling and cancelling

Schedule a message up to 7 days ahead, and let it expire if it cannot be
delivered in time. A scheduled message can be cancelled until it is sent:

```dart
final response = await client.messages.create(
  CreateMessageRequest(
    from: const Address(email: 'reminders@example.com'),
    recipients: const [Recipient(email: 'ada@example.org')],
    subject: 'Your appointment is tomorrow',
    textContent: 'See you tomorrow at 9:00.',
    schedule: MessageSchedule(
      firstAttempt: DateTime.now().add(const Duration(hours: 20)),
      expires: DateTime.now().add(const Duration(hours: 23)),
    ),
  ),
);

final messageId = response.data.single.id!;
await client.messages.cancel(messageId); // Changed plans.
```

### Testing without delivering (sandbox)

With `sandbox: true`, AhaSend processes the message but delivers nothing.
`sandboxResult` simulates the outcome, including the matching webhook
events:

```dart
await client.messages.create(
  const CreateMessageRequest(
    from: Address(email: 'hello@example.com'),
    recipients: [Recipient(email: 'test@example.org')],
    subject: 'Sandbox test',
    textContent: 'Nothing is delivered.',
    sandbox: true,
    sandboxResult: .bounce,
  ),
);
```

### Tags, tracking, headers and retention

```dart
await client.messages.create(
  const CreateMessageRequest(
    from: Address(email: 'security@example.com'),
    recipients: [Recipient(email: 'ada@example.org')],
    subject: 'Password reset',
    textContent: 'Use this link to reset your password: ...',
    tags: ['password-reset'], // Filter messages and statistics by tag.
    tracking: Tracking(open: false, click: false), // Override account defaults.
    headers: {'X-Request-Id': 'req-8f2c'},
    retention: Retention(metadata: 30, data: 0), // Days to keep metadata and content.
  ),
);
```

To make a send safe to retry across restarts, pass your own idempotency
key. See [Retries and idempotency](#retries-and-idempotency).

## Checking what happened to a message

Fetch one message with its delivery attempts and, while it is retained, its
content:

```dart
final message = await client.messages.get(messageId);
print('${message.recipient}: ${message.status}'); // e.g. Delivered, Bounced
for (final attempt in message.deliveryAttempts) {
  print('${attempt.time} ${attempt.status}: ${attempt.log}');
}
print('opens: ${message.openCount}, clicks: ${message.clickCount}');
```

Search recent messages with filters:

```dart
await for (final message in client.messages.listAll(
  status: ['Bounced', 'Failed'],
  tags: ['password-reset'],
  fromTime: DateTime.now().subtract(const Duration(days: 1)),
)) {
  print('${message.recipient} ${message.status} ${message.bounceClassification}');
}
```

Other filters are `sender`, `recipient`, `subject` and `messageIdHeader`.
`messageIdHeader` is an exact match: pass the header with its angle
brackets, as the send response or a webhook event gives it.
For live updates instead of polling, use [webhooks](#webhooks).

## Domains and DNS

You can only send from a domain that you have added and verified. The flow
is: add the domain, publish the DNS records AhaSend gives you, then run the
DNS check.

### Add a domain and get its DNS records

```dart
final domain = await client.domains.create(
  const CreateDomainRequest(domain: 'mail.example.com'),
);

for (final record in domain.dnsRecords) {
  print(
    '${record.type.padRight(5)} ${record.host.padRight(40)} ${record.content}'
    '${record.required ? '' : '  (optional)'}',
  );
}
```

Publish these records at your DNS provider. Each `DnsRecord` has a `type`
(such as `TXT`, `CNAME` or `MX`), a `host`, the `content` to enter, whether
it is `required`, and whether AhaSend already sees it (`propagated`).

Use a subdomain such as `mail.example.com` for transactional mail and
another one such as `news.example.com` with `sendingType: .marketing` for
newsletters, so the two don't share a reputation.

### Check the DNS status

`checkDns` asks AhaSend to look up the records now and returns the updated
domain. Results are cached for 60 seconds, so don't check more often than
that. Most records verify within minutes; DNS changes can take up to 48
hours.

```dart
final checked = await client.domains.checkDns('mail.example.com');
if (checked.dnsValid) {
  print('Ready to send.');
} else {
  final missing = checked.dnsRecords.where((r) => r.required && !r.propagated);
  for (final record in missing) {
    print('Still missing: ${record.type} ${record.host}');
  }
}
```

A small helper that waits until the domain is verified:

```dart
Future<Domain> waitForDns(AhaSendClient client, String name) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    final domain = await client.domains.checkDns(name);
    if (domain.dnsValid) return domain;
    await Future<void>.delayed(const Duration(minutes: 2));
  }
  throw StateError('DNS records of $name are still not valid.');
}
```

`get` returns the stored status without a new lookup, and `lastDnsCheckAt`
tells you when the last check ran.

### List, update and delete domains

```dart
// Every domain that is not verified yet:
await for (final domain in client.domains.listAll(dnsValid: false)) {
  print('${domain.domain}: last checked ${domain.lastDnsCheckAt}');
}

// Turn a domain into a marketing domain:
await client.domains.update(
  'news.example.com',
  const UpdateDomainRequest(sendingType: .marketing),
);

await client.domains.delete('old.example.com');
```

### Paused domains

AhaSend pauses sending from a marketing domain when too many recent emails
from it bounced. Check `paused`, `pausedAt` and `pauseReason`:

```dart
final domain = await client.domains.get('news.example.com');
if (domain.paused) {
  print('Paused since ${domain.pausedAt}: ${domain.pauseReason?.value}');
}
```

Fix the cause, then ask AhaSend support to lift the pause. For a
sub-account, the parent can lift it with
[`subAccounts.unpauseDomain`](#manage-sub-accounts).

## Sub-accounts

Sub-accounts give each of your customers an isolated AhaSend account with
its own domains, suppressions, reputation and API keys, billed to your
(parent) account. They are a Platform Partner feature that AhaSend enables
on request.

There are two kinds of calls:

- **Managing the sub-account** (create, update, suspend, usage, its API
  keys) uses your **parent** API key and the parent account ID. These are
  the `client.subAccounts` methods.
- **Everything inside the sub-account** (domains, sending, webhooks,
  templates, ...) uses an API key **of the sub-account** and the
  sub-account's ID. Get a client for that with
  `client.forAccount(subAccountId, apiKey: childKey)`.

### Create a sub-account and its API key

```dart
// 1. Parent key: create the sub-account.
final subAccount = await client.subAccounts.create(
  const CreateSubAccountRequest(name: 'Acme Inc.', website: 'acme.com'),
  // A stable key makes a retried call return the same sub-account.
  options: const RequestOptions(idempotencyKey: 'sub-account-customer-42'),
);

// 2. Parent key: create the sub-account's first API key.
final childKey = await client.subAccounts.apiKeys.create(
  subAccount.id,
  const CreateApiKeyRequest(
    label: 'Acme backend',
    scopes: ['domains:read', 'domains:write', 'messages:send:all'],
  ),
  options: const RequestOptions(idempotencyKey: 'sub-account-customer-42-key'),
);

// The secret is returned only on creation. Store it in your secret manager
// now, together with subAccount.id. Never log it.
final secret = childKey.secretKey;
```

Scope the child key to what your platform does in the sub-account. See
[API keys and scopes](#api-keys-and-scopes).

### Add a domain to a sub-account

Use the sub-account's key and ID. The rest is the same as for your own
domains:

```dart
final acme = client.forAccount(subAccountId, apiKey: childSecret);

final domain = await acme.domains.create(
  const CreateDomainRequest(domain: 'mail.acme.com'),
);
// Show domain.dnsRecords to your customer, or publish them through your
// DNS provider's API. Then:
final checked = await acme.domains.checkDns('mail.acme.com');
print('mail.acme.com verified: ${checked.dnsValid}');
```

`acme` shares the connection of `client`; there is nothing to close.

### Send as a sub-account

```dart
final acme = client.forAccount(subAccountId, apiKey: childSecret);

await acme.messages.create(
  const CreateMessageRequest(
    from: Address(email: 'noreply@mail.acme.com', name: 'Acme'),
    recipients: [Recipient(email: 'customer@example.org')],
    subject: 'Welcome to Acme',
    textContent: 'Thanks for signing up!',
  ),
);
```

Webhooks, routes, templates, suppressions and statistics of the
sub-account work the same way through `acme`.

### Manage sub-accounts

All of these use the parent key:

```dart
// List and inspect.
await for (final sub in client.subAccounts.listAll()) {
  print('${sub.name} (${sub.id}): ${sub.status.value}, '
      '${sub.domainCount} domains');
}
final sub = await client.subAccounts.get(subAccountId);

// Rename it, or cap its monthly sending (0 means no cap).
await client.subAccounts.update(
  subAccountId,
  const UpdateSubAccountRequest(monthlyCredit: 50000),
);

// Pause all sending of the sub-account, and resume it.
await client.subAccounts.suspend(
  subAccountId,
  const SuspendSubAccountRequest(reason: 'Invoice overdue'),
);
await client.subAccounts.unsuspend(subAccountId);

// Lift a pause on one of its domains after fixing the bounce rate.
await client.subAccounts.unpauseDomain(subAccountId, 'mail.acme.com');

// Soft-delete it.
await client.subAccounts.delete(subAccountId);
```

A sub-account's `status` is `active`, `suspended`, `parentSuspended` (your
own account is paused) or `deleted`.

### Usage and cost per sub-account

```dart
final usage = await client.subAccounts.usage();
print('Period ${usage.billingPeriod.start} to ${usage.billingPeriod.end}');
for (final sub in usage.subAccounts) {
  print('${sub.name}: ${sub.receptionCount} messages, '
      '${sub.allocatedCost} ${usage.currency}');
}
print('Total: ${usage.total.receptionCount} messages');
```

`allocatedCost` is the sub-account's share of your pooled invoice, split by
message volume. It is not what the sub-account would pay on its own plan.

### Rotate a sub-account key

```dart
final newKey = await client.subAccounts.apiKeys.create(
  subAccountId,
  const CreateApiKeyRequest(
    label: 'Acme backend 2026-11',
    scopes: ['messages:send:all'],
  ),
);
// Store newKey.secretKey, switch your services to it, then:
await client.subAccounts.apiKeys.delete(subAccountId, oldKeyId);
```

## API keys and scopes

Every key has a list of scopes. Give each service only what it needs. A
send-only key for one domain is the safest choice for a sending service:

```dart
final key = await client.apiKeys.create(
  const CreateApiKeyRequest(
    label: 'Checkout service',
    scopes: ['messages:send:example.com'],
    // Optional: only accept requests from these IPs or CIDR blocks.
    ipAllowList: ['203.0.113.0/24'],
  ),
);
// key.secretKey is shown only now. Store it in your secret manager.
```

Common scopes:

| Scope | Allows |
| --- | --- |
| `messages:send:all`, `messages:send:{domain}` | Sending from any domain, or from one domain |
| `messages:read:all`, `messages:read:{domain}` | Reading messages |
| `messages:cancel:all`, `messages:cancel:{domain}` | Cancelling scheduled messages |
| `domains:read`, `domains:write`, `domains:delete:all` | Managing domains |
| `webhooks:read:all`, `webhooks:write:all`, `webhooks:delete:all` | Managing webhooks (also per `{domain}`) |
| `routes:read:all`, `routes:write:all`, `routes:delete:all` | Managing routes (also per `{domain}`) |
| `templates:read`, `templates:write`, `templates:delete` | Managing templates |
| `campaigns:read`, `campaigns:write`, `campaigns:send`, `campaigns:delete` | Managing and sending campaigns |
| `contacts:read`, `contacts:write`, `lists:read`, `lists:write` | Managing contacts and lists |
| `suppressions:read`, `suppressions:write`, `suppressions:delete`, `suppressions:wipe` | Managing suppressions |
| `statistics:read:all`, `statistics:read:{domain}` | Reading statistics |
| `smtp-credentials:read:all`, `smtp-credentials:write:all` | Managing SMTP credentials |
| `api-keys:read`, `api-keys:write`, `api-keys:delete` | Managing API keys |
| `sub-accounts:*`, `sub-account-api-keys:*` | Managing [sub-accounts](#sub-accounts) (parent keys only) |

See the [scopes reference](https://ahasend.com/docs/api-reference/scopes)
for the full list.

Change a key's label, scopes or IP allow list with `update`. Pass an empty
`ipAllowList` to remove the restriction:

```dart
await client.apiKeys.update(
  keyId,
  const UpdateApiKeyRequest(ipAllowList: []),
);
```

To rotate a key, create a new one, switch your services over, then delete
the old one with `client.apiKeys.delete(oldKeyId)`.

## Templates

Templates store a design with a subject and default sender, so your code
only sends data. An `html` template is the easiest to manage through the
API; `advanced` templates use MJML.

### Create and publish a template

```dart
final template = await client.templates.create(
  const CreateTemplateRequest(
    name: 'Order shipped',
    subject: 'Order {{ order }} has shipped',
    from: TemplateAddressInput(email: 'orders@example.com', name: 'Example Shop'),
    content: TemplateContentInput(
      html: '<p>Hi {{ name }}, order {{ order }} is on its way.</p>',
    ),
    publish: true, // Publish right away instead of keeping a draft.
  ),
);

// The variables AhaSend found in the design:
for (final variable in template.variables) {
  print('${variable.name} (required: ${variable.required})');
}
```

Without `text`, AhaSend generates the plain-text version from the HTML.

### Send with a template

Recipient substitutions fill the template's variables:

```dart
await client.messages.createFromTemplate(
  CreateTemplateMessageRequest(
    templateId: template.id,
    recipients: const [
      Recipient(
        email: 'ada@example.org',
        substitutions: {'name': 'Ada', 'order': '1042'},
      ),
    ],
  ),
);
```

`from`, `subject` and `replyTo` in the request override the template's
defaults.

A send uses the template's published copy. `client.templates.get` returns
the working copy, which is the draft while the template has one, so read
the variables a send has to supply with `getPublished`:

```dart
final published = await client.templates.getPublished(template.id);
final requiredNames = [
  for (final variable in published.variables)
    if (variable.required) variable.name,
];
```

### Edit, publish and roll back

Updates go to a draft. Sends keep using the published version until you
publish:

```dart
await client.templates.update(
  template.id,
  const UpdateTemplateRequest(
    subject: .set('Good news: order {{ order }} has shipped'),
    content: TemplateContentInput(
      html: '<p>Hi {{ name }}, order {{ order }} is on its way!</p>',
    ),
  ),
);

// Review the draft: get returns it while the template has one.
final draft = await client.templates.get(template.id);
print(draft.hasDraft); // true
await client.templates.publish(template.id);
// Or throw the draft away: await client.templates.discardDraft(template.id);

// Every publish creates a version. Restore an older one:
final versions = await client.templates.listVersions(template.id);
await client.templates.restoreVersion(
  template.id,
  versions.last.id,
  request: const RestoreTemplateVersionRequest(publish: true),
);
```

## Contacts and lists

Contacts and lists are the audience of [campaigns](#campaigns).

### Contacts

```dart
final contact = await client.contacts.create(
  const CreateContactRequest(
    email: 'ada@example.org',
    firstName: 'Ada',
    lastName: 'Lovelace',
    // Custom attributes must be defined in the dashboard first.
    attributes: {'plan': 'pro', 'signed_up': '2026-10-01'},
  ),
);

// Fetch by ID or email, update, delete.
await client.contacts.get('ada@example.org');
await client.contacts.update(
  'ada@example.org',
  const UpdateContactRequest(
    unsubscribed: true,
    attributes: {'plan': null}, // null removes an attribute.
  ),
);
await client.contacts.delete(contact.id);
```

Import many contacts at once. Each entry is created or updated by email, and
one failing entry does not stop the others:

```dart
final result = await client.contacts.batchUpsert(
  const BatchUpsertContactsRequest(
    data: [
      BatchUpsertContactInput(email: 'ada@example.org', firstName: 'Ada'),
      BatchUpsertContactInput(email: 'grace@example.org', firstName: 'Grace'),
    ],
  ),
);
print('${result.created} created, ${result.updated} updated, '
    '${result.failed} failed');
for (final failure in result.data.where((r) => r.outcome == .failed)) {
  print('${failure.email}: ${failure.reason}');
}
```

### Lists

```dart
final list = await client.lists.create(
  const CreateContactListRequest(name: 'Newsletter', tags: ['marketing']),
);

// Add existing contacts by email or ID.
await client.lists.batchAddContacts(
  list.id,
  const BatchAddListContactsRequest(
    data: [
      BatchAddListContactInput.byEmail('ada@example.org'),
      BatchAddListContactInput.byEmail('grace@example.org'),
    ],
  ),
);

// Add or update one member with a subscription status.
await client.lists.upsertContact(
  list.id,
  'ada@example.org',
  const UpsertListContactRequest(subscriptionStatus: .confirmed),
);

// Members, with their contact data.
await for (final member in client.lists.listAllContacts(
  list.id,
  subscriptionStatus: .confirmed,
  includeContacts: true,
)) {
  print('${member.email} ${member.contact?.firstName}');
}

// Which lists is a contact on?
await for (final membership in client.lists.listAllForContact('ada@example.org')) {
  print(membership.listId);
}

await client.lists.removeContact(list.id, 'grace@example.org');
```

## Campaigns

A campaign sends one design to the contacts of one or more lists.

### Create, test and send

```dart
final campaign = await client.campaigns.create(
  CreateCampaignRequest(
    name: 'October newsletter',
    subject: 'What is new in October',
    from: const TemplateAddressInput(email: 'news@example.com', name: 'Example'),
    listIds: [newsletterListId],
    editor: .html,
    content: const TemplateContentInput(
      html: '<h1>October news</h1><p>...</p>'
          '<p><a href="{{ unsubscribe_url }}">Unsubscribe</a></p>',
    ),
  ),
);

// Campaigns must contain an unsubscribe link. Check what is missing:
if (campaign.ready == false) {
  for (final issue in campaign.issues ?? const <CampaignIssue>[]) {
    print('${issue.code.value}: ${issue.message}');
  }
}

// Send a test to up to 5 addresses.
await client.campaigns.test(
  campaign.id,
  const TestCampaignRequest(to: ['me@example.com']),
);

// Send now, or schedule it.
try {
  await client.campaigns.send(
    campaign.id,
    request: SendCampaignRequest(sendAt: DateTime.utc(2026, 11, 1, 9)),
  );
} on BadRequestException catch (e) {
  final notReady = CampaignNotReady.fromException(e);
  print('Not ready: ${notReady?.issues?.map((i) => i.code.value)}');
}
```

A campaign can also copy a campaign template: pass `templateId` instead of
`content`. Use `client.campaignTemplates` to manage those.

A scheduled campaign can be moved back to draft with
`client.campaigns.unschedule(id)`, changed with `update`, and sent again.
`duplicate` copies a campaign.

### Results

```dart
final stats = await client.campaigns.stats(campaign.id);
print('${stats.delivered}/${stats.recipients} delivered, '
    'open rate ${stats.rates.openRate}, click rate ${stats.rates.clickRate}');

await for (final recipient in client.campaigns.listAllRecipients(
  campaign.id,
  status: 'bounced',
)) {
  print('${recipient.email}: ${recipient.bounceReason}');
}
```

## Suppressions

AhaSend does not send to suppressed addresses, for example after a hard
bounce. You can list, add and remove them:

```dart
// Is this address suppressed?
final page = await client.suppressions.list(email: 'ada@example.org');
for (final suppression in page.data) {
  print('${suppression.reason} until ${suppression.expiresAt}');
}

// Suppress an address for a year.
await client.suppressions.create(
  CreateSuppressionRequest(
    email: 'ada@example.org',
    reason: 'Asked us to stop',
    expiresAt: DateTime.now().add(const Duration(days: 365)),
  ),
);

// Allow sending again, for all domains or one domain.
await client.suppressions.delete('ada@example.org');
await client.suppressions.delete('ada@example.org', domain: 'example.com');
```

`deleteAll()` removes every suppression (it needs the
`suppressions:wipe` scope).

## Webhooks

Webhooks tell your server about events of the messages you send: delivered,
bounced, opened, clicked and more.

### Create a webhook

```dart
final webhook = await client.webhooks.create(
  const CreateWebhookRequest(
    name: 'Delivery events',
    url: 'https://api.example.com/ahasend/webhook',
    scope: .global, // Or .scoped with `domains: [...]`.
    onDelivered: true,
    onBounced: true,
    onFailed: true,
    onSuppressionCreated: true,
  ),
);
// The signing secret is returned only now. Store it for the verifier.
final webhookSecret = webhook.secret;
```

Change the events later with
`client.webhooks.update(id, UpdateWebhookRequest(...))`. `get` and `list`
show `successCount`, `errorCount` and `lastRequestAt`, so you can see
whether deliveries reach your server.

### Verify and handle deliveries

Import `package:ahasend/webhooks.dart` and pass the raw request body
exactly as received. Use `verify` for a `String` body and `verifyBytes`
when your framework gives you the bytes:

```dart
import 'package:ahasend/webhooks.dart';

final verifier = WebhookVerifier(webhookSecret); // 'aha-whsec-...'

int handle(String rawBody, Map<String, String> headers) {
  final WebhookEvent event;
  try {
    event = verifier.verify(body: rawBody, headers: headers);
  } on WebhookVerificationException {
    return 400; // Not from AhaSend, or replayed.
  } on InvalidPayloadException {
    // Authentic, but this package version cannot decode it. Retrying would
    // not help: store the body to look at later and acknowledge it.
    return 204;
  }

  switch (event) {
    case MessageDeliveredEvent(:final data):
      print('Delivered to ${data.recipient}');
    case MessageBouncedEvent(:final data):
      print('Bounced: ${data.recipient} '
          '(${data.deliveryAttempt?.classification})');
    case SuppressionCreatedEvent(:final data):
      print('Suppressed ${data.recipient} until ${data.expiresAt}');
    default:
      break;
  }
  return 204;
}
```

Group the events of a message by `data.messageIdHeader`: it equals
`messageIdHeader` from the send response and never changes. `data.id` is
the API message ID, but a message sent before 9 November 2026 can receive
events with an older, different ID for up to 30 days. Campaign messages
send the same events; `messages.get` cannot fetch them by `data.id`.

The verifier checks the signature in constant time and rejects timestamps
more than five minutes away from the current time. It does not protect
against replays by itself: store the `webhook-id` with your work item and
skip IDs you have seen.

AhaSend can add event types at any time, and nothing breaks when it does:
a type this package version does not know arrives as an
`UnknownWebhookEvent`, and a later version may give it its own class.
Keep a `default` branch, acknowledge such events with a 2xx response, and
match a type the package does not know yet on `event.type`, not on
`UnknownWebhookEvent`. The same holds for enum values: see
[Enums](#enums).

`WebhookVerifier.signedHeaders` builds valid headers for your own tests.

## Inbound email (routes)

Routes receive email sent **to** your domain and post it to your server as
JSON. Point the domain's MX records to AhaSend first (they are part of
`domain.dnsRecords`).

```dart
final route = await client.routes.create(
  const CreateRouteRequest(
    name: 'Support inbox',
    recipient: 'support@example.com', // Wildcards work: 'ticket-*@example.com'
    url: 'https://api.example.com/ahasend/inbound',
    attachments: true,
    stripReplies: true, // Also extract the new text of a reply.
  ),
);
final routeSecret = route.secret; // Shown only now. Store it.
```

Route deliveries are signed like webhooks, with the route's secret:

```dart
final verifier = WebhookVerifier(routeSecret); // 'aha-rsec-...'

void handleInbound(String rawBody, Map<String, String> headers) {
  final event = verifier.verify(body: rawBody, headers: headers);
  if (event case MessageRoutingEvent(:final data)) {
    print('From ${data.from}: ${data.subject}');
    print(data.replyFromPlainBody.isNotEmpty
        ? data.replyFromPlainBody
        : data.plainBody);
    for (final attachment in data.attachments) {
      final bytes = attachment.decodeData();
      print('${attachment.filename}: ${bytes.length} bytes');
    }
  }
}
```

## Statistics

### Email statistics

`emails` returns stored email counts of transactional, campaign and
inbound mail, for any time in the account's history:

```dart
final stats = await client.statistics.emails(
  fromTime: DateTime.utc(2026, 1, 1),
  toTime: DateTime.utc(2027, 1, 1),
  groupBy: .month,
);
print('Delivered in 2026: ${stats.totals.deliveredCount}');
for (final month in stats.data) {
  print('${month.fromTimestamp}: ${month.deliveredCount} delivered, '
      '${month.bouncedCount} bounced, ${month.complainedCount} complaints');
}
```

The range is rounded to whole periods (`stats.fromTime`, `stats.toTime`)
and can be at most 31 days for `hour`, 366 days for `day` and `week`, and
5 years for `month`. Opens, clicks and deferrals count events, so one
message can add more than one.

Break the counts down by domain with `breakdown: .domain`. The rows are
paged by domain; `totals` covers the whole request on every page:

```dart
EmailStatisticsResponse? page = await client.statistics.emails(
  groupBy: .week,
  breakdown: .domain,
  limit: 50,
);
while (page != null) {
  for (final row in page.data) {
    print('${row.senderDomain} ${row.fromTimestamp}: ${row.receptionCount}');
  }
  page = await page.nextPage();
}
```

### Transactional statistics

`deliverability`, `bounce` and `deliveryTime` cover transactional mail
within the account's message retention period, and are rate limited to one
request per second:

```dart
final days = await client.statistics.deliverability(
  fromTime: DateTime.now().subtract(const Duration(days: 7)),
  toTime: DateTime.now(),
  groupBy: .day,
  senderDomains: ['mail.example.com'],
);
for (final day in days) {
  print('${day.fromTimestamp}: ${day.deliveredCount} delivered, '
      '${day.bouncedCount} bounced, ${day.openedCount} opened');
}

final bounces = await client.statistics.bounce(groupBy: .week);
final speed = await client.statistics.deliveryTime(groupBy: .day);
```

All three take the same filters: `fromTime`, `toTime`, `senderDomains`,
`recipientDomains`, `tags` and `groupBy` (`hour`, `day`, `week`, `month`).
`deliverability` counts each message once by its current status, so its
numbers differ from `emails` for the same range.

## SMTP credentials

For software that can only send over SMTP (host `send.ahasend.com`, ports
587, 25 or 2525 with STARTTLS):

```dart
final credential = await client.smtpCredentials.create(
  const CreateSmtpCredentialRequest(
    name: 'Legacy CRM',
    scope: .scoped,
    domains: ['mail.example.com'],
  ),
);
print('User: ${credential.username}');
// credential.password is shown only now. Store it.
```

## Account and members

```dart
final account = await client.accounts.get();
print('${account.name}: open tracking ${account.trackOpens}');

await client.accounts.update(
  const UpdateAccountRequest(trackClicks: false, messageDataRetention: 3),
);

for (final member in await client.accounts.listMembers()) {
  print('${member.userId}: ${member.role.value}');
}
await client.accounts.addMember(
  const AddMemberRequest(email: 'dev@example.com', role: .developer),
);
```

## Resources

| Property | API area |
| --- | --- |
| `client.messages` | Send, list, fetch and cancel messages |
| `client.templates` | Transactional templates, drafts and versions |
| `client.campaigns` | Marketing campaigns, test sends, stats and recipients |
| `client.campaignTemplates` | Campaign templates |
| `client.contacts` | Contacts and batch upserts |
| `client.lists` | Contact lists and list membership |
| `client.suppressions` | Suppressed addresses |
| `client.domains` | Sending domains and DNS checks |
| `client.webhooks` | Webhook endpoints |
| `client.routes` | Inbound routes |
| `client.smtpCredentials` | SMTP credentials |
| `client.apiKeys` | API keys |
| `client.accounts` | Account settings and members |
| `client.subAccounts` | Sub-accounts, their API keys and usage |
| `client.statistics` | Email, deliverability, bounce and delivery-time statistics |
| `client.ping()` | Checks the API key |

Enums and `Patch` values work with dot shorthands, as in `role: .developer`
or `subject: .set('...')`.

## Pagination

List methods return one `CursorPage`. `listAll` returns a `Stream` that fetches
the following pages as you iterate.

```dart
final page = await client.domains.list(limit: 50);
print(page.data.length);
final next = await page.nextPage(); // null on the last page

await for (final contact in client.contacts.listAll(subscribed: true)) {
  print(contact.email);
}
```

## Errors

Every error of the API client extends the sealed class `AhaSendException`:

| Exception | Cause |
| --- | --- |
| `BadRequestException` | HTTP 400 |
| `AuthenticationException` | HTTP 401: missing or invalid API key |
| `PermissionDeniedException` | HTTP 403: missing scope or IP not allowed |
| `NotFoundException` | HTTP 404 |
| `ConflictException` / `IdempotencyConflictException` | HTTP 409 |
| `UnprocessableEntityException` | HTTP 422 |
| `RateLimitException` | HTTP 429, with `retryAfter` |
| `ServerException` | HTTP 5xx |
| `ApiException` | Base class of the above, also used for other statuses |
| `NetworkException` | Connection failed or timed out |
| `UnexpectedResponseException` | The response could not be decoded |
| `InvalidUsageException` | The SDK was misused, for example without an account ID |

```dart
try {
  await client.domains.get('example.com');
} on NotFoundException {
  print('No such domain');
} on ApiException catch (e) {
  print('HTTP ${e.statusCode}: ${e.message} (request ${e.requestId})');
}
```

The API sends no machine-readable error codes, so branch on the exception
type, not on the message.

## Retries and idempotency

By default the client retries up to three times after network failures,
HTTP 429 and HTTP 5xx, waiting for `Retry-After` when the API sends it and
otherwise backing off exponentially with jitter.

Operations that support idempotency get a random `Idempotency-Key`, which
the client reuses for its own retries. For safety across process restarts,
pass a key derived from your own data:

```dart
await client.messages.create(
  request,
  options: RequestOptions(
    idempotencyKey: 'order-$orderId-receipt',
    onResponse: (info) => print('replayed: ${info.idempotentReplayed}'),
  ),
);
```

AhaSend stores the outcome of an idempotent request for 24 hours (5 minutes
for API key creation) and replays it for the same key.

Configure or turn off retries with `RetryConfig`:

```dart
final client = AhaSendClient(
  apiKey: apiKey,
  accountId: accountId,
  retry: const RetryConfig(maxRetries: 5, maxDelay: Duration(seconds: 10)),
  // retry: RetryConfig.disabled,
);
```

`RequestOptions` can also override the API key, the timeout and headers for
a single call.

## Updating fields

Most update requests leave out fields that are `null`. Where the API makes a
difference between leaving a field unchanged and clearing it, the field takes
a `Patch`:

```dart
await client.campaigns.update(
  campaignId,
  UpdateCampaignRequest(
    subject: const .set('October news'),
    replyTo: const .clear(), // sends "reply_to": null
  ),
);
```

## Enums

Fields with a fixed set of values, such as `Campaign.status`, use types like
`CampaignStatus`. They are extension types on `String`, so a value the API
adds later is kept as it is instead of breaking your code or the decoding:

```dart
switch (campaign.status) {
  case CampaignStatus.sent:
    print('Done');
  case CampaignStatus.failed:
    print('Failed: ${campaign.statusReason}');
  default:
    // Also reached for values this package version does not know yet.
    print('Status ${campaign.status.value}');
}

campaign.status.isKnown; // false for a value added after this version
CampaignStatus.values;   // every value this version knows
```

A switch over these types always needs a `default` branch, so a new value
never turns into a compile error. To send a value the package does not
know yet, create it from its string: `CampaignStatus('new_status')`.

## Testing your code

`AhaSendClient` and its resources are interface classes, so your tests can
replace them with fakes or mocks, for example with `package:test`'s `Fake`
or with [mocktail](https://pub.dev/packages/mocktail):

```dart
class FakeMessages() extends Fake implements MessagesResource {
  final sent = <CreateMessageRequest>[];

  @override
  Future<CreateMessageResponse> create(
    CreateMessageRequest request, {
    RequestOptions? options,
  }) async {
    sent.add(request);
    return const CreateMessageResponse(data: []);
  }
}

class FakeAhaSend() extends Fake implements AhaSendClient {
  @override
  final messages = FakeMessages();
}
```

To test against recorded HTTP responses instead, pass a `MockClient` from
`package:http/testing.dart` as `httpClient`. For end-to-end tests against
the real API, use [sandbox sends](#testing-without-delivering-sandbox).

## Flutter, the web and other runtimes

The package has no `dart:io` dependency, so it runs on the Dart VM, in
Flutter, on the web and in serverless runtimes. You can inject any
`http.Client` with the `httpClient` parameter.

Some names, such as `Message`, `Contact` or `Template`, may also exist in
your own code, for example in Serverpod models. Import the package with a
prefix then: `import 'package:ahasend/ahasend.dart' as aha;`.

That does not make it a good idea to call AhaSend from an app: see the
warning at the top. In a Flutter app, call your own backend, and let the
backend use this package.

## Links

- [AhaSend API reference](https://ahasend.com/docs/api-reference)
- [OpenAPI spec](https://ahasend.com/docs/openapi.yaml)

This package is not an official AhaSend product.
