import 'package:ahasend/ahasend.dart';
import 'package:test/test.dart';

import 'helpers.dart';

Map<String, Object?> credentialJson({
  String id = 'c-1',
  String scope = 'scoped',
}) => {
  'object': 'credential_smtp',
  'id': id,
  'created_at': '2024-01-01T00:00:00Z',
  'updated_at': '2024-01-01T00:00:00Z',
  'name': 'Production SMTP',
  'username': 'smtp-user-1',
  'sandbox': false,
  'scope': scope,
  'domains': ['example.com'],
};

void main() {
  test('smtpCredentials.list decodes credentials', () async {
    final api = FakeApi([
      FakeResponse(200, pageBody([credentialJson()])),
    ]);
    final page = await api.client().smtpCredentials.list(limit: 10);
    expect(api.last.method, 'GET');
    expect(api.last.url.path, accountPath('/smtp-credentials'));
    expect(api.last.url.queryParameters, {'limit': '10'});
    final credential = page.data.single;
    expect(credential.scope, SmtpCredentialScope.scoped);
    expect(credential.domains, ['example.com']);
    expect(credential.sandbox, isFalse);
  });

  test('smtpCredentials.listAll follows cursors', () async {
    final api = FakeApi([
      FakeResponse(
        200,
        pageBody([credentialJson(id: '1')], hasMore: true, nextCursor: 'c2'),
      ),
      FakeResponse(200, pageBody([credentialJson(id: '2')])),
    ]);
    final ids = await api
        .client()
        .smtpCredentials
        .listAll()
        .map((c) => c.id)
        .toList();
    expect(ids, ['1', '2']);
  });

  test('smtpCredentials.create is idempotent and hides the password', () async {
    final api = FakeApi([
      FakeResponse(201, {
        ...credentialJson(scope: 'global'),
        'domains': <String>[],
        'password': 'p4ssw0rd-SECRET',
      }),
    ]);
    final created = await api.client().smtpCredentials.create(
      const CreateSmtpCredentialRequest(
        name: 'Production SMTP',
        scope: SmtpCredentialScope.global,
        sandbox: true,
      ),
    );
    expect(api.last.method, 'POST');
    expect(api.last.url.path, accountPath('/smtp-credentials'));
    expect(api.last.headers['Idempotency-Key'], isNotEmpty);
    expect(api.lastJson, {
      'name': 'Production SMTP',
      'sandbox': true,
      'scope': 'global',
    });
    expect(created.password, 'p4ssw0rd-SECRET');
    expect(created.domains, isEmpty);
    expect(created.toString(), isNot(contains('SECRET')));
    expect(created.toJson()['password'], 'p4ssw0rd-SECRET');
  });

  test('scoped create sends domains', () async {
    final api = FakeApi([
      FakeResponse(201, {...credentialJson(), 'password': 'p'}),
    ]);
    await api.client().smtpCredentials.create(
      const CreateSmtpCredentialRequest(
        name: 'Scoped',
        scope: SmtpCredentialScope.scoped,
        domains: ['example.com'],
      ),
    );
    expect(api.lastJson, {
      'name': 'Scoped',
      'scope': 'scoped',
      'domains': ['example.com'],
    });
  });

  test('smtpCredentials.get encodes the ID', () async {
    final api = FakeApi([FakeResponse(200, credentialJson())]);
    final credential = await api.client().smtpCredentials.get('c-1');
    expect(api.last.method, 'GET');
    expect(api.last.url.path, accountPath('/smtp-credentials/c-1'));
    expect(credential.toJson()['object'], 'credential_smtp');
  });

  test('smtpCredentials.delete sends DELETE', () async {
    final api = FakeApi();
    final result = await api.client().smtpCredentials.delete('c-1');
    expect(api.last.method, 'DELETE');
    expect(api.last.url.path, accountPath('/smtp-credentials/c-1'));
    expect(api.last.headers['Idempotency-Key'], isNull);
    expect(result.message, 'ok');
  });

  test('unknown scopes are kept', () {
    expect(
      SmtpCredential.fromJson(credentialJson(scope: 'team')).scope,
      SmtpCredentialScope('team'),
    );
  });
}
