import 'package:flutter/foundation.dart';

/// An article from `GET /articles` or `GET /articles/{id}` (backend
/// `ArticleResource`).
///
/// Articles are open to every access level, so `is_locked` (always `false`)
/// is not read.
@immutable
class Article {
  const Article({
    required this.id,
    required this.title,
    required this.shortDescription,
    this.fullDescription,
    this.coverImageUrl,
    this.publishedAt,
    this.isNew = false,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    final cover = json['cover_image_url'] as String?;
    return Article(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      fullDescription: json['full_description'] as String?,
      coverImageUrl: cover == null || cover.isEmpty
          ? null
          : Uri.tryParse(cover),
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
      isNew: json['is_new'] as bool? ?? false,
    );
  }

  final int id;
  final String title;
  final String shortDescription;

  /// Rich text (HTML) from the admin.
  final String? fullDescription;

  /// Ready public URL of the cover; never built on the device.
  final Uri? coverImageUrl;
  final DateTime? publishedAt;

  /// Marked new in the admin (`is_new`).
  final bool isNew;
}

/// `GET /articles`: the headline article (chosen in the admin) and every
/// other published one. [featured] never repeats in [items].
@immutable
class ArticleCatalog {
  const ArticleCatalog({this.featured, this.items = const []});

  /// A missing or malformed body is an empty catalog.
  factory ArticleCatalog.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return const ArticleCatalog();
    final featured = json['featured'];
    final items = json['items'];
    return ArticleCatalog(
      featured: featured is Map<String, dynamic>
          ? Article.fromJson(featured)
          : null,
      items: items is List
          ? [
              for (final item in items)
                Article.fromJson(item as Map<String, dynamic>),
            ]
          : const [],
    );
  }

  final Article? featured;
  final List<Article> items;

  bool get isEmpty => featured == null && items.isEmpty;
}
