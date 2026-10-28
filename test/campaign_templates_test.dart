import 'package:ahasend/ahasend.dart';
import 'package:test/test.dart';

import 'helpers.dart';

const templateId = '00000000-0000-4000-8000-000000000013';

Map<String, Object?> campaignTemplateJson({bool withContent = true}) => {
  'object': 'campaign_template',
  'id': templateId,
  'created_at': '2025-10-01T09:00:00Z',
  'updated_at': '2025-10-02T09:00:00Z',
  'name': 'Newsletter',
  'editor': 'advanced',
  if (withContent)
    'content': {
      'mjml': '<mjml><mj-body></mj-body></mjml>',
      'html': '<html></html>',
      'text_is_custom': false,
    },
};

void main() {
  group('campaignTemplates.list', () {
    test('sends the limit and decodes the page', () async {
      final api = FakeApi([
        FakeResponse(200, pageBody([campaignTemplateJson(withContent: false)])),
      ]);
      final page = await api.client().campaignTemplates.list(
        limit: 10,
        before: 'c0',
      );
      expect(api.last.method, 'GET');
      expect(api.last.url.path, accountPath('/campaign-templates'));
      expect(api.last.url.queryParameters, {'limit': '10', 'before': 'c0'});
      final template = page.data.single;
      expect(template.name, 'Newsletter');
      expect(template.editor, TemplateEditor.advanced);
      expect(template.content, isNull);
      expect(template.toJson().containsKey('content'), isFalse);
    });

    test('listAll follows cursors', () async {
      final api = FakeApi([
        FakeResponse(
          200,
          pageBody([campaignTemplateJson()], hasMore: true, nextCursor: 'n'),
        ),
        FakeResponse(200, pageBody([campaignTemplateJson()])),
      ]);
      final all = await api.client().campaignTemplates.listAll().toList();
      expect(all, hasLength(2));
      expect(api.requests[1].url.queryParameters, {'after': 'n'});
    });
  });

  test('campaignTemplates.create posts with an idempotency key', () async {
    final api = FakeApi([FakeResponse(201, campaignTemplateJson())]);
    final template = await api.client().campaignTemplates.create(
      const CreateCampaignTemplateRequest(
        name: 'Newsletter',
        content: TemplateContentInput(mjml: '<mjml><mj-body></mj-body></mjml>'),
      ),
    );
    expect(api.last.method, 'POST');
    expect(api.last.url.path, accountPath('/campaign-templates'));
    expect(api.last.headers['Idempotency-Key'], isNotEmpty);
    expect(api.lastJson, {
      'name': 'Newsletter',
      'content': {'mjml': '<mjml><mj-body></mj-body></mjml>'},
    });
    expect(template.content!.html, '<html></html>');
    expect(template.createdAt, DateTime.utc(2025, 10, 1, 9));
  });

  test('campaignTemplates.create sends the editor without content', () {
    expect(
      const CreateCampaignTemplateRequest(
        name: 'Blank',
        editor: TemplateEditor.simple,
      ).toJson(),
      {'name': 'Blank', 'editor': 'simple'},
    );
  });

  test('campaignTemplates.get encodes the ID', () async {
    final api = FakeApi([FakeResponse(200, campaignTemplateJson())]);
    final template = await api.client().campaignTemplates.get(templateId);
    expect(api.last.method, 'GET');
    expect(api.last.url.path, accountPath('/campaign-templates/$templateId'));
    expect(api.last.headers.containsKey('Idempotency-Key'), isFalse);
    expect(template.id, templateId);
  });

  test('campaignTemplates.update sends PUT with an idempotency key', () async {
    final api = FakeApi([FakeResponse(200, campaignTemplateJson())]);
    await api.client().campaignTemplates.update(
      templateId,
      const UpdateCampaignTemplateRequest(
        name: 'Renamed',
        content: TemplateContentInput(text: Patch.set('Plain')),
      ),
    );
    expect(api.last.method, 'PUT');
    expect(api.last.url.path, accountPath('/campaign-templates/$templateId'));
    expect(api.last.headers['Idempotency-Key'], isNotEmpty);
    expect(api.lastJson, {
      'name': 'Renamed',
      'content': {'text': 'Plain'},
    });
  });

  test('campaignTemplates.delete sends DELETE', () async {
    final api = FakeApi();
    final result = await api.client().campaignTemplates.delete(templateId);
    expect(api.last.method, 'DELETE');
    expect(api.last.url.path, accountPath('/campaign-templates/$templateId'));
    expect(api.last.headers.containsKey('Idempotency-Key'), isFalse);
    expect(result.message, 'ok');
  });
}
