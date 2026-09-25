/// Route paths used across the app.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String verification = '/verification';
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
