import '../json.dart';
import 'common.dart';

/// What kind of value a send supplies for a [TemplateVariable].
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const TemplateVariableKind(
  /// The string the API uses for this value.
  String value,
) {
  /// Text or a number that appears in the email, such as a first name.
  /// The API calls this kind `value`.
  static const TemplateVariableKind scalar = TemplateVariableKind('value');

  /// A value that only decides whether a part of the email is shown. Send a
  /// non-empty value to make it set; leave it out or send `""`, `false`,
  /// `0`, `null`, `[]` or `{}` to make it not set.
  static const TemplateVariableKind condition = TemplateVariableKind(
    'condition',
  );

  /// An array; a section of the email repeats once per element. See
  /// [TemplateVariable.itemFields].
  static const TemplateVariableKind list = TemplateVariableKind('list');

  /// Every value this version of the package knows.
  static const List<TemplateVariableKind> values = [scalar, condition, list];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// A variable a template design uses.
final class const TemplateVariable({
  /// The variable name as the design writes it, for example `first_name`.
  required final String name,

  /// Whether each recipient of a send must supply a value. `email` and
  /// `unsubscribe_url` are never required: the send supplies them.
  required final bool required,

  /// What kind of value to send.
  required final TemplateVariableKind kind,

  /// Only for a [TemplateVariableKind.list] variable: the fields each
  /// element should have. `["value"]` allows plain values; empty when the
  /// repeated section uses nothing from its elements.
  final List<String>? itemFields,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a template variable.
  this;

  /// Decodes a template variable from JSON.
  factory fromJson(JsonMap json) => TemplateVariable(
    name: json['name'] as String,
    required: json['required'] as bool? ?? false,
    kind: decodeEnum(json['kind'], TemplateVariableKind.new),
    itemFields: decodeScalarListOrNull<String>(json['item_fields']),
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'name': name,
    'required': required,
    'kind': kind.value,
    'item_fields': ?itemFields,
  };

  @override
  String toString() =>
      'TemplateVariable(name: $name, kind: ${kind.value}, required: $required)';
}

/// The editor a template is designed with. It never changes after the
/// template is created.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const TemplateEditor(
  /// The string the API uses for this value.
  String value,
) {
  /// Designed in MJML with the dashboard's advanced editor.
  static const TemplateEditor advanced = TemplateEditor('advanced');

  /// Designed with the dashboard's simple editor. Its HTML can be read but
  /// not changed through the API.
  static const TemplateEditor simple = TemplateEditor('simple');

  /// An HTML template, uploaded or written by hand.
  static const TemplateEditor html = TemplateEditor('html');

  /// Every value this version of the package knows.
  static const List<TemplateEditor> values = [advanced, simple, html];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// The content of a template, draft, version, campaign template or
/// campaign. Keys that do not apply to the editor, and empty ones, are
/// `null`.
final class const TemplateContent({
  /// Whether the text was written rather than made from the HTML.
  required final bool textIsCustom,

  /// The MJML source. Only for `advanced` designs.
  final String? mjml,

  /// The HTML of an `html` design, or the HTML made from a `simple` design.
  final String? html,

  /// The plain text version of the email.
  final String? text,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates template content.
  this;

  /// Decodes template content from JSON.
  factory fromJson(JsonMap json) => TemplateContent(
    mjml: json['mjml'] as String?,
    html: json['html'] as String?,
    text: json['text'] as String?,
    textIsCustom: json['text_is_custom'] as bool? ?? false,
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'mjml': ?mjml,
    'html': ?html,
    'text': ?text,
    'text_is_custom': textIsCustom,
  };
}

/// A transactional template, as one of its two copies.
///
/// `templates.get` and every template write return the working copy: the
/// draft while the template has one, and the published copy otherwise.
/// `templates.getPublished` and `templates.list` return the published
/// copy, the one sends use. [hasDraft] says whether a draft exists.
final class const Template({
  /// The template ID. Pass it as `templateId` to
  /// `messages.createFromTemplate`.
  required final String id,

  /// When the template was created.
  required final DateTime createdAt,

  /// When the name or this copy last changed.
  required final DateTime updatedAt,

  /// The template name, as shown in the dashboard.
  required final String name,

  /// This copy's subject. Empty until one is set. A send uses the
  /// published subject unless it names its own.
  required final String subject,

  /// This copy's preview text.
  required final String preheader,

  /// Every variable this copy's design uses. Recipients supply them in
  /// `substitutions`. A send checks the variables of the published copy,
  /// which `templates.getPublished` returns.
  required final List<TemplateVariable> variables,

  /// The editor the template is designed with.
  required final TemplateEditor editor,

  /// Whether the template has a draft: changes that are not published yet.
  /// `templates.get` returns the draft while one exists.
  required final bool hasDraft,

  /// This copy's default sender, or `null` when it has none. A send of a
  /// published copy without one must name a sender.
  final Address? from,

  /// This copy's default reply-to address, or `null` when it has none.
  final Address? replyTo,

  /// This copy's content. `null` when it has no body, as for the published
  /// copy of a template that was never published, and always `null` in
  /// `templates.list`.
  final TemplateContent? content,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a template.
  this;

  /// Decodes a template from JSON.
  factory fromJson(JsonMap json) => Template(
    id: json['id'] as String,
    createdAt: decodeDateTime(json['created_at']),
    updatedAt: decodeDateTime(json['updated_at']),
    name: json['name'] as String,
    subject: json['subject'] as String? ?? '',
    preheader: json['preheader'] as String? ?? '',
    variables: decodeList(json['variables'], TemplateVariable.fromJson),
    from: switch (json['from']) {
      null => null,
      final from => Address.fromJson(asJsonMap(from)),
    },
    replyTo: switch (json['reply_to']) {
      null => null,
      final replyTo => Address.fromJson(asJsonMap(replyTo)),
    },
    editor: decodeEnum(json['editor'], TemplateEditor.new),
    hasDraft: json['has_draft'] as bool? ?? false,
    content: switch (json['content']) {
      null => null,
      final content => TemplateContent.fromJson(asJsonMap(content)),
    },
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'template',
    'id': id,
    'created_at': encodeDateTime(createdAt),
    'updated_at': encodeDateTime(updatedAt),
    'name': name,
    'subject': subject,
    'preheader': preheader,
    'variables': [for (final v in variables) v.toJson()],
    'from': from?.toJson(),
    'reply_to': replyTo?.toJson(),
    'editor': editor.value,
    'has_draft': hasDraft,
    'content': ?content?.toJson(),
  };

  @override
  String toString() =>
      'Template(id: $id, name: $name, '
      'editor: ${editor.value}, hasDraft: $hasDraft)';
}

/// A template's draft: saved changes that are not published yet.
///
/// Only the deprecated `templates.getDraft` returns it.
@Deprecated(
  'The API removed the draft endpoint. Use templates.get, which returns '
  'the draft as a Template while the template has one.',
)
final class const TemplateDraft({
  /// The template the draft belongs to.
  required final String templateId,

  /// When the draft last changed.
  required final DateTime updatedAt,

  /// The draft's subject.
  required final String subject,

  /// The draft's preview text.
  required final String preheader,

  /// Every variable the draft uses.
  required final List<TemplateVariable> variables,

  /// The draft's default sender, or `null` when it has none.
  final Address? from,

  /// The draft's default reply-to address, or `null` when it has none.
  final Address? replyTo,

  /// The draft's content, or `null` when it has no body.
  final TemplateContent? content,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a template draft.
  this;

  /// Decodes a template draft from JSON.
  factory fromJson(JsonMap json) => TemplateDraft(
    templateId: json['template_id'] as String,
    updatedAt: decodeDateTime(json['updated_at']),
    subject: json['subject'] as String? ?? '',
    preheader: json['preheader'] as String? ?? '',
    variables: decodeList(json['variables'], TemplateVariable.fromJson),
    from: switch (json['from']) {
      null => null,
      final from => Address.fromJson(asJsonMap(from)),
    },
    replyTo: switch (json['reply_to']) {
      null => null,
      final replyTo => Address.fromJson(asJsonMap(replyTo)),
    },
    content: switch (json['content']) {
      null => null,
      final content => TemplateContent.fromJson(asJsonMap(content)),
    },
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'template_draft',
    'template_id': templateId,
    'updated_at': encodeDateTime(updatedAt),
    'subject': subject,
    'preheader': preheader,
    'variables': [for (final v in variables) v.toJson()],
    'from': from?.toJson(),
    'reply_to': replyTo?.toJson(),
    'content': content?.toJson(),
  };

  @override
  String toString() =>
      'TemplateDraft(templateId: $templateId, updatedAt: $updatedAt)';
}

/// Who published a template version.
///
/// The API can add values at any time. A value this version of the package
/// does not know is kept as it is, and [isKnown] is `false` for it, so
/// handle it in a `default` branch.
extension type const TemplatePublisherType(
  /// The string the API uses for this value.
  String value,
) {
  /// A user, in the dashboard.
  static const TemplatePublisherType user = TemplatePublisherType('user');

  /// An API key, through the API.
  static const TemplatePublisherType apiKey = TemplatePublisherType('api_key');

  /// Every value this version of the package knows.
  static const List<TemplatePublisherType> values = [user, apiKey];

  /// Whether this version of the package knows this value.
  bool get isKnown => values.contains(this);
}

/// Who published a template version.
final class const TemplatePublisher({
  /// Whether a user or an API key published the version.
  required final TemplatePublisherType type,

  /// The user's ID or the API key's ID.
  required final String id,
}) {
  /// Creates a publisher.
  this;

  /// Decodes a publisher from JSON.
  factory fromJson(JsonMap json) => TemplatePublisher(
    type: decodeEnum(json['type'], TemplatePublisherType.new),
    id: json['id'] as String,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {'type': type.value, 'id': id};

  @override
  String toString() => 'TemplatePublisher(${type.value}: $id)';
}

/// A published version of a template, without its content.
final class const TemplateVersion({
  /// The version ID.
  required final String id,

  /// The version number, counted from 1 for each template.
  required final int version,

  /// When the version was published.
  required final DateTime publishedAt,

  /// Who published the version, or `null` when this is not known.
  final TemplatePublisher? publishedBy,

  /// The JSON object this value was decoded from.
  final JsonMap raw = const {},
}) {
  /// Creates a template version.
  this;

  /// Decodes a template version from JSON.
  factory fromJson(JsonMap json) => TemplateVersion(
    id: json['id'] as String,
    version: decodeInt(json['version']),
    publishedAt: decodeDateTime(json['published_at']),
    publishedBy: switch (json['published_by']) {
      null => null,
      final publishedBy => TemplatePublisher.fromJson(asJsonMap(publishedBy)),
    },
    raw: json,
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'object': 'template_version',
    'id': id,
    'version': version,
    'published_at': encodeDateTime(publishedAt),
    'published_by': publishedBy?.toJson(),
  };

  @override
  String toString() {
    final className = this is TemplateVersionDetail
        ? 'TemplateVersionDetail'
        : 'TemplateVersion';
    return '$className(id: $id, version: $version, publishedAt: $publishedAt)';
  }
}

/// A published version of a template with its content.
final class const TemplateVersionDetail({
  required super.id,
  required super.version,
  required super.publishedAt,

  /// The version's subject.
  required final String subject,

  /// The version's preview text.
  required final String preheader,

  /// Every variable the version uses, as saved when it was published.
  required final List<TemplateVariable> variables,
  super.publishedBy,

  /// The version's default sender, or `null` when it has none.
  final Address? from,

  /// The version's default reply-to address, or `null` when it has none.
  final Address? replyTo,

  /// The version's content, or `null` when it has no body.
  final TemplateContent? content,
  super.raw,
}) extends TemplateVersion {
  /// Creates a template version with content.
  this;

  /// Decodes a template version with content from JSON.
  factory fromJson(JsonMap json) {
    final v = TemplateVersion.fromJson(json);
    return TemplateVersionDetail(
      id: v.id,
      version: v.version,
      publishedAt: v.publishedAt,
      publishedBy: v.publishedBy,
      subject: json['subject'] as String? ?? '',
      preheader: json['preheader'] as String? ?? '',
      variables: decodeList(json['variables'], TemplateVariable.fromJson),
      from: switch (json['from']) {
        null => null,
        final from => Address.fromJson(asJsonMap(from)),
      },
      replyTo: switch (json['reply_to']) {
        null => null,
        final replyTo => Address.fromJson(asJsonMap(replyTo)),
      },
      content: switch (json['content']) {
        null => null,
        final content => TemplateContent.fromJson(asJsonMap(content)),
      },
      raw: json,
    );
  }

  @override
  JsonMap toJson() => {
    ...super.toJson(),
    'subject': subject,
    'preheader': preheader,
    'variables': [for (final v in variables) v.toJson()],
    'from': from?.toJson(),
    'reply_to': replyTo?.toJson(),
    'content': content?.toJson(),
  };
}

/// The content of a template, campaign template or campaign write.
///
/// Holds at most one of [mjml] and [html], and at least one of [mjml],
/// [html] and [text]. Leave `content` out of a write that does not change
/// it.
final class const TemplateContentInput({
  /// The MJML source. Only for `advanced` designs. Images must use full
  /// `https://` URLs.
  final String? mjml,

  /// The HTML. Only for `html` designs. Images and stylesheets must use
  /// full `https://` URLs.
  final String? html,

  /// The plain text version. `Patch.clear()` sends `null`, which makes the
  /// text from the HTML. Leaving it out beside a new design keeps a custom
  /// text, or makes the text from the new HTML otherwise.
  final Patch<String>? text,
}) {
  /// Creates content for a write.
  this;

  /// Creates content from read [content] of a template designed with
  /// [editor], so it can be sent back, for example with a changed design.
  ///
  /// The HTML of a `simple` template can be changed only in the dashboard,
  /// so for that editor only the text is kept.
  factory fromContent(
    TemplateContent content, {
    required TemplateEditor editor,
  }) => TemplateContentInput(
    mjml: content.mjml,
    html: editor == TemplateEditor.simple ? null : content.html,
    text: switch (content.text) {
      null => null,
      final text => Patch.set(text),
    },
  );

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'mjml': ?mjml,
    'html': ?html,
    if (text case final p?) 'text': p.value,
  };
}

/// An address in a template or campaign write.
final class const TemplateAddressInput({
  /// The email address.
  required final String email,

  /// The display name.
  final String? name,
}) {
  /// Creates an address for a write.
  this;

  /// Creates an address for a write from a read [address].
  factory fromAddress(Address address) =>
      TemplateAddressInput(email: address.email, name: address.name);

  /// Encodes this object as JSON.
  JsonMap toJson() => {'email': email, 'name': ?name};

  @override
  String toString() => name == null ? email : '$name <$email>';
}

/// A request to create a transactional template.
///
/// The fields go to the template's draft; set [publish] to publish it in
/// the same request.
final class const CreateTemplateRequest({
  /// The template name (1 to 255 characters).
  required final String name,

  /// The editor. Required when [content] holds neither `mjml` nor `html`;
  /// must agree with the content otherwise.
  final TemplateEditor? editor,

  /// The subject (at most 998 characters).
  final String? subject,

  /// The preview text (at most 500 characters).
  final String? preheader,

  /// The default sender. Must be on a verified, unpaused domain of the
  /// account.
  final TemplateAddressInput? from,

  /// The default reply-to address. It needs [from], and its name must be
  /// empty.
  final TemplateAddressInput? replyTo,

  /// The content.
  final TemplateContentInput? content,

  /// Whether to publish the draft once it is written.
  final bool? publish,
}) {
  /// Creates a template create request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'name': name,
    'editor': ?editor?.value,
    'subject': ?subject,
    'preheader': ?preheader,
    'from': ?from?.toJson(),
    'reply_to': ?replyTo?.toJson(),
    'content': ?content?.toJson(),
    'publish': ?publish,
  };
}

/// Changes to a transactional template.
///
/// A field left `null` is not changed. Every field but [name] goes to the
/// draft; [name] changes at once. The editor never changes.
final class const UpdateTemplateRequest({
  /// The template name (1 to 255 characters).
  final String? name,

  /// The subject. `Patch.clear()` (or an empty string) clears it.
  final Patch<String>? subject,

  /// The preview text. `Patch.clear()` (or an empty string) clears it.
  final Patch<String>? preheader,

  /// The default sender, replacing address and name together.
  /// `Patch.clear()` clears the sender and the reply-to.
  final Patch<TemplateAddressInput>? from,

  /// The default reply-to address. `Patch.clear()` clears it. It needs a
  /// sender, and its name must be empty.
  final Patch<TemplateAddressInput>? replyTo,

  /// The content.
  final TemplateContentInput? content,

  /// Whether to publish the whole draft once it is written, including
  /// changes made in the dashboard.
  final bool? publish,
}) {
  /// Creates a template update request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {
    'name': ?name,
    if (subject case final p?) 'subject': p.value,
    if (preheader case final p?) 'preheader': p.value,
    if (from case final p?) 'from': p.value?.toJson(),
    if (replyTo case final p?) 'reply_to': p.value?.toJson(),
    'content': ?content?.toJson(),
    'publish': ?publish,
  };
}

/// A request to restore a template version into the draft.
final class const RestoreTemplateVersionRequest({
  /// Whether to publish the draft once the version is restored into it.
  final bool? publish,
}) {
  /// Creates a restore request.
  this;

  /// Encodes this object as JSON.
  JsonMap toJson() => {'publish': ?publish};
}
