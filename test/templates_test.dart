import 'package:ahasend/ahasend.dart';
import 'package:test/test.dart';

import 'helpers.dart';

const templateId = '0b4f2c1e-6d7a-4c8b-9e0f-1a2b3c4d5e6f';
const versionId = '9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d';

Map<String, Object?> templateJson({bool withContent = true}) => {
  'object': 'template',
  'id': templateId,
  'created_at': '2025-10-01T09:00:00Z',
  'updated_at': '2025-10-02T09:00:00Z',
  'name': 'Order confirmation',
  'subject': 'Your order {{ order_id }}',
  'preheader': 'Thanks for your order',
  'variables': [
    {'name': 'first_name', 'required': true, 'kind': 'value'},
    {'name': 'vip', 'required': false, 'kind': 'condition'},
    {
      'name': 'items',
      'required': true,
      'kind': 'list',
      'item_fields': ['name', 'price'],
    },
  ],
  'from': {'email': 'shop@example.com', 'name': 'Shop'},
  'reply_to': null,
  'editor': 'html',
  'has_draft': false,
  if (withContent)
    'content': {
      'html': '<p>Hi {{ first_name }}</p>',
      'text': 'Hi {{ first_name }}',
      'text_is_custom': false,
    },
};

Map<String, Object?> versionJson({int version = 2}) => {
  'object': 'template_version',
  'id': versionId,
  'version': version,
  'published_at': '2025-10-02T09:00:00Z',
  'published_by': {
    'type': 'api_key',
    'id': '11111111-1111-4111-8111-111111111111',
  },
};

