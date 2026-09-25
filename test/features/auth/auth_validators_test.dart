import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/features/auth/index.dart';

void main() {
  group('email', () {
    test('empty → required', () {
      expect(AuthValidators.email('  '), AuthErrorText.emailRequired);
    });

    for (final bad in [
      'kate',
      'kate@',
      'kate@example',
      '@example.com',
      'k t@x.io',
    ]) {
      test('"$bad" → invalid format', () {
        expect(AuthValidators.email(bad), AuthErrorText.emailInvalid);
      });
    }

    test('valid, surrounding spaces ignored', () {
      expect(AuthValidators.email(' kate@example.com '), isNull);
    });
  });

  group('new password (backend PASSWORD_REGEX)', () {
    test('empty → required', () {
      expect(AuthValidators.newPassword(''), AuthErrorText.passwordRequired);
    });

    for (final bad in ['a1!', 'abcdefgh', 'abcdefg1', 'abcdefg!', '234567!']) {
      test('"$bad" → format error', () {
        expect(AuthValidators.newPassword(bad), AuthErrorText.passwordFormat);
      });
    }

    for (final good in ['abcdef1!', 'Pa55word#', '12345678?']) {
      test('"$good" → ok', () {
        expect(AuthValidators.newPassword(good), isNull);
      });
    }
  });

  test('confirmation must equal the password', () {
    expect(
      AuthValidators.passwordConfirmation('secret1!', 'secret1?'),
      AuthErrorText.passwordsMismatch,
    );
    expect(
      AuthValidators.passwordConfirmation('secret1!', ''),
      AuthErrorText.passwordsMismatch,
    );
    expect(AuthValidators.passwordConfirmation('secret1!', 'secret1!'), isNull);
  });

  test('code must be exactly 6 digits', () {
    expect(AuthValidators.code('12345'), AuthErrorText.invalidCode);
    expect(AuthValidators.code('12345a'), AuthErrorText.invalidCode);
    expect(AuthValidators.code('123456'), isNull);
  });

  test('139:5290 wait message uses Russian plural forms', () {
    String wait(int seconds) =>
        AuthErrorText.tooManyAttemptsWait(Duration(seconds: seconds));

    expect(wait(30), 'Слишком много попыток. Попробуйте через 1 минуту');
    expect(wait(120), 'Слишком много попыток. Попробуйте через 2 минуты');
    expect(wait(300), 'Слишком много попыток. Попробуйте через 5 минут');
    expect(wait(21 * 60), 'Слишком много попыток. Попробуйте через 21 минуту');
    expect(wait(11 * 60), 'Слишком много попыток. Попробуйте через 11 минут');
  });
}
