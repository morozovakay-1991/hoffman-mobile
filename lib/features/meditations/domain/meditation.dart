import 'package:flutter/foundation.dart';

/// A meditation from `GET /meditations` or `GET /meditations/{id}`.
///
/// `audio_path` is deliberately not read: it is a storage key, not a
/// playable URL. Audio is played only from `GET /meditations/{id}/audio`
/// ([MeditationAudio]).
@immutable
class Meditation {
  const Meditation({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.durationSeconds,
    this.fullDescription,
    this.coverImageUrl,
    this.isFree = false,
    this.isLocked = false,
    this.topicIds = const [],
  });

  factory Meditation.fromJson(Map<String, dynamic> json) {
    final cover = json['cover_image_url'] as String?;
    final topicIds = json['topic_ids'];
    return Meditation(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      fullDescription: json['full_description'] as String?,
      coverImageUrl: cover == null || cover.isEmpty
          ? null
          : Uri.tryParse(cover),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      isFree: json['is_free'] as bool? ?? false,
      isLocked: json['is_locked'] as bool? ?? false,
      topicIds: topicIds is List
          ? [for (final id in topicIds) (id as num).toInt()]
          : const [],
    );
  }

  final int id;
  final String title;
  final String shortDescription;

  /// Rich text (HTML) from the admin; `null` for a locked meditation — the
  /// backend withholds it.
  final String? fullDescription;

  /// Ready public URL of the cover; never built on the device.
  final Uri? coverImageUrl;
  final int durationSeconds;
  final bool isFree;

  /// The user's access level does not open it. The list still shows it; a
  /// direct request answers 403 `ACCESS_DENIED`.
  final bool isLocked;
  final List<int> topicIds;
}

/// `GET /meditations`: the headline meditation (chosen in the admin) and
/// every other published one. [featured] never repeats in [items].
@immutable
class MeditationCatalog {
  const MeditationCatalog({this.featured, this.items = const []});

  /// A missing or malformed body is an empty catalog.
  factory MeditationCatalog.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return const MeditationCatalog();
    final featured = json['featured'];
    final items = json['items'];
    return MeditationCatalog(
      featured: featured is Map<String, dynamic>
          ? Meditation.fromJson(featured)
          : null,
      items: items is List
          ? [
              for (final item in items)
                Meditation.fromJson(item as Map<String, dynamic>),
            ]
          : const [],
    );
  }

  final Meditation? featured;
  final List<Meditation> items;

  bool get isEmpty => featured == null && items.isEmpty;
}

/// `GET /meditations/{id}/audio`: a presigned URL to the audio file, valid
/// for an hour.
@immutable
class MeditationAudio {
  const MeditationAudio({required this.url, required this.expiresAt});

  factory MeditationAudio.fromJson(Map<String, dynamic> json) {
    return MeditationAudio(
      url: Uri.parse(json['url'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  /// Renew a little ahead of [expiresAt], so a request that starts just
  /// before the deadline is not refused by the storage midway.
  static const Duration renewAhead = Duration(minutes: 1);

  final Uri url;
  final DateTime expiresAt;

  bool isExpiredAt(DateTime now) =>
      !now.isBefore(expiresAt.subtract(renewAhead));
}