void main() {
  group('templates.list', () {
    test('sends the limit and decodes templates without content', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          pageBody(
            [templateJson(withContent: false)],
            hasMore: true,
            nextCursor: 'c2',
          ),
        ),
      ]);
      final page = await api.client().templates.list(limit: 5, after: 'c1');
      expect(api.last.method, 'GET');
      expect(api.last.url.path, accountPath('/templates'));
      expect(api.last.url.queryParameters, {'limit': '5', 'after': 'c1'});
      final template = page.data.single;
      expect(template.name, 'Order confirmation');
      expect(template.content, isNull);
      expect(template.editor, TemplateEditor.html);
      expect(
        template.from,
        const Address(email: 'shop@example.com', name: 'Shop'),
      );
      expect(template.replyTo, isNull);
      expect(template.variables.map((v) => v.kind), [
        TemplateVariableKind.scalar,
        TemplateVariableKind.condition,
        TemplateVariableKind.list,
      ]);
      expect(template.variables.last.itemFields, ['name', 'price']);
      expect(template.variables.first.itemFields, isNull);
      expect(page.pagination.nextCursor, 'c2');
    });

    test('listAll follows cursors', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          pageBody([templateJson()], hasMore: true, nextCursor: 'c2'),
        ),
        FakeResponse(200, pageBody([templateJson()])),
      ]);
      final all = await api.client().templates.listAll(limit: 1).toList();
      expect(all, hasLength(2));
      expect(api.requests[1].url.queryParameters, {
        'limit': '1',
        'after': 'c2',
      });
    });
  });

  test('templates.create posts the body with an idempotency key', () async {
    final api = FakeApi([FakeResponse(201, templateJson())]);
    final template = await api.client().templates.create(
      const CreateTemplateRequest(
        name: 'Order confirmation',
        editor: TemplateEditor.html,
        subject: 'Your order',
        from: TemplateAddressInput(email: 'shop@example.com', name: 'Shop'),
        replyTo: TemplateAddressInput(email: 'help@example.com'),
        content: TemplateContentInput(html: '<p>Hi</p>'),
        publish: true,
      ),
    );
    expect(api.last.method, 'POST');
    expect(api.last.url.path, accountPath('/templates'));
    expect(api.last.headers['Idempotency-Key'], isNotEmpty);
    expect(api.lastJson, {
      'name': 'Order confirmation',
      'editor': 'html',
      'subject': 'Your order',
      'from': {'email': 'shop@example.com', 'name': 'Shop'},
      'reply_to': {'email': 'help@example.com'},
      'content': {'html': '<p>Hi</p>'},
      'publish': true,
    });
    expect(template.content!.html, '<p>Hi {{ first_name }}</p>');
    expect(template.content!.textIsCustom, isFalse);
    expect(template.toJson()['object'], 'template');
  });

  test('templates.get encodes the ID', () async {
    final api = FakeApi([FakeResponse(200, templateJson())]);
    final template = await api.client().templates.get('a/b');
    expect(api.last.method, 'GET');
    expect(api.last.url.path, accountPath('/templates/a%2Fb'));
    expect(api.last.headers.containsKey('Idempotency-Key'), isFalse);
    expect(template.id, templateId);
  });

  group('templates.update', () {
    test('sends PUT with patches and an idempotency key', () async {
      final api = FakeApi([FakeResponse(200, templateJson())]);
      await api.client().templates.update(
        templateId,
        UpdateTemplateRequest(
          name: 'Renamed',
          subject: Patch.set('New subject'),
          preheader: const Patch.clear(),
          from: const Patch.set(
            TemplateAddressInput(email: 'shop@example.com'),
          ),
          replyTo: const Patch.clear(),
          content: const TemplateContentInput(
            html: '<p>New</p>',
            text: Patch.clear(),
          ),
        ),
      );
      expect(api.last.method, 'PUT');
      expect(api.last.url.path, accountPath('/templates/$templateId'));
      expect(api.last.headers['Idempotency-Key'], isNotEmpty);
      expect(api.lastJson, {
        'name': 'Renamed',
        'subject': 'New subject',
        'preheader': null,
        'from': {'email': 'shop@example.com'},
        'reply_to': null,
        'content': {'html': '<p>New</p>', 'text': null},
      });
    });

    test('leaves out unset fields', () {
      expect(const UpdateTemplateRequest(publish: true).toJson(), {
        'publish': true,
      });
      expect(const UpdateTemplateRequest(from: Patch.clear()).toJson(), {
        'from': null,
      });
    });
  });

  test('templates.delete sends DELETE', () async {
    final api = FakeApi();
    final result = await api.client().templates.delete(templateId);
    expect(api.last.method, 'DELETE');
    expect(api.last.url.path, accountPath('/templates/$templateId'));
    expect(api.last.headers.containsKey('Idempotency-Key'), isFalse);
    expect(result.message, 'ok');
  });

  test('templates.getDraft decodes the draft', () async {
    final api = FakeApi([
      FakeResponse(200, {
        'object': 'template_draft',
        'template_id': templateId,
        'updated_at': '2025-10-03T09:00:00Z',
        'subject': 'Draft subject',
        'preheader': '',
        'variables': [
          {'name': 'first_name', 'required': true, 'kind': 'value'},
        ],
        'from': null,
        'reply_to': null,
        'content': {
          'mjml': '<mjml></mjml>',
          'text': 'Custom',
          'text_is_custom': true,
        },
      }),
    ]);
    final draft = await api.client().templates.getDraft(templateId);
    expect(api.last.method, 'GET');
    expect(api.last.url.path, accountPath('/templates/$templateId/draft'));
    expect(draft.templateId, templateId);
    expect(draft.subject, 'Draft subject');
    expect(draft.from, isNull);
    expect(draft.content!.mjml, '<mjml></mjml>');
    expect(draft.content!.textIsCustom, isTrue);
    expect(draft.updatedAt, DateTime.utc(2025, 10, 3, 9));
  });

  test('templates.discardDraft sends DELETE to the draft', () async {
    final api = FakeApi([FakeResponse(200, templateJson())]);
    final template = await api.client().templates.discardDraft(templateId);
    expect(api.last.method, 'DELETE');
    expect(api.last.url.path, accountPath('/templates/$templateId/draft'));
    expect(api.last.headers.containsKey('Idempotency-Key'), isFalse);
    expect(template.hasDraft, isFalse);
  });

  test('templates.publish posts without a body', () async {
    final api = FakeApi([FakeResponse(200, templateJson())]);
    await api.client().templates.publish(templateId);
    expect(api.last.method, 'POST');
    expect(api.last.url.path, accountPath('/templates/$templateId/publish'));
    expect(api.last.headers['Idempotency-Key'], isNotEmpty);
    expect(api.last.body, isEmpty);
  });

  test('templates.listVersions decodes the unpaginated list', () async {
    final api = FakeApi([
      FakeResponse(200, {
        'object': 'list',
        'data': [
          versionJson(),
          {...versionJson(version: 1), 'published_by': null},
        ],
      }),
    ]);
    final versions = await api.client().templates.listVersions(templateId);
    expect(api.last.method, 'GET');
    expect(api.last.url.path, accountPath('/templates/$templateId/versions'));
    expect(versions.map((v) => v.version), [2, 1]);
    expect(versions.first.publishedBy!.type, TemplatePublisherType.apiKey);
    expect(versions.last.publishedBy, isNull);
  });

  test('templates.getVersion decodes the version detail', () async {
    final api = FakeApi([
      FakeResponse(200, {
        ...versionJson(),
        'subject': 'v2 subject',
        'preheader': 'v2',
        'variables': <Object>[],
        'from': {'email': 'shop@example.com', 'name': ''},
        'reply_to': {'email': 'help@example.com', 'name': ''},
        'content': null,
      }),
    ]);
    final version = await api.client().templates.getVersion(
      templateId,
      versionId,
    );
    expect(
      api.last.url.path,
      accountPath('/templates/$templateId/versions/$versionId'),
    );
    expect(version.version, 2);
    expect(version.subject, 'v2 subject');
    expect(version.replyTo!.email, 'help@example.com');
    expect(version.content, isNull);
    expect(version.toJson()['object'], 'template_version');
  });

  group('templates.restoreVersion', () {
    test('sends an empty body by default', () async {
      final api = FakeApi([FakeResponse(200, templateJson())]);
      await api.client().templates.restoreVersion(templateId, versionId);
      expect(api.last.method, 'POST');
      expect(
        api.last.url.path,
        accountPath('/templates/$templateId/versions/$versionId/restore'),
      );
      expect(api.last.headers['Idempotency-Key'], isNotEmpty);
      expect(api.lastJson, <String, Object?>{});
    });

    test('sends publish', () async {
      final api = FakeApi([FakeResponse(200, templateJson())]);
      await api.client().templates.restoreVersion(
        templateId,
        versionId,
        request: const RestoreTemplateVersionRequest(publish: true),
      );
      expect(api.lastJson, {'publish': true});
    });
  });

  test('TemplateContentInput.fromContent keeps the text', () {
    final input = TemplateContentInput.fromContent(
      const TemplateContent(html: '<p>x</p>', text: 'x', textIsCustom: true),
      editor: .html,
    );
    expect(input.toJson(), {'html': '<p>x</p>', 'text': 'x'});
  });

  test(
    'TemplateContentInput.fromContent drops the HTML of simple templates',
    () {
      final input = TemplateContentInput.fromContent(
        const TemplateContent(html: '<p>x</p>', text: 'x', textIsCustom: true),
        editor: .simple,
      );
      expect(input.toJson(), {'text': 'x'});
    },
  );

  test('unknown enum values are kept', () {
    expect(TemplateEditor('drag').isKnown, isFalse);
    expect(TemplateVariableKind('map').isKnown, isFalse);
    expect(TemplatePublisherType('bot').isKnown, isFalse);
  });
}
