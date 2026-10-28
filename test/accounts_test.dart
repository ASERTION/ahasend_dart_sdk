import 'package:ahasend/ahasend.dart';
import 'package:test/test.dart';

import 'helpers.dart';

Map<String, Object?> accountJson() => {
  'object': 'account',
  'id': testAccountId,
  'parent_account_id': null,
  'created_at': '2024-01-01T00:00:00Z',
  'updated_at': '2024-01-02T00:00:00Z',
  'name': 'Acme',
  'website': 'acme.com',
  'about': 'We send receipts.',
  'track_opens': true,
  'track_clicks': false,
  'reject_bad_recipients': true,
  'reject_mistyped_recipients': false,
  'message_metadata_retention': 30,
  'message_data_retention': 7.0,
  'owner_id': 'u-1',
};

Map<String, Object?> memberJson({String role = 'Billing Manager'}) => {
  'created_at': '2024-01-01T00:00:00Z',
  'updated_at': '2024-01-01T00:00:00Z',
  'user_id': 'u-2',
  'account_id': testAccountId,
  'role': role,
};

void main() {
  test('accounts.get decodes the account', () async {
    final api = FakeApi([FakeResponse(200, accountJson())]);
    final account = await api.client().accounts.get();
    expect(api.last.method, 'GET');
    expect(api.last.url.path, accountPath(''));
    expect(account.name, 'Acme');
    expect(account.parentAccountId, isNull);
    expect(account.trackOpens, isTrue);
    expect(account.messageDataRetention, 7);
    expect(account.ownerId, 'u-1');
    expect(account.toJson()['object'], 'account');
  });

  test('accounts.update sends PUT with only set fields', () async {
    final api = FakeApi([FakeResponse(200, accountJson())]);
    await api.client().accounts.update(
      const UpdateAccountRequest(
        name: 'Updated Company Name',
        website: 'https://example.com',
        trackOpens: true,
        messageDataRetention: 0,
      ),
    );
    expect(api.last.method, 'PUT');
    expect(api.last.url.path, accountPath(''));
    expect(api.last.headers['Idempotency-Key'], isNull);
    expect(api.lastJson, {
      'name': 'Updated Company Name',
      'website': 'https://example.com',
      'track_opens': true,
      'message_data_retention': 0,
    });
  });

  test('accounts.listMembers decodes the list', () async {
    final api = FakeApi([
      FakeResponse(200, {
        'object': 'list',
        'data': [memberJson()],
      }),
    ]);
    final members = await api.client().accounts.listMembers();
    expect(api.last.method, 'GET');
    expect(api.last.url.path, accountPath('/members'));
    expect(members.single.role, AccountMemberRole.billingManager);
    expect(members.single.userId, 'u-2');
  });

  test('accounts.addMember is idempotent', () async {
    final api = FakeApi([FakeResponse(201, memberJson(role: 'Developer'))]);
    final member = await api.client().accounts.addMember(
      const AddMemberRequest(
        email: 'user@example.com',
        name: 'John Doe',
        role: AccountMemberRole.billingManager,
      ),
    );
    expect(api.last.method, 'POST');
    expect(api.last.url.path, accountPath('/members'));
    expect(api.last.headers['Idempotency-Key'], isNotEmpty);
    expect(api.lastJson, {
      'email': 'user@example.com',
      'name': 'John Doe',
      'role': 'Billing Manager',
    });
    expect(member.role, AccountMemberRole.developer);
  });

  test('accounts.removeMember sends DELETE', () async {
    final api = FakeApi();
    final result = await api.client().accounts.removeMember('u-2');
    expect(api.last.method, 'DELETE');
    expect(api.last.url.path, accountPath('/members/u-2'));
    expect(api.last.headers['Idempotency-Key'], isNull);
    expect(result.message, 'ok');
  });

  test('unknown roles decode to unknown', () {
    expect(AccountMemberRole('Owner').isKnown, isFalse);
  });
}
