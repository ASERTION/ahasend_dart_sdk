import 'dart:convert';

import 'package:ahasend/webhooks.dart';
import 'package:test/test.dart';

const webhookId = 'abe11757-2886-4b55-96f1-0e0afc95795a';
const accountId = '4cdd7bdd-294e-4762-892f-83d40abf5a87';

Map<String, Object?> messagePayload(
  String type,
  String event, {
  Map<String, Object?> extra = const {},
}) => {
  'type': type,
  'webhook_id': webhookId,
  'timestamp': '2024-05-06T09:49:16.687031577Z',
  'data': {
    'account_id': accountId,
    'event': event,
    'from': 'sender@example.com',
    'recipient': 'recipient@example.com',
    'subject': 'Welcome to our service',
    'message_id_header': '<message-id-12345@localhost>',
    'id': '0192f5a4-7b1c-7d3e-9a2b-4c5d6e7f8a9b',
    ...extra,
  },
};

WebhookEvent parse(Map<String, Object?> payload) =>
    WebhookEvent.parse(jsonEncode(payload));

void main() {
  group('message events', () {
    final cases = <String, (String, Matcher)>{
      'message.reception': ('on_reception', isA<MessageReceptionEvent>()),
      'message.delivered': ('on_delivered', isA<MessageDeliveredEvent>()),
      'message.transient_error': (
        'on_transient_error',
        isA<MessageTransientErrorEvent>(),
      ),
      'message.failed': ('on_failed', isA<MessageFailedEvent>()),
      'message.bounced': ('on_bounced', isA<MessageBouncedEvent>()),
      'message.suppressed': ('on_suppressed', isA<MessageSuppressedEvent>()),
      'message.opened': ('on_opened', isA<MessageOpenedEvent>()),
    };
    cases.forEach((type, c) {
      test('$type decodes to its class', () {
        final event = parse(messagePayload(type, c.$1));
        expect(event, c.$2);
        expect(event, isA<MessageWebhookEvent>());
        expect(event.type, type);
        final message = event as MessageWebhookEvent;
        expect(message.webhookId, webhookId);
        expect(message.data.accountId, accountId);
        expect(message.data.event.value, c.$1);
        expect(message.data.recipient, 'recipient@example.com');
        expect(message.data.messageIdHeader, '<message-id-12345@localhost>');
        expect(message.data.id, '0192f5a4-7b1c-7d3e-9a2b-4c5d6e7f8a9b');
        expect(message.data.deliveryAttempt, isNull);
        expect(message.data.isBot, isNull);
      });
    });

    test('old 32-character IDs from before 9 November 2026 still decode', () {
      final event = parse(
        messagePayload(
          'message.delivered',
          'on_delivered',
          extra: {'id': '407926766d2711f09b30960002cafe7c'},
        ),
      );
      final message = event as MessageWebhookEvent;
      expect(message.data.id, '407926766d2711f09b30960002cafe7c');
      expect(message.data.messageIdHeader, '<message-id-12345@localhost>');
    });

    test('timestamps with nanoseconds are parsed', () {
      final event = parse(messagePayload('message.reception', 'on_reception'));
      expect(event.timestamp, DateTime.utc(2024, 5, 6, 9, 49, 16, 687, 31));
    });

    test('message.delivered carries its delivery attempt', () {
      final event = parse(
        messagePayload(
          'message.delivered',
          'on_delivered',
          extra: {
            'delivery_attempt': {
              'smtp_code': 250,
              'enhanced_status_code': '2.0.0',
              'response': 'OK: queued',
              'command': 'DATA',
            },
          },
        ),
      ) as MessageDeliveredEvent;
      final attempt = event.data.deliveryAttempt!;
      expect(attempt.smtpCode, 250);
      expect(attempt.enhancedStatusCode, '2.0.0');
      expect(attempt.response, 'OK: queued');
      expect(attempt.command, 'DATA');
      expect(attempt.classification, isNull);
      expect(event.data.event, MessageEventTrigger.onDelivered);
    });

    test(
      'message.transient_error and message.bounced carry a classification',
      () {
        final transient = parse(
          messagePayload(
            'message.transient_error',
            'on_transient_error',
            extra: {
              'delivery_attempt': {
                'classification': 'QuotaIssues',
                'smtp_code': 452,
                'enhanced_status_code': '4.2.2',
                'response': "The recipient's inbox is out of storage space",
                'command': 'RCPT TO',
              },
            },
          ),
        ) as MessageTransientErrorEvent;
        expect(transient.data.deliveryAttempt!.classification, 'QuotaIssues');
        expect(transient.data.deliveryAttempt!.smtpCode, 452);

        final bounced = parse(
          messagePayload(
            'message.bounced',
            'on_bounced',
            extra: {
              'delivery_attempt': {
                'classification': 'InvalidRecipient',
                'smtp_code': 550,
                'enhanced_status_code': '5.1.1',
                'response':
                    'The email account that you tried to reach does not exist',
                'command': 'RCPT TO',
              },
            },
          ),
        ) as MessageBouncedEvent;
        expect(
          bounced.data.deliveryAttempt!.classification,
          'InvalidRecipient',
        );
        expect(bounced.data.deliveryAttempt!.enhancedStatusCode, '5.1.1');
      },
    );

    test('an explicit null delivery attempt means none', () {
      final event = parse(
        messagePayload(
          'message.bounced',
          'on_bounced',
          extra: {'delivery_attempt': null},
        ),
      ) as MessageBouncedEvent;
      expect(event.data.deliveryAttempt, isNull);
    });

    test('message.opened carries client details', () {
      final event = parse(
        messagePayload(
          'message.opened',
          'on_opened',
          extra: {
            'user_agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'ip': '192.168.1.100',
            'is_bot': false,
          },
        ),
      ) as MessageOpenedEvent;
      expect(event.data.userAgent, startsWith('Mozilla/5.0'));
      expect(event.data.ip, '192.168.1.100');
      expect(event.data.isBot, isFalse);
    });

    test('an unknown trigger is kept', () {
      final event = parse(
        messagePayload('message.delivered', 'on_teleported'),
      ) as MessageWebhookEvent;
      expect(event.data.event.isKnown, isFalse);
      expect(event.data.toJson()['event'], 'on_teleported');
    });

    test('toJson round-trips the data', () {
      final payload = messagePayload('message.failed', 'on_failed');
      final event = parse(payload);
      final json = event.toJson();
      expect(json['type'], 'message.failed');
      expect(json['webhook_id'], webhookId);
      expect(json['data'], payload['data']);
      expect(event.raw, payload);
    });
  });

  test('message.clicked decodes its own data shape', () {
    final event = parse(
      messagePayload(
        'message.clicked',
        'on_clicked',
        extra: {
          'url': 'https://example.com/landing-page',
          'user_agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'ip': '192.168.1.100',
          'is_bot': false,
        },
      ),
    );
    expect(event, isA<MessageClickedEvent>());
    expect(event, isNot(isA<MessageWebhookEvent>()));
    final clicked = event as MessageClickedEvent;
    expect(clicked.webhookId, webhookId);
    expect(clicked.data.url, 'https://example.com/landing-page');
    expect(clicked.data.ip, '192.168.1.100');
    expect(clicked.data.isBot, isFalse);
    expect(clicked.data.event, MessageEventTrigger.onClicked);
    expect(clicked.toJson()['data'], (clicked.raw['data']! as Map));
  });

  test('suppression.created decodes', () {
    final event = parse({
      'type': 'suppression.created',
      'webhook_id': webhookId,
      'timestamp': '2024-05-06T12:57:06.451529527Z',
      'data': {
        'account_id': accountId,
        'recipient': 'bounced@example.com',
        'created_at': '2024-05-06T12:57:06.451529617Z',
        'expires_at': '2024-06-05T12:57:06.451529617Z',
        'reason': 'Too many hard bounces',
        'sending_domain': 'your-domain.com',
      },
    });
    expect(event, isA<SuppressionCreatedEvent>());
    final data = (event as SuppressionCreatedEvent).data;
    expect(event.webhookId, webhookId);
    expect(data.recipient, 'bounced@example.com');
    expect(data.reason, 'Too many hard bounces');
    expect(data.sendingDomain, 'your-domain.com');
    expect(data.createdAt, DateTime.utc(2024, 5, 6, 12, 57, 6, 451, 529));
    expect(data.expiresAt, DateTime.utc(2024, 6, 5, 12, 57, 6, 451, 529));
  });

  test('domain.dns_error decodes', () {
    final event = parse({
      'type': 'domain.dns_error',
      'webhook_id': webhookId,
      'timestamp': '2024-05-06T12:59:46.404433272Z',
      'data': {
        'domain': 'example.com',
        'account_id': accountId,
        'spf_valid': false,
        'dkim_valid': true,
        'dmarc_valid': false,
        'dns_last_checked_at': '2024-05-06T12:59:46.404433312Z',
      },
    });
    expect(event, isA<DomainDnsErrorEvent>());
    final data = (event as DomainDnsErrorEvent).data;
    expect(data.domain, 'example.com');
    expect(data.spfValid, isFalse);
    expect(data.dkimValid, isTrue);
    expect(data.dmarcValid, isFalse);
    expect(data.dnsLastCheckedAt.year, 2024);
  });

  test('message.routing decodes the inbound message', () {
    final event = parse({
      'type': 'message.routing',
      'route_id': webhookId,
      'timestamp': '2024-05-06T13:15:46.404433272Z',
      'data': {
        'id': 'route-msg-12345',
        'from': 'customer@gmail.com',
        'reply_to': 'customer@gmail.com',
        'to': 'support@yourdomain.com',
        'subject': 'Help with my account',
        'message_id': '<unique-message-id@gmail.com>',
        'size': 2048,
        'spam_score': 0.1,
        'bounce': false,
        'cc': '',
        'date': 'Mon, 06 May 2024 13:15:46 +0000',
        'in_reply_to': '',
        'references': '',
        'auto_submitted': '',
        'html_body': '<p>I need help with my account settings.</p>',
        'plain_body': 'I need help with my account settings.',
        'reply_from_plain_body': 'I need help with my account settings.',
        'attachments': [
          {
            'filename': 'logo.png',
            'content_type': 'image/png',
            'content_id': 'logo-123',
            'disposition': 'inline',
            'data': 'aGVsbG8=',
          },
        ],
        'headers': {'X-Mailer': 'Gmail', 'X-Priority': '3'},
      },
    });
    expect(event, isA<MessageRoutingEvent>());
    final routing = event as MessageRoutingEvent;
    expect(routing.routeId, webhookId);
    final data = routing.data;
    expect(data.id, 'route-msg-12345');
    expect(data.from, 'customer@gmail.com');
    expect(data.to, 'support@yourdomain.com');
    expect(data.size, 2048);
    expect(data.spamScore, 0.1);
    expect(data.bounce, isFalse);
    expect(data.date, 'Mon, 06 May 2024 13:15:46 +0000');
    expect(data.plainBody, 'I need help with my account settings.');
    expect(data.headers, {'X-Mailer': 'Gmail', 'X-Priority': '3'});
    final attachment = data.attachments.single;
    expect(attachment.filename, 'logo.png');
    expect(attachment.contentId, 'logo-123');
    expect(attachment.disposition, 'inline');
    expect(utf8.decode(attachment.decodeData()), 'hello');
    expect(routing.toJson()['route_id'], webhookId);
    expect(routing.toJson()['data'], routing.raw['data']);
  });

  test('message.routing tolerates missing headers', () {
    final event = parse({
      'type': 'message.routing',
      'route_id': webhookId,
      'timestamp': '2024-05-06T13:15:46Z',
      'data': {'id': 'x', 'attachments': <Object>[]},
    }) as MessageRoutingEvent;
    expect(event.data.headers, isNull);
    expect(event.data.attachments, isEmpty);
  });

  group('unknown and invalid payloads', () {
    test('an unknown type decodes to UnknownWebhookEvent', () {
      final payload = {
        'type': 'contact.created',
        'webhook_id': webhookId,
        'timestamp': '2024-05-06T13:15:46Z',
        'data': {'email': 'a@example.com'},
      };
      final event = parse(payload);
      expect(event, isA<UnknownWebhookEvent>());
      expect(event.type, 'contact.created');
      expect(event.data, {'email': 'a@example.com'});
      expect(event.raw, payload);
      expect(event.toJson(), payload);
    });

    test('fromJson works on decoded maps', () {
      final event = WebhookEvent.fromJson(
        messagePayload('message.reception', 'on_reception'),
      );
      expect(event, isA<MessageReceptionEvent>());
    });

    test('invalid JSON throws InvalidPayloadException', () {
      expect(
        () => WebhookEvent.parse('{'),
        throwsA(isA<InvalidPayloadException>()),
      );
    });

    test('a JSON array throws InvalidPayloadException', () {
      expect(
        () => WebhookEvent.parse('[]'),
        throwsA(isA<InvalidPayloadException>()),
      );
    });

    test('a missing type throws InvalidPayloadException', () {
      expect(
        () => WebhookEvent.fromJson({'timestamp': '2024-05-06T13:15:46Z'}),
        throwsA(isA<InvalidPayloadException>()),
      );
    });

    test('a missing timestamp throws InvalidPayloadException', () {
      expect(
        () => WebhookEvent.fromJson({'type': 'message.delivered', 'data': {}}),
        throwsA(
          isA<InvalidPayloadException>().having(
            (e) => e.cause,
            'cause',
            isNotNull,
          ),
        ),
      );
    });

    test('a known type without data throws InvalidPayloadException', () {
      expect(
        () => WebhookEvent.fromJson({
          'type': 'message.delivered',
          'timestamp': '2024-05-06T13:15:46Z',
        }),
        throwsA(isA<InvalidPayloadException>()),
      );
    });
  });

  test('events are handled with a switch and a default branch', () {
    // WebhookEvent is not sealed, so new event types never break a switch.
    String describe(WebhookEvent event) => switch (event) {
      MessageWebhookEvent(:final data) => 'message ${data.event.value}',
      MessageClickedEvent(:final data) => 'click ${data.url}',
      SuppressionCreatedEvent(:final data) => 'suppressed ${data.recipient}',
      DomainDnsErrorEvent(:final data) => 'dns ${data.domain}',
      MessageRoutingEvent(:final data) => 'inbound ${data.subject}',
      _ => 'other ${event.type}',
    };
    expect(
      describe(
        WebhookEvent.fromJson({
          'type': 'message.teleported',
          'timestamp': '2024-05-06T13:15:46Z',
        }),
      ),
      'other message.teleported',
    );
    expect(
      describe(parse(messagePayload('message.opened', 'on_opened'))),
      'message on_opened',
    );
  });
}
