/// Route paths used across the app.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';

  /// "Вы выпускник Процесса Хоффмана?" — Figma 139:5310.
  static const String verification = '/verification';

  /// "Данные выпускника" — Figma 139:5303.
  static const String verificationForm = '/verification/form';

  /// "Статус подтвержден" — Figma 139:5307.
  static const String verificationConfirmed = '/verification/confirmed';

  /// "Статус не подтвержден" — Figma 139:5306.
  static const String verificationNotConfirmed = '/verification/not-confirmed';

  /// Главная — Figma 612:7209.
  static const String home = '/home';

  // Content sections. Their list routes are the bottom tabs (except
  // [topics]); apart from meditations the screens are still placeholders.
  static const String meditations = '/meditations';
  static const String tools = '/tools';
  static const String topics = '/topics';
  static const String diary = '/diary';
  static const String articles = '/articles';

  /// Its player is `${meditation(id)}/player`.
  static String meditation(int id) => '$meditations/$id';
  static String tool(int id) => '$tools/$id';
  static String topic(int id) => '$topics/$id';
  static String article(int id) => '$articles/$id';

  /// "Личный кабинет" — Figma 651:3334 (not verified) / 651:3729 (verified).
  static const String profile = '/profile';

  /// "Личные данные" — Figma 642:3311.
  static const String profilePersonalData = '/profile/personal-data';

  /// "Имя пользователя" — Figma 642:3475.
  static const String profileName = '/profile/personal-data/name';

  /// "Email" — Figma 642:3504.
  static const String profileEmail = '/profile/personal-data/email';

  /// "Введите код" for the new email — Figma 848:1330.
  static const String profileEmailCode = '/profile/personal-data/email/code';

  /// "Пароль" — Figma 642:3533.
  static const String profilePassword = '/profile/personal-data/password';

  /// Graduate verification retried from the profile (ТЗ 5.2.4): the form —
  /// Figma "Профиль" 131:2453. Same screens as [verificationForm] and the
  /// results, but inside the tab shell.
  static const String profileVerification = '/profile/verification';

  /// "Статус подтвержден" from the profile — Figma "Профиль" 131:2408.
  static const String profileVerificationConfirmed =
      '/profile/verification/confirmed';

  /// "Статус не подтвержден" from the profile — Figma "Профиль" 131:2429.
  static const String profileVerificationNotConfirmed =
      '/profile/verification/not-confirmed';

  /// "Удаление аккаунта" — Figma 755:3939.
  static const String profileDeleteAccount = '/profile/delete-account';

  /// "Уведомления" — Figma 642:3433.
  static const String profileNotifications = '/profile/notifications';

  /// "Правовая информация" — Figma 642:3358.
  static const String profileLegal = '/profile/legal';

  /// A legal document — Figma 642:3400.
  static String profileLegalDocument(String slug) =>
      '$profileLegal/${Uri.encodeComponent(slug)}';

  /// "Ваш аккаунт удален" — Figma 753:3884. Reachable signed in or out: it
  /// is opened right before the deleted account's session ends.
  static const String accountDeleted = '/account-deleted';

  /// Reset password, step 1 (email) — Figma 139:5305.
  static const String forgotPassword = '/forgot-password';

  /// Step 2 (code, resend timer) — Figma 139:5304.
  static const String forgotPasswordCode = '/forgot-password/code';

  /// Step 3 (new password) — Figma 139:5302.
  static const String forgotPasswordNewPassword =
      '/forgot-password/new-password';

  /// Step 4 ("Пароль изменен") — Figma 139:5309.
  static const String forgotPasswordDone = '/forgot-password/done';
}
