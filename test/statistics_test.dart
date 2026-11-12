import 'package:ahasend/ahasend.dart';
import 'package:test/test.dart';

import 'helpers.dart';

Map<String, Object?> counts({int reception = 100, int delivered = 95}) => {
  'reception_count': reception,
  'delivered_count': delivered,
  'bounced_count': 3,
  'suppressed_count': 1,
  'complained_count': 1,
  'deferred_count': 4,
  'opened_count': 40,
  'clicked_count': 10,
};

Map<String, Object?> emailStatisticsJson({
  String? breakdown,
  List<Map<String, Object?>> data = const [],
  Map<String, Object?> pagination = const {'has_more': false},
}) => {
  'object': 'email_statistics',
  'from_time': '2026-08-01T00:00:00Z',
  'to_time': '2026-11-01T00:00:00Z',
  'group_by': 'month',
  'breakdown': breakdown,
  'totals': counts(reception: 300, delivered: 290),
  'data': data,
  'pagination': pagination,
};

Map<String, Object?> emailRow(String from, String to, {String? domain}) => {
  'from_timestamp': from,
  'to_timestamp': to,
  'sender_domain': domain,
  ...counts(),
};

void main() {
  test(
    'statistics.deliverability sends filters and decodes the list',
    () async {
      final api = FakeApi([
        FakeResponse(200, {
          'object': 'list',
          'data': [
            {
              'from_timestamp': '2024-05-01T00:00:00Z',
              'to_timestamp': '2024-05-02T00:00:00Z',
              'reception_count': 100,
              'delivered_count': 95,
              'deferred_count': 2,
              'bounced_count': 3,
              'failed_count': 0,
              'suppressed_count': 1,
              'opened_count': 40,
              'clicked_count': 10.0,
            },
          ],
        }),
      ]);
      final stats = await api.client().statistics.deliverability(
        fromTime: DateTime.utc(2024, 5, 1),
        toTime: DateTime.utc(2024, 5, 8),
        senderDomains: ['a.com', 'b.com'],
        recipientDomains: ['gmail.com', 'googlemail.com'],
        tags: ['welcome'],
        groupBy: StatisticsGroupBy.hour,
      );
      expect(api.last.method, 'GET');
      expect(
        api.last.url.path,
        accountPath('/statistics/transactional/deliverability'),
      );
      expect(api.last.url.queryParameters, {
        'from_time': '2024-05-01T00:00:00.000Z',
        'to_time': '2024-05-08T00:00:00.000Z',
        'sender_domain': 'a.com,b.com',
        'recipient_domains': 'gmail.com,googlemail.com',
        'tags': 'welcome',
        'group_by': 'hour',
      });
      final bucket = stats.single;
      expect(bucket.fromTimestamp, DateTime.utc(2024, 5, 1));
      expect(bucket.receptionCount, 100);
      expect(bucket.deliveredCount, 95);
      expect(bucket.clickedCount, 10);
      expect(bucket.toJson()['suppressed_count'], 1);
    },
  );

  test('statistics.bounce decodes classifications', () async {
    final api = FakeApi([
      FakeResponse(200, {
        'object': 'list',
        'data': [
          {
            'from_timestamp': '2024-05-01T00:00:00Z',
            'to_timestamp': '2024-05-02T00:00:00Z',
            'bounces': [
              {'classification': 'InvalidRecipient', 'count': 4},
              {'classification': 'QuotaIssues', 'count': 1},
            ],
          },
        ],
      }),
    ]);
    final stats = await api.client().statistics.bounce();
    expect(api.last.url.path, accountPath('/statistics/transactional/bounce'));
    expect(api.last.url.queryParameters, isEmpty);
    final bounces = stats.single.bounces;
    expect(bounces.map((b) => b.classification), [
      'InvalidRecipient',
      'QuotaIssues',
    ]);
    expect(bounces.first.count, 4);
  });

  test('statistics.deliveryTime decodes doubles', () async {
    final api = FakeApi([
      FakeResponse(200, {
        'object': 'list',
        'data': [
          {
            'from_timestamp': '2024-05-01T00:00:00Z',
            'to_timestamp': '2024-05-02T00:00:00Z',
            'avg_delivery_time': 1,
            'delivered_count': 10,
            'delivery_times': [
              {
                'recipient_domain': 'gmail.com',
                'delivery_time': 0.85,
                'count': 7,
              },
            ],
          },
        ],
      }),
    ]);
    final stats = await api.client().statistics.deliveryTime(
      groupBy: StatisticsGroupBy.month,
    );
    expect(
      api.last.url.path,
      accountPath('/statistics/transactional/delivery-time'),
    );
    expect(api.last.url.queryParameters, {'group_by': 'month'});
    expect(api.last.headers.containsKey('Idempotency-Key'), isFalse);
    final bucket = stats.single;
    expect(bucket.avgDeliveryTime, 1.0);
    expect(bucket.deliveredCount, 10);
    expect(bucket.deliveryTimes.single.recipientDomain, 'gmail.com');
    expect(bucket.deliveryTimes.single.deliveryTime, 0.85);
    expect(bucket.deliveryTimes.single.count, 7);
  });

  test('unknown group_by decodes to unknown', () {
    expect(StatisticsGroupBy('year').isKnown, isFalse);
    expect(StatisticsGroupBy('week'), StatisticsGroupBy.week);
  });

  group('statistics.emails', () {
    test('sends no filters by default and decodes the rows', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          emailStatisticsJson(
            data: [
              emailRow('2026-08-01T00:00:00Z', '2026-09-01T00:00:00Z'),
              emailRow('2026-09-01T00:00:00Z', '2026-10-01T00:00:00Z'),
              emailRow('2026-10-01T00:00:00Z', '2026-11-01T00:00:00Z'),
            ],
          ),
        ),
      ]);
      final stats = await api.client().statistics.emails();
      expect(api.last.method, 'GET');
      expect(api.last.url.path, accountPath('/statistics/emails'));
      expect(api.last.url.queryParameters, isEmpty);
      expect(api.last.headers.containsKey('Idempotency-Key'), isFalse);

      expect(stats.fromTime, DateTime.utc(2026, 8));
      expect(stats.toTime, DateTime.utc(2026, 11));
      expect(stats.groupBy, StatisticsGroupBy.month);
      expect(stats.breakdown, isNull);
      expect(stats.totals.receptionCount, 300);
      expect(stats.totals.deliveredCount, 290);
      expect(stats.totals.complainedCount, 1);
      expect(stats.data, hasLength(3));
      final row = stats.data.first;
      expect(row.fromTimestamp, DateTime.utc(2026, 8));
      expect(row.toTimestamp, DateTime.utc(2026, 9));
      expect(row.senderDomain, isNull);
      expect(row.receptionCount, 100);
      expect(row.deliveredCount, 95);
      expect(row.bouncedCount, 3);
      expect(row.suppressedCount, 1);
      expect(row.complainedCount, 1);
      expect(row.deferredCount, 4);
      expect(row.openedCount, 40);
      expect(row.clickedCount, 10);
      expect(row, isA<EmailStatisticsTotals>());
      expect(stats.hasMore, isFalse);
      expect(await stats.nextPage(), isNull);
      expect(api.requests, hasLength(1));
    });

    test('sends every filter', () async {
      final api = FakeApi([FakeResponse(200, emailStatisticsJson())]);
      await api.client().statistics.emails(
        fromTime: DateTime.utc(2026, 8),
        toTime: DateTime.utc(2026, 11),
        groupBy: StatisticsGroupBy.month,
        senderDomains: ['example.com', 'example.org'],
        breakdown: EmailStatisticsBreakdown.domain,
        limit: 10,
        after: 'c1',
      );
      expect(api.last.url.queryParameters, {
        'from_time': '2026-08-01T00:00:00.000Z',
        'to_time': '2026-11-01T00:00:00.000Z',
        'group_by': 'month',
        'sender_domain': 'example.com,example.org',
        'breakdown': 'domain',
        'limit': '10',
        'after': 'c1',
      });
    });

    test('pages a breakdown by domain and keeps the filters', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          emailStatisticsJson(
            breakdown: 'domain',
            data: [
              emailRow(
                '2026-08-01T00:00:00Z',
                '2026-09-01T00:00:00Z',
                domain: 'a.example.com',
              ),
            ],
            pagination: {'has_more': true, 'next_cursor': 'c2'},
          ),
        ),
        FakeResponse(
          200,
          emailStatisticsJson(
            breakdown: 'domain',
            data: [
              emailRow(
                '2026-08-01T00:00:00Z',
                '2026-09-01T00:00:00Z',
                domain: 'b.example.com',
              ),
            ],
          ),
        ),
      ]);
      final first = await api.client().statistics.emails(
        groupBy: StatisticsGroupBy.month,
        breakdown: EmailStatisticsBreakdown.domain,
        limit: 1,
      );
      expect(first.breakdown, EmailStatisticsBreakdown.domain);
      expect(first.data.single.senderDomain, 'a.example.com');
      expect(first.hasMore, isTrue);

      final second = await first.nextPage();
      expect(api.requests, hasLength(2));
      expect(api.last.url.queryParameters, {
        'group_by': 'month',
        'breakdown': 'domain',
        'limit': '1',
        'after': 'c2',
      });
      expect(second!.data.single.senderDomain, 'b.example.com');
      expect(second.totals.receptionCount, 300);
      expect(second.hasMore, isFalse);
      expect(await second.nextPage(), isNull);
    });

    test('encodes the response as JSON', () async {
      final json = emailStatisticsJson(
        breakdown: 'domain',
        data: [
          emailRow(
            '2026-08-01T00:00:00Z',
            '2026-09-01T00:00:00Z',
            domain: 'example.com',
          ),
        ],
      );
      final api = FakeApi([FakeResponse(200, json)]);
      final stats = await api.client().statistics.emails();
      expect(stats.toJson(), {
        ...json,
        'from_time': '2026-08-01T00:00:00.000Z',
        'to_time': '2026-11-01T00:00:00.000Z',
        'data': [
          {
            ...emailRow(
              '2026-08-01T00:00:00.000Z',
              '2026-09-01T00:00:00.000Z',
              domain: 'example.com',
            ),
          },
        ],
      });
      expect(stats.raw, json);
    });

    test('defaults missing counters to 0', () async {
      final api = FakeApi([
        FakeResponse(200, {
          ...emailStatisticsJson(),
          'totals': {'reception_count': 5},
        }),
      ]);
      final stats = await api.client().statistics.emails();
      expect(stats.totals.receptionCount, 5);
      expect(stats.totals.complainedCount, 0);
    });

    test('keeps unknown breakdown values', () {
      expect(EmailStatisticsBreakdown('tag').isKnown, isFalse);
      expect(
        EmailStatisticsBreakdown('domain'),
        EmailStatisticsBreakdown.domain,
      );
    });
  });
}
