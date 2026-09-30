import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/features/auth/index.dart';

/// Texts of the topic screens (ТЗ 5.6). Section titles and `Читать` are
/// shared with home (`HomeText`).
abstract final class TopicsText {
  /// The badge leading back to the tools (Figma `badges`, `инструменты`).
  static const String toolsLink = 'инструменты';

  /// Figma "Theme" 2:1474.
  static const String possibleWork = 'Возможная работа';

  // TODO(figma): no related content block in the mockup ("Theme" 2:1469
  // only links a tool and a meditation from "Возможная работа").
  static const String relatedTools = 'Инструменты по теме';
  static const String relatedMeditations = 'Медитации по теме';

  static const String loadFailed = 'Не удалось загрузить темы';
  static const String topicLoadFailed = 'Не удалось загрузить тему';
  static const String relatedLoadFailed =
      'Не удалось загрузить инструменты и медитации';
  static const String refreshFailed = 'Не удалось обновить данные';
  static const String notFound = 'Тема не найдена';

  /// Full-screen failure text for [error], or [fallback] unless offline.
  static String errorText(Object error, String fallback) =>
      error is ApiException && error.isNetwork
      ? AuthErrorText.network
      : fallback;
}
