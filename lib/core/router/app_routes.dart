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

  static const String home = '/home';

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
