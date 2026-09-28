import 'dart:math' as math;

import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/features/auth/index.dart';

/// Texts of the home screen (Figma 612:7209) and the formatting of its
/// card metadata.
abstract final class HomeText {
  static const String greeting = 'С возвращением';
  static String greetingFor(String name) =>
      name.trim().isEmpty ? greeting : '$greeting, ${name.trim()}';

  static const String seeAll = 'все';
  static const String profile = 'Личный кабинет';

  static const String meditations = 'Медитации';
  static const String meditationsSubtitle =
      'Практики для осознания, проживания и восстановления';
  static const String tools = 'Инструменты';
  static const String toolsSubtitle =
      'Упражнения для рефлексии, поддержки и изменений';
  static const String topics = 'Темы';
  // TODO(figma): the mockup repeats the tools subtitle here.
  static const String topicsSubtitle =
      'Упражнения для рефлексии, поддержки и изменений';
  static const String diary = 'Дневник\n100 дней';
  // TODO(figma): the mockup has lorem ipsum here.
  static const String diarySubtitle = 'Одно задание в день, шаг за шагом';
  static const String articles = 'Статьи';
  static const String articlesSubtitle = 'Анонсы, новости и авторские тексты';

  static const String start = 'Начать';
  static const String read = 'Читать';
  static const String continueDiary = 'Продолжить';

  static const String sectionEmpty = 'Здесь пока ничего нет';
  static const String loadFailed = 'Не удалось загрузить данные';
  static const String refreshFailed = 'Не удалось обновить данные';

  static String day(int day) => 'День $day';
  static String ofTotal(int total) => 'из $total';

  /// Full-screen load failure text for [error] from the provider.
  static String loadError(Object error) =>
      error is ApiException && error.isNetwork
      ? AuthErrorText.network
      : loadFailed;

  /// `25 минут` — rounded to whole minutes, at least one.
  static String duration(int seconds) {
    final minutes = seconds <= 0 ? 0 : math.max(1, (seconds / 60).round());
    return '$minutes ${_plural(minutes, 'минута', 'минуты', 'минут')}';
  }

  /// `Март, 2025`; empty for an unpublished article.
  static String monthYear(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    return '${_months[local.month - 1]}, ${local.year}';
  }

  static const List<String> _months = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  static String _plural(int n, String one, String few, String many) {
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 14) return many;
    return switch (n % 10) {
      1 => one,
      2 || 3 || 4 => few,
      _ => many,
    };
  }
}
