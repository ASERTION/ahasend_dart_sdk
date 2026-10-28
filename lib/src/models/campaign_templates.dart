import '../json.dart';
import 'templates.dart';

/// A design a campaign copies when it is made from it.
///
/// A campaign template has no draft, no versions, no subject and no
/// sender; the campaign owns its subject and sender.
final class const CampaignTemplate({
  /// The campaign template ID.
  required final String id,

  /// When the campaign template was created.
  required final DateTime createdAt,

  /// When the campaign template last changed.
  required final DateTime updatedAt,

  /// The name, as shown in the dashboard.
  required final String name,

  /// The editor the design is made with.
  required final TemplateEditor editor,

  /// The content, or `null` when it has neither HTML nor text. Always
  /// `null` in `campaignTemplates.list`. A campaign can be made from the
  /// campaign template only once it has HTML.
  final TemplateContent? content,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a campaign template.
  this;

  /// Decodes a campaign template from JSON.
  factory fromJson(JsonMap json) => CampaignTemplate(
    id: json['id'] as String,
    createdAt: decodeDateTime(json['created_at']),
    updatedAt: decodeDateTime(json['updated_at']),
    name: json['name'] as String,
    editor: decodeEnum(json['editor'], TemplateEditor.new),
    content: switch (json['content']) {
      null => null,
      final content => TemplateContent.fromJson(asJsonMap(content)),
    },
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'campaign_template',
    'id': id,
    'created_at': encodeDateTime(createdAt),
    'updated_at': encodeDateTime(updatedAt),
    'name': name,
    'editor': editor.value,
    'content': ?content?.toJson(),
  };

  @override
  String toString() =>
      'CampaignTemplate(id: $id, name: $name, editor: ${editor.value})';
}

/// A request to create a campaign template.
final class const CreateCampaignTemplateRequest({
  /// The name (1 to 255 characters).
  required final String name,

  /// The editor. Required when [content] holds neither `mjml` nor `html`;
  /// must agree with the content otherwise.
  final TemplateEditor? editor,

  /// The content. Where the [TemplateContentInput] rules name the draft,
  /// they mean the campaign template itself.
  final TemplateContentInput? content,
}) {
  /// Creates a campaign template create request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'name': name,
    'editor': ?editor?.value,
    'content': ?content?.toJson(),
  };
}

/// Changes to a campaign template. A field left `null` is not changed.
/// The editor never changes.
final class const UpdateCampaignTemplateRequest({
  /// The name (1 to 255 characters).
  final String? name,

  /// The content. For a `simple` campaign template, send only `text`.
  final TemplateContentInput? content,
}) {
  /// Creates a campaign template update request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {'name': ?name, 'content': ?content?.toJson()};
}
