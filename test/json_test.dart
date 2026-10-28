import 'dart:math';

import 'package:ahasend/src/json.dart';
import 'package:test/test.dart';

void main() {
  group('parseRfc3339', () {
    test('matches DateTime.parse for typical API timestamps', () {
      const samples = [
        '2024-01-01T10:00:05Z',
        '2024-01-01 10:00:05Z',
        '2024-02-29T23:59:59.999999Z',
        '2024-02-29T23:59:59.9Z',
        '2024-02-29T23:59:59.123456789Z',
        '2023-12-25T10:30:00+02:00',
        '2023-12-25T00:30:00-05:30',
        '1970-01-01T00:00:00Z',
        '9999-12-31T23:59:59Z',
        // Out-of-range fields are normalized like DateTime.parse does.
        '2024-02-30T00:00:00Z',
        '2016-12-31T23:59:60Z',
      ];
      for (final s in samples) {
        expect(parseRfc3339(s), DateTime.parse(s), reason: s);
        expect(parseRfc3339(s)!.isUtc, isTrue, reason: s);
      }
    });

    test('accepts lowercase t and z, which RFC 3339 allows', () {
      expect(
        parseRfc3339('2024-01-01t10:00:05z'),
        DateTime.utc(2024, 1, 1, 10, 0, 5),
      );
    });

    test('matches DateTime.parse for random timestamps', () {
      final random = Random(42);
      String two(int v) => v.toString().padLeft(2, '0');
      for (var i = 0; i < 20000; i++) {
        final buffer = StringBuffer()
          ..write(random.nextInt(10000).toString().padLeft(4, '0'))
          ..write('-${two(1 + random.nextInt(12))}')
          ..write('-${two(1 + random.nextInt(28))}')
          ..write('T${two(random.nextInt(24))}')
          ..write(':${two(random.nextInt(60))}')
          ..write(':${two(random.nextInt(60))}');
        if (random.nextBool()) {
          buffer.write('.');
          final digits = 1 + random.nextInt(9);
          for (var d = 0; d < digits; d++) {
            buffer.write(random.nextInt(10));
          }
        }
        if (random.nextBool()) {
          buffer.write('Z');
        } else {
          buffer
            ..write(random.nextBool() ? '+' : '-')
            ..write(two(random.nextInt(24)))
            ..write(':${two(random.nextInt(60))}');
        }
        final s = buffer.toString();
        expect(parseRfc3339(s), DateTime.parse(s), reason: s);
      }
    });

    test(
      'returns null for other formats, which decodeDateTime still parses',
      () {
        const others = [
          '2024-01-01T10:00:05',
          '2024-01-01T10:00:05+0200',
          '2024-01-01T10:00Z',
          '2024-01-01',
          '20240101T100005Z',
          '2024-01-01T10:00:05.Z',
        ];
        for (final s in others) {
          expect(parseRfc3339(s), isNull, reason: s);
        }
        expect(
          decodeDateTime('2024-01-01T10:00:05+0200'),
          DateTime.parse('2024-01-01T10:00:05+0200'),
        );
      },
    );

    test('rejects garbage', () {
      for (final s in ['', 'not a date at all!!', '2024-0a-01T10:00:05Z']) {
        expect(parseRfc3339(s), isNull, reason: s);
      }
      expect(() => decodeDateTime('nope'), throwsFormatException);
    });
  });

  group('Patch', () {
    test('set and clear', () {
      expect(const Patch.set(1).value, 1);
      expect(const Patch.set(1).isClear, isFalse);
      expect(const Patch<int>.clear().isClear, isTrue);
      expect(const Patch<int>.clear().value, isNull);
      expect(const Patch.set('a'), const Patch.set('a'));
    });
  });

  test('decodeList returns unmodifiable lists', () {
    final list = decodeList([
      {'a': 1},
    ], (json) => json['a']);
    expect(list, [1]);
    expect(() => list.add(2), throwsUnsupportedError);
    expect(decodeList(null, (json) => 0), isEmpty);
  });
}
