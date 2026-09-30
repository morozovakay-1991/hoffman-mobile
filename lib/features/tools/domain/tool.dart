import 'package:flutter/foundation.dart';

/// A tool from `GET /tools` or `GET /tools/{id}` (backend `ToolResource`).
@immutable
class Tool {
  const Tool({
    required this.id,
    required this.title,
    required this.shortDescription,
    this.fullDescription,
    this.coverImageUrl,
    this.stageTag,
    this.isLocked = false,
    this.topicIds = const [],
  });

  factory Tool.fromJson(Map<String, dynamic> json) {
    final cover = json['cover_image_url'] as String?;
    final stageTag = (json['stage_tag'] as String?)?.trim();
    final topicIds = json['topic_ids'];
    return Tool(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      fullDescription: json['full_description'] as String?,
      coverImageUrl: cover == null || cover.isEmpty
          ? null
          : Uri.tryParse(cover),
      stageTag: stageTag == null || stageTag.isEmpty ? null : stageTag,
      isLocked: json['is_locked'] as bool? ?? false,
      topicIds: topicIds is List
          ? [for (final id in topicIds) (id as num).toInt()]
          : const [],
    );
  }

  final int id;
  final String title;
  final String shortDescription;

  /// Rich text (HTML) from the admin.
  final String? fullDescription;

  /// Ready public URL of the cover; never built on the device.
  final Uri? coverImageUrl;

  /// Stage of the Process the tool belongs to, e.g. `выражение`.
  final String? stageTag;

  /// Still sent by the backend but always `false`: the tools are open to
  /// every user (a product decision, departing from ТЗ 4.1). Nothing in the
  /// app acts on it.
  final bool isLocked;
  final List<int> topicIds;
}

/// `GET /tools`: the headline tool (chosen in the admin) and every other
/// published one. [featured] never repeats in [items].
@immutable
class ToolCatalog {
  const ToolCatalog({this.featured, this.items = const []});

  /// A missing or malformed body is an empty catalog.
  factory ToolCatalog.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return const ToolCatalog();
    final featured = json['featured'];
    final items = json['items'];
    return ToolCatalog(
      featured: featured is Map<String, dynamic>
          ? Tool.fromJson(featured)
          : null,
      items: items is List
          ? [
              for (final item in items)
                Tool.fromJson(item as Map<String, dynamic>),
            ]
          : const [],
    );
  }

  final Tool? featured;
  final List<Tool> items;

  bool get isEmpty => featured == null && items.isEmpty;

  /// [featured] first, then [items].
  List<Tool> get all => [?featured, ...items];
}
