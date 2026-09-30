import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;

/// A topic from `GET /topics` or `GET /topics/{id}` (backend
/// `TopicResource`).
///
/// `short_description` and `possible_work` (the "Возможная работа" block,
/// ТЗ 5.6) are read when the backend sends them; `TopicResource` does not
/// have them yet, so both stay optional.
@immutable
class Topic {
  const Topic({
    required this.id,
    required this.title,
    required this.subtitle,
    this.shortDescription,
    this.fullDescription,
    this.possibleWork,
    this.coverImageUrl,
    this.isLocked = false,
    this.toolIds = const [],
    this.meditationIds = const [],
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    final cover = json['cover_image_url'] as String?;
    final shortDescription = (json['short_description'] as String?)?.trim();
    return Topic(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      shortDescription: shortDescription == null || shortDescription.isEmpty
          ? null
          : shortDescription,
      fullDescription: json['full_description'] as String?,
      possibleWork: possibleWorkHtml(json['possible_work']),
      coverImageUrl: cover == null || cover.isEmpty
          ? null
          : Uri.tryParse(cover),
      isLocked: json['is_locked'] as bool? ?? false,
      toolIds: _ids(json['tool_ids']),
      meditationIds: _ids(json['meditation_ids']),
    );
  }

  final int id;
  final String title;

  /// The short wording of the topic's essence, shown under the title, e.g.
  /// `нелюбовь к себе / нет ресурсов / выгорание`.
  final String subtitle;

  /// Plain text for the unfolded list card; `null` when the backend has
  /// none (see [summary]).
  final String? shortDescription;

  /// Rich text (HTML) from the admin.
  final String? fullDescription;

  /// "Возможная работа": the recommendations as an HTML list (`<ul>` or
  /// `<ol>`), `null` when there are none.
  final String? possibleWork;

  /// Ready public URL of the cover; never built on the device.
  final Uri? coverImageUrl;

  /// Still sent by the backend but always `false`: the topics are open to
  /// every user (a product decision, departing from ТЗ 4.1). Nothing in the
  /// app acts on it.
  final bool isLocked;

  /// The tools and meditations linked to the topic in the admin.
  final List<int> toolIds;
  final List<int> meditationIds;

  /// Longest [summary] cut from the full description, in characters.
  static const int summaryMaxLength = 600;

  /// Text of the unfolded list card: [shortDescription], or the start of the
  /// full description as plain text while the backend has no short one
  /// (the mockup, 132:5157, cuts it the same way).
  String get summary {
    if (shortDescription case final text?) return text;
    final text = plainText(fullDescription ?? '');
    if (text.length <= summaryMaxLength) return text;
    final cut = text.substring(0, summaryMaxLength);
    final space = cut.lastIndexOf(RegExp(r'\s'));
    return '${(space > 0 ? cut.substring(0, space) : cut).trimRight()}…';
  }

  /// [html] without tags and entities, paragraphs on their own lines.
  static String plainText(String html) {
    if (html.trim().isEmpty) return '';
    final fragment = html_parser.parseFragment(
      html.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n'),
    );
    final blocks = fragment.children.isEmpty
        ? [fragment.text ?? '']
        : [for (final node in fragment.nodes) node.text ?? ''];
    return blocks.map((b) => b.trim()).where((b) => b.isNotEmpty).join('\n');
  }

  /// `possible_work` as an HTML list: kept as is when it is already HTML, a
  /// list of items (strings, inline HTML allowed) or plain text with one
  /// recommendation per line becomes a `<ul>`.
  @visibleForTesting
  static String? possibleWorkHtml(Object? value) {
    final List<String> items;
    switch (value) {
      case final String text when text.contains('<'):
        return text.trim().isEmpty ? null : text.trim();
      case final String text:
        items = [for (final line in text.split('\n')) _escape(line)];
      case final List<Object?> list:
        items = [
          for (final item in list)
            if (item is String) item,
        ];
      default:
        return null;
    }
    final entries = [
      for (final item in items)
        if (item.trim().isNotEmpty) '<li>${item.trim()}</li>',
    ];
    return entries.isEmpty ? null : '<ul>${entries.join()}</ul>';
  }

  static String _escape(String text) => const HtmlEscape().convert(text);

  static List<int> _ids(Object? json) =>
      json is List ? [for (final id in json) (id as num).toInt()] : const [];
}

/// `GET /topics`: the headline topic (chosen in the admin) and every other
/// published one. [featured] never repeats in [items].
@immutable
class TopicCatalog {
  const TopicCatalog({this.featured, this.items = const []});

  /// A missing or malformed body is an empty catalog.
  factory TopicCatalog.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return const TopicCatalog();
    final featured = json['featured'];
    final items = json['items'];
    return TopicCatalog(
      featured: featured is Map<String, dynamic>
          ? Topic.fromJson(featured)
          : null,
      items: items is List
          ? [
              for (final item in items)
                Topic.fromJson(item as Map<String, dynamic>),
            ]
          : const [],
    );
  }

  final Topic? featured;
  final List<Topic> items;

  bool get isEmpty => featured == null && items.isEmpty;
}
