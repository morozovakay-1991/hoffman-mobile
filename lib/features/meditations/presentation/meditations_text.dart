import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/meditations/domain/meditation.dart';

/// Texts of the meditation screens (ТЗ 5.4).
abstract final class MeditationsText {
  static const String start = 'Начать';
  static const String listen = 'Слушать';
  static const String share = ShareButton.label;
  static const String play = 'Воспроизвести';
  static const String pause = 'Пауза';
  static const String rewind = 'Назад на 10 секунд';
  static const String forward = 'Вперёд на 10 секунд';

  static const String loadFailed = 'Не удалось загрузить медитации';
  static const String meditationLoadFailed = 'Не удалось загрузить медитацию';
  static const String audioLoadFailed = 'Не удалось загрузить аудио';
  static const String refreshFailed = 'Не удалось обновить данные';
  static const String shareFailed = ShareButton.failed;
  static const String notFound = 'Медитация не найдена';

  /// Full-screen failure text for [error], or [fallback] unless offline.
  static String errorText(Object error, String fallback) =>
      error is ApiException && error.isNetwork
      ? AuthErrorText.network
      : fallback;

  /// What the share sheet sends. There is no public web page of a
  /// meditation yet, so it is the title and the short description only.
  static String shareText(Meditation meditation) =>
      shareTextOf(meditation.title, meditation.shortDescription);

  /// `4:05`, or `1:02:03` past an hour.
  static String time(Duration duration) {
    final d = duration.isNegative ? Duration.zero : duration;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    if (d.inHours == 0) return '${d.inMinutes}:$seconds';
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    return '${d.inHours}:$minutes:$seconds';
  }
}
