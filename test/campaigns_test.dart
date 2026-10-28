import 'package:ahasend/ahasend.dart';
import 'package:test/test.dart';

import 'helpers.dart';

const campaignId = '00000000-0000-4000-8000-000000000020';
const listId = '00000000-0000-4000-8000-000000000010';

Map<String, Object?> listItemJson({String id = campaignId}) => {
  'object': 'campaign',
  'id': id,
  'created_at': '2025-10-01T09:00:00Z',
  'updated_at': '2025-10-02T09:00:00Z',
  'name': 'October newsletter',
  'subject': 'What is new in October',
  'preheader': null,
  'from': {'email': 'news@example.com', 'name': 'Example'},
  'reply_to': null,
  'status': 'draft',
  'status_reason': null,
  'send_at': null,
  'send_resumes_at': null,
  'finished_at': null,
};

Map<String, Object?> campaignJson() => {
  ...listItemJson(),
  'list_ids': [listId],
  'editor': 'advanced',
  'content': {
    'mjml': '<mjml></mjml>',
    'html': '<html></html>',
    'text_is_custom': false,
  },
  'ready': false,
  'issues': [
    {
      'code': 'preheader_missing',
      'message': 'Add a preview text before you send the campaign.',
    },
  ],
};

void main() {
  group('campaigns.list', () {
    test('sends the status filter and decodes list items', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          pageBody([listItemJson()], hasMore: true, nextCursor: 'c2'),
        ),
      ]);
      final page = await api.client().campaigns.list(
        status: CampaignStatus.waitingForReview,
        limit: 20,
      );
      expect(api.last.method, 'GET');
      expect(api.last.url.path, accountPath('/campaigns'));
      expect(api.last.url.queryParameters, {
        'status': 'waiting_for_review',
        'limit': '20',
      });
      final item = page.data.single;
      expect(item, isNot(isA<Campaign>()));
      expect(item.status, CampaignStatus.draft);
      expect(item.subject, 'What is new in October');
      expect(item.preheader, isNull);
      expect(item.from!.name, 'Example');
      expect(item.sendAt, isNull);
    });

    test('listAll follows cursors and keeps filters', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          pageBody([listItemJson(id: '1')], hasMore: true, nextCursor: 'c2'),
        ),
        FakeResponse(200, pageBody([listItemJson(id: '2')])),
      ]);
      final ids = await api
          .client()
          .campaigns
          .listAll(status: CampaignStatus.sent)
          .map((c) => c.id)
          .toList();
      expect(ids, ['1', '2']);
      expect(api.requests[1].url.queryParameters, {
        'status': 'sent',
        'after': 'c2',
      });
    });
  });

  test('campaigns.create posts with an idempotency key', () async {
    final api = FakeApi([FakeResponse(201, campaignJson())]);
    final campaign = await api.client().campaigns.create(
      const CreateCampaignRequest(
        name: 'October newsletter',
        subject: 'What is new in October',
        preheader: 'Three things we shipped this month',
        from: TemplateAddressInput(email: 'news@example.com', name: 'Example'),
        replyTo: 'support@example.com',
        listIds: [listId],
        templateId: '00000000-0000-4000-8000-000000000013',
      ),
    );
    expect(api.last.method, 'POST');
    expect(api.last.url.path, accountPath('/campaigns'));
    expect(api.last.headers['Idempotency-Key'], isNotEmpty);
    expect(api.lastJson, {
      'name': 'October newsletter',
      'subject': 'What is new in October',
      'preheader': 'Three things we shipped this month',
      'from': {'email': 'news@example.com', 'name': 'Example'},
      'reply_to': 'support@example.com',
      'list_ids': [listId],
      'template_id': '00000000-0000-4000-8000-000000000013',
    });
    expect(campaign.listIds, [listId]);
    expect(campaign.editor, TemplateEditor.advanced);
    expect(campaign.ready, isFalse);
    expect(campaign.issues!.single.code, CampaignIssueCode.preheaderMissing);
    expect(campaign.content!.mjml, '<mjml></mjml>');
  });

  test(
    'campaigns.get decodes a sent campaign with null draft fields',
    () async {
      final api = FakeApi([
        FakeResponse(200, {
          ...campaignJson(),
          'status': 'sent',
          'send_at': '2025-10-05T08:00:00Z',
          'finished_at': '2025-10-05T08:30:00Z',
          'ready': null,
          'issues': null,
          'editor': null,
          'content': null,
        }),
      ]);
      final campaign = await api.client().campaigns.get(campaignId);
      expect(api.last.method, 'GET');
      expect(api.last.url.path, accountPath('/campaigns/$campaignId'));
      expect(api.last.headers.containsKey('Idempotency-Key'), isFalse);
      expect(campaign.status, CampaignStatus.sent);
      expect(campaign.sendAt, DateTime.utc(2025, 10, 5, 8));
      expect(campaign.ready, isNull);
      expect(campaign.issues, isNull);
      expect(campaign.editor, isNull);
      expect(campaign.toJson()['status'], 'sent');
    },
  );

  group('campaigns.update', () {
    test('sends PUT with patches', () async {
      final api = FakeApi([FakeResponse(200, campaignJson())]);
      await api.client().campaigns.update(
        campaignId,
        UpdateCampaignRequest(
          name: 'Renamed',
          subject: Patch.set('New subject'),
          preheader: const Patch.clear(),
          from: const Patch.clear(),
          replyTo: const Patch.clear(),
          listIds: const [listId],
          content: const TemplateContentInput(html: '<p>Hi</p>'),
        ),
      );
      expect(api.last.method, 'PUT');
      expect(api.last.url.path, accountPath('/campaigns/$campaignId'));
      expect(api.last.headers['Idempotency-Key'], isNotEmpty);
      expect(api.lastJson, {
        'name': 'Renamed',
        'subject': 'New subject',
        'preheader': null,
        'from': null,
        'reply_to': null,
        'list_ids': [listId],
        'content': {'html': '<p>Hi</p>'},
      });
    });

    test('sets from and reply-to', () {
      expect(
        const UpdateCampaignRequest(
          from: Patch.set(TemplateAddressInput(email: 'a@example.com')),
          replyTo: Patch.set('r@example.com'),
        ).toJson(),
        {
          'from': {'email': 'a@example.com'},
          'reply_to': 'r@example.com',
        },
      );
      expect(const UpdateCampaignRequest().toJson(), isEmpty);
    });
  });

  test('campaigns.delete sends DELETE', () async {
    final api = FakeApi();
    final result = await api.client().campaigns.delete(campaignId);
    expect(api.last.method, 'DELETE');
    expect(api.last.url.path, accountPath('/campaigns/$campaignId'));
    expect(api.last.headers.containsKey('Idempotency-Key'), isFalse);
    expect(result.message, 'ok');
  });

  group('campaigns.duplicate', () {
    test('sends an empty body by default', () async {
      final api = FakeApi([FakeResponse(201, campaignJson())]);
      await api.client().campaigns.duplicate(campaignId);
      expect(api.last.method, 'POST');
      expect(
        api.last.url.path,
        accountPath('/campaigns/$campaignId/duplicate'),
      );
      expect(api.last.headers['Idempotency-Key'], isNotEmpty);
      expect(api.lastJson, <String, Object?>{});
    });

    test('sends the name', () async {
      final api = FakeApi([FakeResponse(201, campaignJson())]);
      await api.client().campaigns.duplicate(
        campaignId,
        request: const DuplicateCampaignRequest(name: 'Copy'),
      );
      expect(api.lastJson, {'name': 'Copy'});
    });
  });

  group('campaigns.send', () {
    test('posts send_at and decodes warnings', () async {
      final api = FakeApi([
        FakeResponse(202, {
          ...campaignJson(),
          'status': 'validating',
          'ready': null,
          'issues': null,
          'send_at': '2030-01-01T12:00:00Z',
          'warnings': ['The account cannot send right now.'],
        }),
      ]);
      final result = await api.client().campaigns.send(
        campaignId,
        request: SendCampaignRequest(sendAt: DateTime.utc(2030, 1, 1, 12)),
      );
      expect(api.last.method, 'POST');
      expect(api.last.url.path, accountPath('/campaigns/$campaignId/send'));
      expect(api.last.headers['Idempotency-Key'], isNotEmpty);
      expect(api.lastJson, {'send_at': '2030-01-01T12:00:00.000Z'});
      expect(result.status, CampaignStatus.validating);
      expect(result.warnings, ['The account cannot send right now.']);
      expect(result.toJson()['warnings'], hasLength(1));
    });

    test('sends now with an empty body', () async {
      final api = FakeApi([
        FakeResponse(202, {...campaignJson(), 'warnings': <String>[]}),
      ]);
      final result = await api.client().campaigns.send(campaignId);
      expect(api.lastJson, <String, Object?>{});
      expect(result.warnings, isEmpty);
    });

    test('a refusal with issues decodes as CampaignNotReady', () async {
      final api = FakeApi([
        FakeResponse(400, {
          'message': 'campaign is not ready to send',
          'issues': [
            {
              'code': 'subject_missing',
              'message': 'Add a subject before you send the campaign.',
            },
            {'code': 'something_new', 'message': 'New'},
          ],
        }),
      ]);
      try {
        await api.client().campaigns.send(campaignId);
        fail('expected an exception');
      } on BadRequestException catch (e) {
        final notReady = CampaignNotReady.fromException(e)!;
        expect(notReady.message, 'campaign is not ready to send');
        expect(notReady.issues!.map((i) => i.code), [
          CampaignIssueCode.subjectMissing,
          CampaignIssueCode('something_new'),
        ]);
      }
    });

    test('other refusals have no issues', () async {
      final api = FakeApi([
        FakeResponse(400, {'message': 'send_at must be in the future'}),
      ]);
      final error = await api
          .client()
          .campaigns
          .send(campaignId)
          .then<Object?>((_) => null, onError: (Object e) => e);
      final notReady = CampaignNotReady.fromException(error!)!;
      expect(notReady.message, 'send_at must be in the future');
      expect(notReady.issues, isNull);
    });

    test('fromException ignores other errors', () {
      expect(CampaignNotReady.fromException(StateError('x')), isNull);
      expect(
        CampaignNotReady.fromException(
          ApiException.fromResponse(
            statusCode: 400,
            body: 'not json',
            headers: const {},
          ),
        ),
        isNull,
      );
    });
  });

  test('campaigns.unschedule posts without a body', () async {
    final api = FakeApi([FakeResponse(200, campaignJson())]);
    final campaign = await api.client().campaigns.unschedule(campaignId);
    expect(api.last.method, 'POST');
    expect(api.last.url.path, accountPath('/campaigns/$campaignId/unschedule'));
    expect(api.last.headers['Idempotency-Key'], isNotEmpty);
    expect(api.last.body, isEmpty);
    expect(campaign.status, CampaignStatus.draft);
  });

  test('campaigns.test posts the addresses and decodes the result', () async {
    final api = FakeApi([
      FakeResponse(200, {
        'object': 'campaign_test',
        'sent_to': ['reviewer@example.com'],
        'failed': [
          {'email': 'bad@example.com', 'message': '550 no such user'},
        ],
        'result_unknown': false,
      }),
    ]);
    final result = await api.client().campaigns.test(
      campaignId,
      const TestCampaignRequest(
        to: ['reviewer@example.com', 'Bad <bad@example.com>'],
      ),
    );
    expect(api.last.method, 'POST');
    expect(api.last.url.path, accountPath('/campaigns/$campaignId/test'));
    expect(api.last.headers['Idempotency-Key'], isNotEmpty);
    expect(api.lastJson, {
      'to': ['reviewer@example.com', 'Bad <bad@example.com>'],
    });
    expect(result.sentTo, ['reviewer@example.com']);
    expect(result.failed.single.message, '550 no such user');
    expect(result.resultUnknown, isFalse);
  });

  group('campaigns.stats', () {
    test('decodes the report and rates', () async {
      final api = FakeApi([
        FakeResponse(200, {
          'object': 'campaign_stats',
          'campaign_id': campaignId,
          'recipients': 1000,
          'delivered': 980,
          'opens': 600,
          'clicks': 120,
          'unsubscribes': 3,
          'complaints': 1,
          'report': {
            'computed_at': '2025-10-05T10:00:00Z',
            'recipients': 1000,
            'openers': 450,
            'clickers': 90.0,
            'bounces': 20,
            'deferrals': 5,
            'by_status': {'Delivered': 980, 'Bounced': 20},
            'by_bounce_classification': {'Unknown': 2, 'invalid-recipient': 18},
          },
          'rates': {
            'open_rate': 45.92,
            'click_rate': 9.18,
            'bounce_rate': 2,
            'deferral_rate': 0.5,
          },
          'recount_failed': false,
        }),
      ]);
      final stats = await api.client().campaigns.stats(campaignId);
      expect(api.last.method, 'GET');
      expect(api.last.url.path, accountPath('/campaigns/$campaignId/stats'));
      expect(stats.delivered, 980);
      expect(stats.report!.clickers, 90);
      expect(stats.report!.byStatus, {'Delivered': 980, 'Bounced': 20});
      expect(stats.report!.byBounceClassification['invalid-recipient'], 18);
      expect(stats.rates.openRate, 45.92);
      expect(stats.rates.bounceRate, 2.0);
      expect(stats.recountFailed, isFalse);
    });

    test('decodes stats before the first recount', () {
      final stats = CampaignStats.fromJson({
        'object': 'campaign_stats',
        'campaign_id': campaignId,
        'recipients': 0,
        'delivered': 0,
        'opens': 0,
        'clicks': 0,
        'unsubscribes': 0,
        'complaints': 0,
        'report': null,
        'rates': {
          'open_rate': null,
          'click_rate': null,
          'bounce_rate': null,
          'deferral_rate': null,
        },
        'recount_failed': true,
      });
      expect(stats.report, isNull);
      expect(stats.rates.openRate, isNull);
      expect(stats.recountFailed, isTrue);
    });
  });

  group('campaigns.listRecipients', () {
    Map<String, Object?> recipientJson(String contactId) => {
      'object': 'campaign_recipient',
      'contact_id': contactId,
      'email': 'ann@example.com',
      'list_name': 'Customers',
      'status': 'Bounced',
      'bounce_classification': 'invalid-recipient',
      'bounce_reason': 'mailbox does not exist',
      'bounce_message': '550 5.1.1 user unknown',
      'attempts': 1,
      'created_at': '2025-10-05T08:00:00Z',
      'updated_at': '2025-10-05T08:01:00Z',
    };

    test('sends filters and decodes recipients', () async {
      final api = FakeApi([
        FakeResponse(200, pageBody([recipientJson('c-1')])),
      ]);
      final page = await api.client().campaigns.listRecipients(
        campaignId,
        status: 'Administratively Bounced',
        limit: 50,
      );
      expect(api.last.method, 'GET');
      expect(
        api.last.url.path,
        accountPath('/campaigns/$campaignId/recipients'),
      );
      expect(api.last.url.queryParameters, {
        'status': 'Administratively Bounced',
        'limit': '50',
      });
      final recipient = page.data.single;
      expect(recipient.contactId, 'c-1');
      expect(recipient.bounceClassification, 'invalid-recipient');
      expect(recipient.attempts, 1);
      expect(recipient.updatedAt, DateTime.utc(2025, 10, 5, 8, 1));
    });

    test('listAllRecipients follows cursors and keeps filters', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          pageBody([recipientJson('2')], hasMore: true, nextCursor: 'c2'),
        ),
        FakeResponse(200, pageBody([recipientJson('1')])),
      ]);
      final ids = await api
          .client()
          .campaigns
          .listAllRecipients(
            campaignId,
            bounceClassification: 'invalid-recipient',
          )
          .map((r) => r.contactId)
          .toList();
      expect(ids, ['2', '1']);
      expect(api.requests[1].url.queryParameters, {
        'bounce_classification': 'invalid-recipient',
        'after': 'c2',
      });
    });
  });

  test('unknown enum values are kept', () {
    expect(CampaignStatus('archived').isKnown, isFalse);
    expect(CampaignIssueCode('new').isKnown, isFalse);
  });
}
