// Checks that every operation in the OpenAPI spec has an SDK method that
// sends the documented HTTP method to the documented path, with an
// Idempotency-Key header exactly when the spec declares one.
//
// When the spec in tool/spec/openapi.yaml is updated, a new operation makes
// this test fail until it is mapped below.
@TestOn('vm')
library;

import 'dart:io';

import 'package:ahasend/ahasend.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'helpers.dart';

typedef Call = Future<Object?> Function(AhaSendClient c);

final Map<String, Call> calls = {
  'ping': (c) => c.ping(),
  // API keys
  'getAPIKeys': (c) => c.apiKeys.list(),
  'createAPIKey': (c) => c.apiKeys.create(
    const CreateApiKeyRequest(label: 'l', scopes: ['messages:send:all']),
  ),
  'getAPIKey': (c) => c.apiKeys.get('k'),
  'updateAPIKey': (c) =>
      c.apiKeys.update('k', const UpdateApiKeyRequest(label: 'l')),
  'deleteAPIKey': (c) => c.apiKeys.delete('k'),
  // Domains
  'getDomains': (c) => c.domains.list(),
  'createDomain': (c) =>
      c.domains.create(const CreateDomainRequest(domain: 'example.com')),
  'getDomain': (c) => c.domains.get('example.com'),
  'updateDomain': (c) =>
      c.domains.update('example.com', const UpdateDomainRequest()),
  'deleteDomain': (c) => c.domains.delete('example.com'),
  'checkDomainDNS': (c) => c.domains.checkDns('example.com'),
  // Messages
  'getMessages': (c) => c.messages.list(),
  'createMessage': (c) => c.messages.create(
    const CreateMessageRequest(
      from: Address(email: 'a@example.com'),
      recipients: [Recipient(email: 'b@example.com')],
      subject: 's',
      textContent: 't',
    ),
  ),
  'createTemplateMessage': (c) => c.messages.createFromTemplate(
    const CreateTemplateMessageRequest(
      templateId: 't',
      recipients: [Recipient(email: 'b@example.com')],
    ),
  ),
  'createConversationMessage': (c) => c.messages.createConversation(
    const CreateConversationMessageRequest(
      from: Address(email: 'a@example.com'),
      to: [Address(email: 'b@example.com')],
      subject: 's',
      textContent: 't',
    ),
  ),
  'getMessage': (c) => c.messages.get('m'),
  'cancelMessage': (c) => c.messages.cancel('m'),
  // Templates
  'listTemplates': (c) => c.templates.list(),
  'createTemplate': (c) =>
      c.templates.create(const CreateTemplateRequest(name: 'n')),
  'getTemplate': (c) => c.templates.get('t'),
  'updateTemplate': (c) =>
      c.templates.update('t', const UpdateTemplateRequest()),
  'deleteTemplate': (c) => c.templates.delete('t'),
  'getTemplateDraft': (c) => c.templates.getDraft('t'),
  'discardTemplateDraft': (c) => c.templates.discardDraft('t'),
  'publishTemplate': (c) => c.templates.publish('t'),
  'listTemplateVersions': (c) => c.templates.listVersions('t'),
  'getTemplateVersion': (c) => c.templates.getVersion('t', 'v'),
  'restoreTemplateVersion': (c) => c.templates.restoreVersion('t', 'v'),
  // Campaign templates
  'listCampaignTemplates': (c) => c.campaignTemplates.list(),
  'createCampaignTemplate': (c) => c.campaignTemplates.create(
    const CreateCampaignTemplateRequest(name: 'n'),
  ),
  'getCampaignTemplate': (c) => c.campaignTemplates.get('t'),
  'updateCampaignTemplate': (c) =>
      c.campaignTemplates.update('t', const UpdateCampaignTemplateRequest()),
  'deleteCampaignTemplate': (c) => c.campaignTemplates.delete('t'),
  // Campaigns
  'listCampaigns': (c) => c.campaigns.list(),
  'createCampaign': (c) =>
      c.campaigns.create(const CreateCampaignRequest(name: 'n')),
  'getCampaign': (c) => c.campaigns.get('c'),
  'updateCampaign': (c) =>
      c.campaigns.update('c', const UpdateCampaignRequest()),
  'deleteCampaign': (c) => c.campaigns.delete('c'),
  'duplicateCampaign': (c) => c.campaigns.duplicate('c'),
  'sendCampaign': (c) => c.campaigns.send('c'),
  'unscheduleCampaign': (c) => c.campaigns.unschedule('c'),
  'testCampaign': (c) =>
      c.campaigns.test('c', const TestCampaignRequest(to: ['a@example.com'])),
  'getCampaignStats': (c) => c.campaigns.stats('c'),
  'listCampaignRecipients': (c) => c.campaigns.listRecipients('c'),
  // Accounts
  'getAccount': (c) => c.accounts.get(),
  'updateAccount': (c) => c.accounts.update(const UpdateAccountRequest()),
  'getAccountMembers': (c) => c.accounts.listMembers(),
  'addAccountMember': (c) => c.accounts.addMember(
    const AddMemberRequest(
      email: 'a@example.com',
      role: AccountMemberRole.developer,
    ),
  ),
  'removeAccountMember': (c) => c.accounts.removeMember('u'),
  // Sub-accounts
  'listSubAccounts': (c) => c.subAccounts.list(),
  'createSubAccount': (c) => c.subAccounts.create(
    const CreateSubAccountRequest(name: 'n', website: 'https://x.test'),
  ),
  'getSubAccountsUsage': (c) => c.subAccounts.usage(),
  'getSubAccount': (c) => c.subAccounts.get('s'),
  'updateSubAccount': (c) =>
      c.subAccounts.update('s', const UpdateSubAccountRequest(name: 'n')),
  'deleteSubAccount': (c) => c.subAccounts.delete('s'),
  'suspendSubAccount': (c) =>
      c.subAccounts.suspend('s', const SuspendSubAccountRequest(reason: 'r')),
  'unsuspendSubAccount': (c) => c.subAccounts.unsuspend('s'),
  'unpauseSubAccountDomain': (c) =>
      c.subAccounts.unpauseDomain('s', 'example.com'),
  'listSubAccountAPIKeys': (c) => c.subAccounts.apiKeys.list('s'),
  'createSubAccountAPIKey': (c) => c.subAccounts.apiKeys.create(
    's',
    const CreateApiKeyRequest(label: 'l', scopes: ['messages:send:all']),
  ),
  'getSubAccountAPIKey': (c) => c.subAccounts.apiKeys.get('s', 'k'),
  'updateSubAccountAPIKey': (c) => c.subAccounts.apiKeys.update(
    's',
    'k',
    const UpdateApiKeyRequest(label: 'l'),
  ),
  'deleteSubAccountAPIKey': (c) => c.subAccounts.apiKeys.delete('s', 'k'),
  // Contacts
  'createContact': (c) =>
      c.contacts.create(const CreateContactRequest(email: 'a@example.com')),
  'getContacts': (c) => c.contacts.list(),
  'batchUpsertContacts': (c) => c.contacts.batchUpsert(
    const BatchUpsertContactsRequest(
      data: [BatchUpsertContactInput(email: 'a@example.com')],
    ),
  ),
  'getContact': (c) => c.contacts.get('a@example.com'),
  'updateContact': (c) =>
      c.contacts.update('a@example.com', const UpdateContactRequest()),
  'deleteContact': (c) => c.contacts.delete('a@example.com'),
  // Lists
  'getLists': (c) => c.lists.list(),
  'createList': (c) =>
      c.lists.create(const CreateContactListRequest(name: 'n')),
  'getList': (c) => c.lists.get('l'),
  'updateList': (c) => c.lists.update('l', const UpdateContactListRequest()),
  'deleteList': (c) => c.lists.delete('l'),
  'getListContacts': (c) => c.lists.listContacts('l'),
  'batchAddListContacts': (c) => c.lists.batchAddContacts(
    'l',
    const BatchAddListContactsRequest(
      data: [BatchAddListContactInput.byEmail('a@example.com')],
    ),
  ),
  'upsertListContact': (c) => c.lists.upsertContact(
    'l',
    'a@example.com',
    const UpsertListContactRequest(),
  ),
  'deleteListContact': (c) => c.lists.removeContact('l', 'a@example.com'),
  'getContactLists': (c) => c.lists.listForContact('a@example.com'),
  // Suppressions
  'getSuppressions': (c) => c.suppressions.list(),
  'createSuppression': (c) => c.suppressions.create(
    CreateSuppressionRequest(
      email: 'a@example.com',
      expiresAt: DateTime.utc(2030),
    ),
  ),
  'deleteSuppression': (c) => c.suppressions.delete('a@example.com'),
  'deleteAllSuppressions': (c) => c.suppressions.deleteAll(),
  // Routes
  'getRoutes': (c) => c.routes.list(),
  'createRoute': (c) => c.routes.create(
    const CreateRouteRequest(
      name: 'n',
      url: 'https://x.test',
      recipient: '*@example.com',
    ),
  ),
  'getRoute': (c) => c.routes.get('r'),
  'updateRoute': (c) => c.routes.update('r', const UpdateRouteRequest()),
  'deleteRoute': (c) => c.routes.delete('r'),
  // Webhooks
  'getWebhooks': (c) => c.webhooks.list(),
  'createWebhook': (c) => c.webhooks.create(
    const CreateWebhookRequest(
      name: 'n',
      url: 'https://x.test',
      scope: WebhookScope.global,
    ),
  ),
  'getWebhook': (c) => c.webhooks.get('w'),
  'updateWebhook': (c) => c.webhooks.update('w', const UpdateWebhookRequest()),
  'deleteWebhook': (c) => c.webhooks.delete('w'),
  // SMTP credentials
  'getSMTPCredentials': (c) => c.smtpCredentials.list(),
  'createSMTPCredential': (c) => c.smtpCredentials.create(
    const CreateSmtpCredentialRequest(
      name: 'n',
      scope: SmtpCredentialScope.global,
    ),
  ),
  'getSMTPCredential': (c) => c.smtpCredentials.get('s'),
  'deleteSMTPCredential': (c) => c.smtpCredentials.delete('s'),
  // Statistics
  'getDeliverabilityStatistics': (c) => c.statistics.deliverability(),
  'getBounceStatistics': (c) => c.statistics.bounce(),
  'getDeliveryTimeStatistics': (c) => c.statistics.deliveryTime(),
};

