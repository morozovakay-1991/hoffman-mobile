import 'package:flutter/foundation.dart';

/// `cover_image_url` of a content item: an absolute URL from the backend,
/// `null` when the item has no cover.
Uri? _coverUrl(Map<String, dynamic> json) {
  final url = json['cover_image_url'] as String?;
  return url == null || url.isEmpty ? null : Uri.tryParse(url);
}

/// A meditation of the home feed (backend `MeditationResource`).
@immutable
class HomeMeditation {
  const HomeMeditation({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.durationSeconds,
    this.coverImageUrl,
    this.isLocked = false,
  });

  factory HomeMeditation.fromJson(Map<String, dynamic> json) {
    return HomeMeditation(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      coverImageUrl: _coverUrl(json),
      isLocked: json['is_locked'] as bool? ?? false,
    );
  }

  final int id;
  final String title;
  final String shortDescription;
  final int durationSeconds;
  final Uri? coverImageUrl;
  final bool isLocked;
}

/// A tool of the home feed (backend `ToolResource`).
@immutable
class HomeTool {
  const HomeTool({
    required this.id,
    required this.title,
    required this.shortDescription,
    this.stageTag,
    this.coverImageUrl,
    this.isLocked = false,
  });

  factory HomeTool.fromJson(Map<String, dynamic> json) {
    return HomeTool(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      stageTag: json['stage_tag'] as String?,
      coverImageUrl: _coverUrl(json),
      isLocked: json['is_locked'] as bool? ?? false,
    );
  }

  final int id;
  final String title;
  final String shortDescription;

  /// Stage of the Process the tool belongs to, e.g. `выражение`.
  final String? stageTag;
  final Uri? coverImageUrl;
  final bool isLocked;
}

/// A topic of the home feed (backend `TopicResource`).
@immutable
class HomeTopic {
  const HomeTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    this.fullDescription,
    this.coverImageUrl,
    this.isLocked = false,
  });

  factory HomeTopic.fromJson(Map<String, dynamic> json) {
    return HomeTopic(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      fullDescription: json['full_description'] as String?,
      coverImageUrl: _coverUrl(json),
      isLocked: json['is_locked'] as bool? ?? false,
    );
  }

  final int id;
  final String title;
  final String subtitle;

  /// `null` for a locked topic: the backend withholds it.
  final String? fullDescription;
  final Uri? coverImageUrl;
  final bool isLocked;
}

/// An article of the home feed (backend `ArticleResource`).
@immutable
class HomeArticle {
  const HomeArticle({
    required this.id,
    required this.title,
    required this.shortDescription,
    this.coverImageUrl,
    this.publishedAt,
    this.isNew = false,
    this.isLocked = false,
  });

  factory HomeArticle.fromJson(Map<String, dynamic> json) {
    return HomeArticle(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      coverImageUrl: _coverUrl(json),
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
      isNew: json['is_new'] as bool? ?? false,
      isLocked: json['is_locked'] as bool? ?? false,
    );
  }

  final int id;
  final String title;
  final String shortDescription;
  final Uri? coverImageUrl;
  final DateTime? publishedAt;

  /// Marked new in the admin (`is_new`); the card shows the `новое` badge.
  final bool isNew;
  final bool isLocked;
}

/// The user's progress in the 100-day diary (`diary_progress`).
@immutable
class DiaryProgress {
  const DiaryProgress({
    required this.isAvailable,
    required this.totalDays,
    this.currentDay,
  });

  factory DiaryProgress.fromJson(Map<String, dynamic>? json) {
    return DiaryProgress(
      isAvailable: json?['is_available'] as bool? ?? false,
      totalDays: (json?['total_days'] as num?)?.toInt() ?? defaultTotalDays,
      currentDay: (json?['current_day'] as num?)?.toInt(),
    );
  }

  static const int defaultTotalDays = 100;

  /// Whether the user's access level opens the diary (confirmed graduate
  /// with access). Decided by the backend, never guessed on the device.
  final bool isAvailable;
  final int totalDays;

  /// The day the user is on, 1-based; `null` when the diary is closed.
  final int? currentDay;

  /// Share of the diary reached, 0–1, for the progress bar.
  double get progress {
    final day = currentDay;
    if (!isAvailable || day == null || totalDays <= 0) return 0;
    return (day / totalDays).clamp(0, 1);
  }
}

/// A content section as the backend returns it: `{featured, items}`.
///
/// [featured] is the item picked in the admin (`is_featured`) to head the
/// section, `null` when none is; [items] are the rest, never repeating
/// [featured].
@immutable
class HomeSection<T> {
  const HomeSection({this.featured, this.items = const []});

  /// A missing or malformed section is an empty one.
  factory HomeSection.fromJson(
    Object? json,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (json is! Map<String, dynamic>) return HomeSection<T>();
    final featured = json['featured'];
    final items = json['items'] as List<dynamic>? ?? const [];
    return HomeSection<T>(
      featured: featured is Map<String, dynamic> ? parse(featured) : null,
      items: [for (final item in items) parse(item as Map<String, dynamic>)],
    );
  }

  final T? featured;
  final List<T> items;

  /// Neither a featured item nor any other.
  bool get isEmpty => featured == null && items.isEmpty;
}

/// `GET /home`: a handful of items per content section plus the diary
/// progress.
@immutable
class HomeSummary {
  const HomeSummary({
    required this.meditations,
    required this.tools,
    required this.topics,
    required this.articles,
    required this.diary,
  });

  factory HomeSummary.fromJson(Map<String, dynamic> json) {
    return HomeSummary(
      meditations: HomeSection.fromJson(
        json['meditations'],
        HomeMeditation.fromJson,
      ),
      tools: HomeSection.fromJson(json['tools'], HomeTool.fromJson),
      topics: HomeSection.fromJson(json['topics'], HomeTopic.fromJson),
      articles: HomeSection.fromJson(json['articles'], HomeArticle.fromJson),
      diary: DiaryProgress.fromJson(
        json['diary_progress'] as Map<String, dynamic>?,
      ),
    );
  }

  final HomeSection<HomeMeditation> meditations;
  final HomeSection<HomeTool> tools;
  final HomeSection<HomeTopic> topics;
  final HomeSection<HomeArticle> articles;
  final DiaryProgress diary;
}
