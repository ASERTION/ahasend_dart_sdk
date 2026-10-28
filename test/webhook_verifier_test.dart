import 'dart:convert';

import 'package:ahasend/webhooks.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

const secret = 'aha-whsec-dGVzdHNlY3JldA';
const id = 'msg_2KWPBgLlAfxdpx2AI54pPJ85f4W';
const timestamp = '1715075416';

const body =
    '{"type":"message.delivered",'
    '"webhook_id":"abe11757-2886-4b55-96f1-0e0afc95795a",'
    '"timestamp":"2024-05-06T09:50:16.687031577Z",'
    '"data":{"account_id":"4cdd7bdd-294e-4762-892f-83d40abf5a87",'
    '"event":"on_delivered","from":"sender@example.com",'
    '"recipient":"recipient@example.com","subject":"Welcome über",'
    '"message_id_header":"<message-id-12345@localhost>",'
    '"id":"407926766d2711f09b30960002cafe7c"}}';

// Computed independently with Python:
// base64(hmac.new(secret.encode(), f"{id}.{timestamp}.".encode() +
//   body.encode("utf-8"), sha256).digest())
const expectedSignature = '1YaRokiyWT6zFs8GgL/7Qt321kIZEEfSulftOD0c3zg=';

// The same content signed with the base64-decoded suffix of the secret,
// as a stock Standard Webhooks library would do. AhaSend does not do this.
const decodedKeySignature = 'awUSp8xj7pk6fdiJykjW8eF50j0UM8FOoyLFsfX5l4w=';

final sentAt = DateTime.fromMillisecondsSinceEpoch(
  1715075416 * 1000,
  isUtc: true,
);

WebhookVerifier verifier({
  String key = secret,
  Duration offset = Duration.zero,
  Duration tolerance = const Duration(minutes: 5),
}) =>
    WebhookVerifier(key, tolerance: tolerance, clock: () => sentAt.add(offset));

Map<String, String> headers({String signature = 'v1,$expectedSignature'}) => {
  'webhook-id': id,
  'webhook-timestamp': timestamp,
  'webhook-signature': signature,
};

