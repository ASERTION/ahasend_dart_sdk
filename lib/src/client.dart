import 'package:http/http.dart' as http;

import 'http/request_options.dart';
import 'http/retry.dart';
import 'http/transport.dart';
import 'json.dart';
import 'models/common.dart';
import 'resources/accounts.dart';
import 'resources/api_keys.dart';
import 'resources/campaign_templates.dart';
import 'resources/campaigns.dart';
import 'resources/contacts.dart';
import 'resources/domains.dart';
import 'resources/lists.dart';
import 'resources/messages.dart';
import 'resources/routes.dart';
import 'resources/smtp_credentials.dart';
import 'resources/statistics.dart';
import 'resources/sub_accounts.dart';
import 'resources/suppressions.dart';
import 'resources/templates.dart';
import 'resources/webhooks.dart';

/// A client for the AhaSend API v2.
///
/// ```dart
/// final client = AhaSendClient(
///   apiKey: 'aha-sk-...',
///   accountId: '00000000-0000-0000-0000-000000000000',
/// );
///
/// final response = await client.messages.create(
///   CreateMessageRequest(
///     from: Address(email: 'hello@example.com', name: 'Example'),
///     recipients: [Recipient(email: 'user@example.org')],
///     subject: 'Welcome',
///     htmlContent: '<p>Hello!</p>',
///   ),
/// );
///
/// client.close();
/// ```
///
/// Most endpoints act on an account, so pass the [accountId] you find in the
/// AhaSend dashboard. Use [forAccount] to work inside a sub-account.
///
/// Create one client when your program starts and share it: it reuses HTTP
/// connections and is safe to use from concurrent requests. Call [close]
/// once, when the program shuts down, not after each request.
///
/// Use the client on a server only. An API key shipped in an app or a web
/// bundle can be extracted by anyone.
interface class AhaSendClient._(
  final Transport _transport,

  /// The account the account endpoints act on.
  final String? accountId,
) {
  /// Creates a client.
  ///
  /// - [apiKey]: an API key, sent as `Authorization: Bearer <apiKey>`.
  /// - [accountId]: the account the account endpoints act on.
  /// - [baseUrl]: the API base URL. Defaults to `https://api.ahasend.com`.
  /// - [httpClient]: the HTTP client to use. When you pass one, you own it
  ///   and [close] does not close it.
  /// - [timeout]: the timeout for each attempt of a request.
  /// - [retry]: how failed requests are retried.
  /// - [userAgent]: the `User-Agent` header (not sent in browsers).
  /// - [headers]: extra headers sent with every request.
  factory({
    required String apiKey,
    String? accountId,
    Uri? baseUrl,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 30),
    RetryConfig retry = const RetryConfig(),
    String? userAgent,
    Map<String, String> headers = const {},
  }) {
    if (apiKey.trim().isEmpty) {
      throw ArgumentError.value(apiKey, 'apiKey', 'must not be empty');
    }
    return AhaSendClient._(
      Transport(
        apiKey: apiKey,
        baseUrl: baseUrl ?? defaultBaseUrl,
        httpClient: httpClient ?? http.Client(),
        ownsHttpClient: httpClient == null,
        timeout: timeout,
        retry: retry,
        userAgent: userAgent ?? defaultUserAgent,
        defaultHeaders: headers,
      ),
      accountId,
    );
  }

  /// The default API base URL.
  static final Uri defaultBaseUrl = Uri.parse('https://api.ahasend.com');

  /// Returns a client that acts on [accountId], optionally with another
  /// [apiKey].
  ///
  /// Use it to work inside a sub-account: everything in a sub-account
  /// (domains, messages, webhooks, ...) is managed with an API key of that
  /// sub-account, created with `subAccounts.apiKeys.create`.
  ///
  /// ```dart
  /// final child = client.forAccount(subAccountId, apiKey: childSecretKey);
  /// await child.domains.create(const CreateDomainRequest(domain: 'mail.acme.com'));
  /// ```
  ///
  /// The returned client shares this client's connection and settings. It
  /// does not own the connection: calling `close()` on it does nothing, and
  /// it stops working once this client is closed.
  AhaSendClient forAccount(String accountId, {String? apiKey}) {
    if (apiKey != null && apiKey.trim().isEmpty) {
      throw ArgumentError.value(apiKey, 'apiKey', 'must not be empty');
    }
    return AhaSendClient._(_transport.view(apiKey: apiKey), accountId);
  }

  /// Send, list, fetch and cancel messages.
  late final MessagesResource messages = MessagesResource(
    _transport,
    accountId,
  );

  /// Read and update the account and manage its members.
  late final AccountsResource accounts = AccountsResource(
    _transport,
    accountId,
  );

  /// Create, list, update and delete API keys.
  late final ApiKeysResource apiKeys = ApiKeysResource(_transport, accountId);

  /// Manage campaign templates.
  late final CampaignTemplatesResource campaignTemplates =
      CampaignTemplatesResource(_transport, accountId);

  /// Create, schedule, send and report on campaigns.
  late final CampaignsResource campaigns = CampaignsResource(
    _transport,
    accountId,
  );

  /// Create, list, update and delete contacts.
  late final ContactsResource contacts = ContactsResource(
    _transport,
    accountId,
  );

  /// Add, verify, update and delete sending domains.
  late final DomainsResource domains = DomainsResource(_transport, accountId);

  /// Manage contact lists and their members.
  late final ListsResource lists = ListsResource(_transport, accountId);

  /// Manage inbound routes.
  late final RoutesResource routes = RoutesResource(_transport, accountId);

  /// Create, list and delete SMTP credentials.
  late final SmtpCredentialsResource smtpCredentials = SmtpCredentialsResource(
    _transport,
    accountId,
  );

  /// Read transactional email statistics.
  late final StatisticsResource statistics = StatisticsResource(
    _transport,
    accountId,
  );

  /// Create and manage sub-accounts and their API keys.
  late final SubAccountsResource subAccounts = SubAccountsResource(
    _transport,
    accountId,
  );

  /// List, add and remove suppressed addresses.
  late final SuppressionsResource suppressions = SuppressionsResource(
    _transport,
    accountId,
  );

  /// Manage transactional templates, drafts and versions.
  late final TemplatesResource templates = TemplatesResource(
    _transport,
    accountId,
  );

  /// Manage webhook endpoints.
  late final WebhooksResource webhooks = WebhooksResource(
    _transport,
    accountId,
  );

  /// Checks that the API is reachable and the API key is valid.
  Future<SuccessResponse> ping({RequestOptions? options}) async {
    final json = await _transport.request('GET', '/v2/ping', options: options);
    return SuccessResponse.fromJson(asJsonMapOrNull(json) ?? const {});
  }

  /// Closes the underlying HTTP client if this client created it.
  void close() => _transport.close();
}
