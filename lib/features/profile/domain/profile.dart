import 'package:flutter/foundation.dart';

/// Notification categories the user can switch off (Figma 642:3433), with
/// their backend `notification_settings` keys.
enum NotificationCategory {
  dailyPractices('daily_practices_enabled'),
  newArticles('new_articles_enabled'),
  system('system_enabled');

  NotificationCategory(this.jsonKey);

  final String jsonKey;
}

/// The user's notification preferences (backend `NotificationSettingResource`).
@immutable
class NotificationSettings {
  const NotificationSettings({
    this.dailyPractices = true,
    this.newArticles = true,
    this.system = true,
  });

  /// A missing key keeps the backend default (every category on — see
  /// `ProfileService::updateNotifications`); `null` settings mean the user
  /// has never changed them.
  factory NotificationSettings.fromJson(Map<String, dynamic>? json) {
    bool read(NotificationCategory c) => json?[c.jsonKey] as bool? ?? true;
    return NotificationSettings(
      dailyPractices: read(NotificationCategory.dailyPractices),
      newArticles: read(NotificationCategory.newArticles),
      system: read(NotificationCategory.system),
    );
  }

  final bool dailyPractices;
  final bool newArticles;
  final bool system;

  bool isEnabled(NotificationCategory category) => switch (category) {
    NotificationCategory.dailyPractices => dailyPractices,
    NotificationCategory.newArticles => newArticles,
    NotificationCategory.system => system,
  };

  NotificationSettings copyWithCategory(
    NotificationCategory category, {
    required bool enabled,
  }) {
    return NotificationSettings(
      dailyPractices: category == NotificationCategory.dailyPractices
          ? enabled
          : dailyPractices,
      newArticles: category == NotificationCategory.newArticles
          ? enabled
          : newArticles,
      system: category == NotificationCategory.system ? enabled : system,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationSettings &&
      other.dailyPractices == dailyPractices &&
      other.newArticles == newArticles &&
      other.system == system;

  @override
  int get hashCode => Object.hash(dailyPractices, newArticles, system);
}

/// The signed-in user's profile, as returned in `profile` by
/// `GET/PATCH /profile` and `POST /profile/email/confirm` (backend
/// `ProfileResource`).
///
/// Graduate status is deliberately not read from here: graduate-only access
/// goes through `currentVerificationProvider` (features/auth) alone.
@immutable
class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.email,
    this.notificationSettings = const NotificationSettings(),
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String,
      notificationSettings: NotificationSettings.fromJson(
        json['notification_settings'] as Map<String, dynamic>?,
      ),
    );
  }

  final int id;
  final String name;
  final String email;
  final NotificationSettings notificationSettings;

  Profile copyWith({
    String? name,
    String? email,
    NotificationSettings? notificationSettings,
  }) {
    return Profile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      notificationSettings: notificationSettings ?? this.notificationSettings,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Profile &&
      other.id == id &&
      other.name == name &&
      other.email == email &&
      other.notificationSettings == notificationSettings;

  @override
  int get hashCode => Object.hash(id, name, email, notificationSettings);
}
