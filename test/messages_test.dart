import 'package:ahasend/ahasend.dart';
import 'package:test/test.dart';

import 'helpers.dart';

Map<String, Object?> summaryJson({String id = 'm-1'}) => {
  'object': 'message',
  'created_at': '2024-01-01T10:00:00Z',
  'updated_at': '2024-01-01T10:00:05Z',
  'sent_at': '2024-01-01T10:00:01Z',
  'delivered_at': null,
  'retain_until': '2024-01-31T10:00:00Z',
  'direction': 'outbound',
  'is_bounce_notification': false,
  'bounce_classification': '',
  'delivery_attempts': [
    {'time': '2024-01-01T10:00:02Z', 'log': '250 OK', 'status': 'Delivered'},
  ],
  'message_id': '<$id@example.com>',
  'id': id,
  'subject': 'Hi',
  'tags': ['welcome'],
  'sender': 'a@example.com',
  'recipient': 'b@example.com',
  'status': 'Delivered',
  'num_attempts': 1,
  'click_count': 0,
  'open_count': 2,
  'reference_message_id': null,
  'domain_id': 'd-1',
  'account_id': testAccountId,
  'template_id': null,
};

void main() {
  group('messages.create', () {
    test('posts the request and decodes the response', () async {
      final api = FakeApi([
        FakeResponse(202, {
          'object': 'list',
          'data': [
            {
              'object': 'message',
              'id': '<abc@example.com>',
              'recipient': {'email': 'b@example.com', 'name': 'B'},
              'status': 'queued',
              'error': null,
            },
          ],
        }),
      ]);
      final response = await api.client().messages.create(
        CreateMessageRequest(
          from: const Address(email: 'a@example.com', name: 'A'),
          recipients: const [
            Recipient(email: 'b@example.com', substitutions: {'x': 1}),
          ],
          subject: 'Hello',
          htmlContent: '<p>Hi</p>',
          tags: const ['t'],
          sandbox: true,
          sandboxResult: SandboxResult.bounce,
          tracking: const Tracking(open: true),
          schedule: MessageSchedule(firstAttempt: DateTime.utc(2030, 1, 1, 12)),
        ),
      );

      expect(api.last.method, 'POST');
      expect(api.last.url.path, accountPath('/messages'));
      expect(api.last.headers['Content-Type'], startsWith('application/json'));
      expect(api.last.headers['Idempotency-Key'], isNotEmpty);
      expect(api.lastJson, {
        'from': {'email': 'a@example.com', 'name': 'A'},
        'recipients': [
          {
            'email': 'b@example.com',
            'substitutions': {'x': 1},
          },
        ],
        'subject': 'Hello',
        'html_content': '<p>Hi</p>',
        'tags': ['t'],
        'sandbox': true,
        'sandbox_result': 'bounce',
        'tracking': {'open': true},
        'schedule': {'first_attempt': '2030-01-01T12:00:00.000Z'},
      });

      final created = response.data.single;
      expect(created.id, '<abc@example.com>');
      expect(created.status, CreatedMessageStatus.queued);
      expect(created.recipient.name, 'B');
    });

    test('template and conversation sends use their own paths', () async {
      final api = FakeApi([
        FakeResponse(202, {'object': 'list', 'data': <Object>[]}),
      ]);
      final client = api.client();
      await client.messages.createFromTemplate(
        const CreateTemplateMessageRequest(
          templateId: 'tpl-1',
          recipients: [Recipient(email: 'b@example.com')],
        ),
      );
      expect(api.last.url.path, accountPath('/messages/template'));
      expect(api.lastJson, {
        'template_id': 'tpl-1',
        'recipients': [
          {'email': 'b@example.com'},
        ],
      });

      await client.messages.createConversation(
        const CreateConversationMessageRequest(
          from: Address(email: 'a@example.com'),
          to: [Address(email: 'b@example.com')],
          cc: [Address(email: 'c@example.com')],
          subject: 'Hi',
          textContent: 'Hi',
        ),
      );
      expect(api.last.url.path, accountPath('/messages/conversation'));
      expect((api.lastJson! as Map)['cc'], [
        {'email': 'c@example.com'},
      ]);
    });

    test('unknown enum values are kept', () {
      expect(CreatedMessageStatus('new').isKnown, isFalse);
    });
  });

  group('messages.list', () {
    test('sends filters and decodes the page', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          pageBody([summaryJson()], hasMore: true, nextCursor: 'c2'),
        ),
      ]);
      final page = await api.client().messages.list(
        status: ['Bounced', 'Failed'],
        tags: ['a', 'b'],
        fromTime: DateTime.utc(2024, 1, 1),
        limit: 10,
      );
      expect(api.last.url.path, accountPath('/messages'));
      expect(api.last.url.queryParameters, {
        'status': 'Bounced,Failed',
        'tags': 'a,b',
        'from_time': '2024-01-01T00:00:00.000Z',
        'limit': '10',
      });
      final message = page.data.single;
      expect(message.status, 'Delivered');
      expect(message.direction, MessageDirection.outbound);
      expect(message.deliveryAttempts.single.log, '250 OK');
      expect(message.openCount, 2);
      expect(page.hasMore, isTrue);
      expect(page.pagination.nextCursor, 'c2');
    });

    test('listAll follows cursors and keeps filters', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          pageBody([summaryJson(id: '1')], hasMore: true, nextCursor: 'c2'),
        ),
        FakeResponse(200, pageBody([summaryJson(id: '2')])),
      ]);
      final ids = await api
          .client()
          .messages
          .listAll(sender: 'a@example.com')
          .map((m) => m.id)
          .toList();
      expect(ids, ['1', '2']);
      expect(api.requests[1].url.queryParameters, {
        'sender': 'a@example.com',
        'after': 'c2',
      });
    });
  });

  test('messages.get encodes the message ID and decodes content', () async {
    final api = FakeApi([
      FakeResponse(200, {
        ...summaryJson(),
        'content': 'raw',
        'content_parsed': {
          'parts': [
            {'content_type': 'text/plain', 'content': 'Hi'},
          ],
          'attachments': <Object>[],
          'headers': {
            'X-A': ['1', '2'],
          },
        },
      }),
    ]);
    final message = await api.client().messages.get('<m-1@example.com>');
    expect(api.last.url.path, accountPath('/messages/%3Cm-1%40example.com%3E'));
    expect(message.content, 'raw');
    expect(message.contentParsed!.headers['X-A'], ['1', '2']);
    expect(message.toJson()['content'], 'raw');
  });

  test('messages.cancel sends DELETE', () async {
    final api = FakeApi();
    final result = await api.client().messages.cancel('m-1');
    expect(api.last.method, 'DELETE');
    expect(api.last.url.path, accountPath('/messages/m-1/cancel'));
    expect(result.message, 'ok');
  });
}
