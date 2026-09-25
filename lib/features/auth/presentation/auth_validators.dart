/// Error texts from the Figma `Ошибки` section (file `App-for-dev`).
abstract final class AuthErrorText {
  /// 139:5287, 139:5295.
  static const String emailRequired = 'Заполните email';

  /// 139:5287.
  static const String passwordRequired = 'Заполните пароль';

  /// Not in the mockup: the Register form's name field (required by the
  /// backend) follows the 139:5287 wording.
  static const String nameRequired = 'Заполните имя';

  /// 139:5297, 139:5294.
  static const String emailInvalid = 'Неверный формат email';

  /// 139:5296.
  static const String emailTaken = 'Email уже используется';

  /// 139:5293.
  static const String emailNotFound = 'Email не зарегистрирован';

  /// 139:5286; also the password hint on Register / New password.
  static const String passwordFormat =
      'Минимум 8 символов, включая цифры и спецсимволы';

  /// 139:5284.
  static const String passwordsMismatch = 'Пароли не совпадают';

  /// 139:5285.
  static const String consentRequired = 'Примите условия чтобы продолжить';

  /// 139:5298.
  static const String invalidCredentials = 'Неверный email или пароль';

  /// 139:5292.
  static const String invalidCode = 'Неверный код. Попробуйте снова';

  /// 139:5291.
  static const String codeExpired = 'Код устарел. Запросите новый';

  /// 139:5290, when the backend reports how long to wait (429 Retry-After).
  static String tooManyAttemptsWait(Duration wait) {
    final minutes = (wait.inSeconds / 60).ceil().clamp(1, 1 << 31);
    return 'Слишком много попыток. Попробуйте через $minutes '
        '${_minutesWord(minutes)}';
  }

  /// 139:5290 variant for `TOO_MANY_ATTEMPTS`, which has no wait time: the
  /// backend unlocks it with a new code, not after a delay.
  static const String tooManyAttemptsNewCode =
      'Слишком много попыток. Запросите новый код';

  // Not in the mockup — generic fallbacks for states the design omits.
  static const String accountBlocked = 'Аккаунт заблокирован';
  static const String network =
      'Нет соединения с интернетом. '
      'Проверьте подключение и попробуйте снова';
  static const String unknown = 'Что-то пошло не так. Попробуйте позже';

  static String _minutesWord(int n) {
    final mod100 = n % 100;
    final mod10 = n % 10;
    if (mod100 >= 11 && mod100 <= 14) return 'минут';
    if (mod10 == 1) return 'минуту';
    if (mod10 >= 2 && mod10 <= 4) return 'минуты';
    return 'минут';
  }
}

/// Client-side checks, mirroring hoffman-backend's request rules so most
/// errors are shown without a round trip.
abstract final class AuthValidators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Same as the backend's `RegisterRequest::PASSWORD_REGEX`: 8+ characters,
  /// at least one digit and one special character.
  static final RegExp _password = RegExp(
    r'^(?=.*[0-9])(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$',
  );

  static final RegExp _code = RegExp(r'^\d{6}$');

  static String? email(String value) {
    final email = value.trim();
    if (email.isEmpty) return AuthErrorText.emailRequired;
    if (!_email.hasMatch(email)) return AuthErrorText.emailInvalid;
    return null;
  }

  static String? requiredPassword(String value) =>
      value.isEmpty ? AuthErrorText.passwordRequired : null;

  static String? newPassword(String value) {
    if (value.isEmpty) return AuthErrorText.passwordRequired;
    if (!_password.hasMatch(value)) return AuthErrorText.passwordFormat;
    return null;
  }

  static String? passwordConfirmation(String password, String confirmation) {
    if (confirmation.isEmpty || confirmation != password) {
      return AuthErrorText.passwordsMismatch;
    }
    return null;
  }

  static String? name(String value) =>
      value.trim().isEmpty ? AuthErrorText.nameRequired : null;

  static String? code(String value) =>
      _code.hasMatch(value) ? null : AuthErrorText.invalidCode;
}
