import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/features/auth/index.dart';

/// Texts of the tool screens (ТЗ 5.5). Section titles and `Читать` are
/// shared with home (`HomeText`).
abstract final class ToolsText {
  /// The badge leading to the topics (Figma `badges`, `темы`).
  static const String topicsLink = 'темы';

  static const String loadFailed = 'Не удалось загрузить инструменты';
  static const String toolLoadFailed = 'Не удалось загрузить инструмент';
  static const String refreshFailed = 'Не удалось обновить данные';
  static const String notFound = 'Инструмент не найден';

  /// Full-screen failure text for [error], or [fallback] unless offline.
  static String errorText(Object error, String fallback) =>
      error is ApiException && error.isNetwork
      ? AuthErrorText.network
      : fallback;
}
