import 'package:ahasend/ahasend.dart';
import 'package:test/test.dart';

import 'helpers.dart';

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
}
