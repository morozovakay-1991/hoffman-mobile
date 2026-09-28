import 'package:flutter/foundation.dart';

/// A meditation of the home feed (backend `MeditationResource`).
@immutable
class HomeMeditation {
  const HomeMeditation({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.durationSeconds,
    this.isLocked = false,
  });

  factory HomeMeditation.fromJson(Map<String, dynamic> json) {
    return HomeMeditation(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      isLocked: json['is_locked'] as bool? ?? false,
    );
  }

  final int id;
  final String title;
  final String shortDescription;
  final int durationSeconds;
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
    this.isLocked = false,
  });

  factory HomeTool.fromJson(Map<String, dynamic> json) {
    return HomeTool(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      stageTag: json['stage_tag'] as String?,
      isLocked: json['is_locked'] as bool? ?? false,
    );
  }

  final int id;
  final String title;
  final String shortDescription;

  /// Stage of the Process the tool belongs to, e.g. `выражение`.
  final String? stageTag;
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
    this.isLocked = false,
  });

  factory HomeTopic.fromJson(Map<String, dynamic> json) {
    return HomeTopic(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      fullDescription: json['full_description'] as String?,
      isLocked: json['is_locked'] as bool? ?? false,
    );
  }

  final int id;
  final String title;
  final String subtitle;

  /// `null` for a locked topic: the backend withholds it.
  final String? fullDescription;
  final bool isLocked;
}

/// An article of the home feed (backend `ArticleResource`).
@immutable
class HomeArticle {
  const HomeArticle({
    required this.id,
    required this.title,
    required this.shortDescription,
    this.coverUrl,
    this.publishedAt,
    this.isLocked = false,
  });

  /// [storageBaseUrl] resolves the backend's relative `cover_image_path`
  /// (a path on its public disk, e.g. `articles/x.jpg`).
  factory HomeArticle.fromJson(
    Map<String, dynamic> json, {
    required Uri storageBaseUrl,
  }) {
    final coverPath = json['cover_image_path'] as String?;
    return HomeArticle(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      coverUrl: coverPath == null || coverPath.isEmpty
          ? null
          : storageBaseUrl.resolve(coverPath),
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
      isLocked: json['is_locked'] as bool? ?? false,
    );
  }

  final int id;
  final String title;
  final String shortDescription;
  final Uri? coverUrl;
  final DateTime? publishedAt;
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

  factory HomeSummary.fromJson(
    Map<String, dynamic> json, {
    required Uri storageBaseUrl,
  }) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) {
      final items = json[key] as List<dynamic>? ?? const [];
      return [for (final item in items) parse(item as Map<String, dynamic>)];
    }

    return HomeSummary(
      meditations: list('meditations', HomeMeditation.fromJson),
      tools: list('tools', HomeTool.fromJson),
      topics: list('topics', HomeTopic.fromJson),
      articles: list(
        'articles',
        (j) => HomeArticle.fromJson(j, storageBaseUrl: storageBaseUrl),
      ),
      diary: DiaryProgress.fromJson(
        json['diary_progress'] as Map<String, dynamic>?,
      ),
    );
  }

  final List<HomeMeditation> meditations;
  final List<HomeTool> tools;
  final List<HomeTopic> topics;
  final List<HomeArticle> articles;
  final DiaryProgress diary;
}
