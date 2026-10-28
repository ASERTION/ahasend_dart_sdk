// Shows that users can replace the client with fakes or mocks in their own
// tests: AhaSendClient and the resources are interface classes.
import 'package:ahasend/ahasend.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

class FakeMessages() extends Fake implements MessagesResource {
  final List<CreateMessageRequest> sent = [];

  @override
  Future<CreateMessageResponse> create(
    CreateMessageRequest request, {
    RequestOptions? options,
  }) async {
    sent.add(request);
    return const CreateMessageResponse(data: []);
  }
}

class FakeClient() extends Fake implements AhaSendClient {
  @override
  final FakeMessages messages = FakeMessages();
}

/// Code under test that depends on the client.
Future<void> sendWelcome(AhaSendClient client, String email) async {
  await client.messages.create(
    CreateMessageRequest(
      from: const Address(email: 'hello@example.com'),
      recipients: [Recipient(email: email)],
      subject: 'Welcome',
      textContent: 'Hi!',
    ),
  );
}

void main() {
  test('application code can be tested with a fake client', () async {
    final client = FakeClient();
    await sendWelcome(client, 'ada@example.org');
    expect(
      client.messages.sent.single.recipients.single.email,
      'ada@example.org',
    );
  });
}