class SpecOperation(
  final String id,
  final String method,
  final String path,
  final bool idempotent,
) {
  /// Matches a concrete request path against the path template.
  RegExp get pattern =>
      RegExp('^${path.replaceAll(RegExp(r'\{[^}]+\}'), '[^/]+')}\$');
}

List<SpecOperation> loadOperations() {
  final spec = loadYaml(File('tool/spec/openapi.yaml').readAsStringSync());
  final paths = (spec as YamlMap)['paths'] as YamlMap;
  return [
    for (final MapEntry(key: path, value: item) in paths.entries)
      for (final MapEntry(key: method, value: op) in (item as YamlMap).entries)
        SpecOperation(
          (op as YamlMap)['operationId'] as String,
          (method as String).toUpperCase(),
          path as String,
          ((op['parameters'] as YamlList?) ?? YamlList()).any(
            (p) =>
                (p as YamlMap)[r'$ref'] ==
                '#/components/parameters/IdempotencyKey',
          ),
        ),
  ];
}

void main() {
  final operations = loadOperations();

  test('spec has operations', () {
    expect(operations, hasLength(greaterThan(90)));
  });

  test('every SDK mapping refers to a spec operation', () {
    final ids = operations.map((o) => o.id).toSet();
    expect(calls.keys.where((k) => !ids.contains(k)), isEmpty);
  });

  for (final op in operations) {
    test('${op.id}: ${op.method} ${op.path}', () async {
      final call = calls[op.id];
      expect(call, isNotNull, reason: 'No SDK method mapped for ${op.id}');

      final api = FakeApi();
      try {
        await call!(api.client());
      } on UnexpectedResponseException {
        // The canned response does not match every schema; only the
        // request matters here.
      }
      expect(api.requests, hasLength(1));
      final request = api.last;
      expect(request.method, op.method);
      expect(
        request.url.path,
        matches(op.pattern),
        reason: 'expected path ${op.path}',
      );
      if (op.path.contains('{account_id}')) {
        expect(request.url.path, contains(testAccountId));
      }
      expect(
        request.headers.containsKey('Idempotency-Key'),
        op.idempotent,
        reason: 'Idempotency-Key header',
      );
    });
  }
}
