import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/features/auth/index.dart';

/// Texts of the article screens (ТЗ 5.7). Section titles, `Читать`, the
/// date format and the `новое` badge are shared with home (`HomeText`).
abstract final class ArticlesText {
  static const String loadFailed = 'Не удалось загрузить статьи';
  static const String articleLoadFailed = 'Не удалось загрузить статью';
  static const String refreshFailed = 'Не удалось обновить данные';
  static const String notFound = 'Статья не найдена';

  /// Full-screen failure text for [error], or [fallback] unless offline.
  static String errorText(Object error, String fallback) =>
      error is ApiException && error.isNetwork
      ? AuthErrorText.network
      : fallback;
}