void main() {
  group('signing', () {
    test('matches the independently computed vector', () {
      expect(
        WebhookVerifier.sign(
          secret: secret,
          id: id,
          timestamp: sentAt,
          body: body,
        ),
        'v1,$expectedSignature',
      );
    });

    test('matches package:crypto over the literal secret bytes', () {
      final mac = Hmac(
        sha256,
        utf8.encode(secret),
      ).convert(utf8.encode('$id.$timestamp.$body'));
      expect(base64.encode(mac.bytes), expectedSignature);
    });

    test('verifies bytes and strings the same way', () {
      verifier().verifySignatureBytes(
        body: utf8.encode(body),
        headers: headers(),
      );
    });

    test('signedHeaders builds headers that verify', () {
      final now = DateTime.now();
      final signed = WebhookVerifier.signedHeaders(
        secret: 'aha-rsec-route',
        id: 'evt-1',
        timestamp: now,
        body: body,
      );
      expect(signed['webhook-id'], 'evt-1');
      expect(
        signed['webhook-timestamp'],
        '${now.millisecondsSinceEpoch ~/ 1000}',
      );
      expect(signed['webhook-signature'], startsWith('v1,'));
      final event = WebhookVerifier('aha-rsec-route')
          .verify(body: body, headers: signed);
      expect(event, isA<MessageDeliveredEvent>());
    });

    test('rejects an empty secret', () {
      expect(() => WebhookVerifier(''), throwsArgumentError);
    });
  });

  group('verify', () {
    test('accepts a valid delivery and parses it', () {
      final event = verifier().verify(body: body, headers: headers());
      expect(event, isA<MessageDeliveredEvent>());
      expect((event as MessageDeliveredEvent).data.subject, 'Welcome über');
    });

    test('accepts the body as bytes', () {
      final event = verifier().verifyBytes(
        body: utf8.encode(body),
        headers: headers(),
      );
      expect(event.type, 'message.delivered');
    });

    test('accepts signatures joined with commas', () {
      // Some frameworks join repeated headers with ", " or ",".
      for (final joined in [
        'v1,bm90IHRoZSByaWdodCBvbmU=,v1,$expectedSignature',
        'v1,bm90IHRoZSByaWdodCBvbmU=, v1,$expectedSignature',
      ]) {
        verifier().verifySignature(
          body: body,
          headers: headers(signature: joined),
        );
      }
    });

    test('resolves header names case-insensitively', () {
      final event = verifier().verify(
        body: body,
        headers: {
          'Webhook-Id': id,
          'WEBHOOK-TIMESTAMP': timestamp,
          'Webhook-Signature': 'v1,$expectedSignature',
        },
      );
      expect(event, isA<MessageDeliveredEvent>());
    });

    test('accepts any matching signature in a list', () {
      verifier().verifySignature(
        body: body,
        headers: headers(
          signature:
              'v1,bm90IHRoZSByaWdodCBvbmU= v2,abc '
              'v1,$expectedSignature',
        ),
      );
    });

    test('accepts timestamps within the tolerance', () {
      verifier(offset: const Duration(minutes: 5))
          .verifySignature(body: body, headers: headers());
      verifier(offset: const Duration(minutes: -5))
          .verifySignature(body: body, headers: headers());
    });
  });

  group('rejects', () {
    void expectThrows<T>(void Function() fn) => expect(
      fn,
      throwsA(isA<T>().having((e) => e, 'is base', isA<WebhookException>())),
    );

    test('a wrong signature', () {
      expectThrows<InvalidSignatureException>(
        () => verifier().verify(
          body: body,
          headers: headers(signature: 'v1,bm90IHRoZSByaWdodCBvbmU='),
        ),
      );
    });

    test('a tampered body', () {
      expectThrows<InvalidSignatureException>(
        () => verifier().verify(
          body: body.replaceFirst('über', 'uber'),
          headers: headers(),
        ),
      );
    });

    test('a tampered id', () {
      expectThrows<InvalidSignatureException>(
        () => verifier().verify(
          body: body,
          headers: {...headers(), 'webhook-id': 'msg_other'},
        ),
      );
    });

    test('a wrong secret', () {
      expectThrows<InvalidSignatureException>(
        () =>
            verifier(key: 'aha-whsec-other')
                .verify(body: body, headers: headers()),
      );
    });

    test('a signature made with the base64-decoded secret', () {
      expectThrows<InvalidSignatureException>(
        () => verifier().verify(
          body: body,
          headers: headers(signature: 'v1,$decodedKeySignature'),
        ),
      );
    });

    test('a signature with another version prefix', () {
      expectThrows<InvalidSignatureException>(
        () => verifier().verify(
          body: body,
          headers: headers(signature: 'v2,$expectedSignature'),
        ),
      );
    });

    test('a signature without a version prefix', () {
      expectThrows<InvalidSignatureException>(
        () => verifier().verify(
          body: body,
          headers: headers(signature: expectedSignature),
        ),
      );
    });

    test('an expired timestamp', () {
      expect(
        () =>
            verifier(offset: const Duration(minutes: 5, seconds: 1))
                .verify(body: body, headers: headers()),
        throwsA(
          isA<TimestampOutOfToleranceException>()
              .having((e) => e.timestamp, 'timestamp', sentAt)
              .having(
                (e) => e.tolerance,
                'tolerance',
                const Duration(minutes: 5),
              ),
        ),
      );
    });

    test('a timestamp in the future', () {
      expectThrows<TimestampOutOfToleranceException>(
        () =>
            verifier(offset: const Duration(minutes: -6))
                .verify(body: body, headers: headers()),
      );
    });

    test('with a custom tolerance', () {
      expectThrows<TimestampOutOfToleranceException>(
        () => verifier(
          tolerance: const Duration(seconds: 10),
          offset: const Duration(seconds: 11),
        ).verify(body: body, headers: headers()),
      );
    });

    test('a malformed timestamp', () {
      expectThrows<InvalidSignatureException>(
        () => verifier().verify(
          body: body,
          headers: {...headers(), 'webhook-timestamp': '2024-05-06'},
        ),
      );
    });

    for (final name in [
      'webhook-id',
      'webhook-timestamp',
      'webhook-signature',
    ]) {
      test('a missing $name header', () {
        final h = headers()..remove(name);
        expect(
          () => verifier().verify(body: body, headers: h),
          throwsA(
            isA<MissingHeaderException>().having(
              (e) => e.header,
              'header',
              name,
            ),
          ),
        );
      });

      test('an empty $name header', () {
        expectThrows<MissingHeaderException>(
          () =>
              verifier().verify(body: body, headers: {...headers(), name: ' '}),
        );
      });
    }

    test('a signed body that is not JSON', () {
      const text = 'not json';
      final signed = WebhookVerifier.signedHeaders(
        secret: secret,
        id: id,
        timestamp: sentAt,
        body: text,
      );
      expectThrows<InvalidPayloadException>(
        () => verifier().verify(body: text, headers: signed),
      );
    });

    test('signed bytes that are not UTF-8', () {
      const bytes = [0xff, 0xfe];
      final timestamp = (sentAt.millisecondsSinceEpoch ~/ 1000).toString();
      final mac = Hmac(
        sha256,
        utf8.encode(secret),
      ).convert([...utf8.encode('$id.$timestamp.'), ...bytes]);
      final signed = {
        'webhook-id': id,
        'webhook-timestamp': timestamp,
        'webhook-signature': 'v1,${base64.encode(mac.bytes)}',
      };
      expectThrows<InvalidPayloadException>(
        () => verifier().verifyBytes(body: bytes, headers: signed),
      );
    });

    test('a payload error is not a verification error', () {
      // The signature was valid, so the handler must not answer 4xx.
      final signed = WebhookVerifier.signedHeaders(
        secret: secret,
        id: id,
        timestamp: sentAt,
        body: 'not json',
      );
      expect(
        () => verifier().verify(body: 'not json', headers: signed),
        throwsA(
          isA<InvalidPayloadException>().having(
            (e) => e,
            'verification error',
            isNot(isA<WebhookVerificationException>()),
          ),
        ),
      );
    });

    test('exceptions name their class in toString', () {
      expect(
        const InvalidSignatureException().toString(),
        startsWith('InvalidSignatureException: '),
      );
      expect(
        const InvalidPayloadException('x').toString(),
        'InvalidPayloadException: x',
      );
    });
  });
}
