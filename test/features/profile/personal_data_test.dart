import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/profile/index.dart';

import '../../helpers/app_harness.dart';
import 'profile_harness.dart';

String _text(WidgetTester tester, Key key) =>
    tester.widget<TextField>(fieldIn(key)).controller!.text;

AuthUser? _sessionUser(ProviderContainer container) =>
    switch (container.read(authControllerProvider).value) {
      Authenticated(:final user) => user,
      _ => null,
    };

/// Leaves the code screen so its resend timer does not outlive the test.
Future<void> _drainTimers(WidgetTester tester) =>
    tester.pump(EmailCodeScreen.resendCooldown + const Duration(seconds: 1));

void main() {
  testWidgets('642:3311 — the four items open their screens', (tester) async {
    final container = await openProfile(
      tester,
      profileEnv(),
      location: AppRoutes.profilePersonalData,
    );

    for (final (item, path) in [
      ('Имя пользователя', AppRoutes.profileName),
      ('Email', AppRoutes.profileEmail),
      ('Пароль', AppRoutes.profilePassword),
      ('Удаление аккаунта\nи данных', AppRoutes.profileDeleteAccount),
    ]) {
      await tapAndSettle(tester, find.widgetWithText(ProfileMenuTile, item));
      expect(currentPath(container), path, reason: item);
      await tapAndSettle(tester, find.byTooltip('Back'));
      expect(currentPath(container), AppRoutes.profilePersonalData);
    }
  });

  group('642:3475 — name', () {
    Future<ProviderContainer> open(WidgetTester tester, TestEnvironment env) =>
        openProfile(tester, env, location: AppRoutes.profileName);

    testWidgets('starts with the current name', (tester) async {
      await open(tester, profileEnv());

      expect(_text(tester, EditNameScreen.nameFieldKey), 'Kate');
    });

    testWidgets('an empty name is caught without a request', (tester) async {
      final env = profileEnv();
      await open(tester, env);

      await tester.enterText(fieldIn(EditNameScreen.nameFieldKey), '   ');
      await tapAndSettle(tester, buttonIn(EditNameScreen.submitKey));

      expect(
        errorOf(tester, EditNameScreen.nameFieldKey),
        AuthErrorText.nameRequired,
      );
      expect(env.backend.requestsTo(patchProfile), isEmpty);
    });

    testWidgets('saves with PATCH /profile, updates the session user and '
        'returns', (tester) async {
      final env = profileEnv({patchProfile: profileResponse(name: 'Катя')});
      final container = await open(tester, env);

      await tester.enterText(fieldIn(EditNameScreen.nameFieldKey), ' Катя ');
      await tapAndSettle(tester, buttonIn(EditNameScreen.submitKey));

      expect(lastBody(env, patchProfile), {'name': 'Катя'});
      expect(currentPath(container), AppRoutes.profile);
      expect(find.text(ProfileText.nameSaved), findsOneWidget);
      expect(_sessionUser(container)?.name, 'Катя');
      expect(container.read(currentProfileProvider).value?.name, 'Катя');
      // PATCH /profile has no notification settings; the loaded ones stay.
      expect(
        container
            .read(currentProfileProvider)
            .value
            ?.notificationSettings
            .system,
        isFalse,
      );
    });

    testWidgets('offline: a message, the screen and the input stay', (
      tester,
    ) async {
      final env = profileEnv();
      final container = await open(tester, env);
      env.backend.offline = true;

      await tester.enterText(fieldIn(EditNameScreen.nameFieldKey), 'Катя');
      await tapAndSettle(tester, buttonIn(EditNameScreen.submitKey));

      expect(find.text(AuthErrorText.network), findsOneWidget);
      expect(currentPath(container), AppRoutes.profileName);
      expect(_text(tester, EditNameScreen.nameFieldKey), 'Катя');
      expect(_sessionUser(container)?.name, 'Kate');
    });

    testWidgets('a rejected name is marked on the field', (tester) async {
      await open(
        tester,
        profileEnv({
          patchProfile: FakeResponse.error(
            422,
            'VALIDATION_ERROR',
            fields: {
              'name': ['The name field must be a string.'],
            },
          ),
        }),
      );

      await tapAndSettle(tester, buttonIn(EditNameScreen.submitKey));

      expect(
        errorOf(tester, EditNameScreen.nameFieldKey),
        AuthErrorText.checkField,
      );
    });
  });

  group('642:3504 + 848:1330 — email with a one-time code', () {
    Future<ProviderContainer> open(WidgetTester tester, TestEnvironment env) =>
        openProfile(tester, env, location: AppRoutes.profileEmail);

    Future<void> submitEmail(WidgetTester tester, String email) async {
      await tester.enterText(fieldIn(EditEmailScreen.emailFieldKey), email);
      await tapAndSettle(tester, buttonIn(EditEmailScreen.submitKey));
    }

    Future<void> submitCode(WidgetTester tester, String code) async {
      await tester.enterText(fieldIn(EmailCodeScreen.codeFieldKey), code);
      await tapAndSettle(tester, buttonIn(EmailCodeScreen.submitKey));
    }

    testWidgets('the current email is the placeholder', (tester) async {
      await open(tester, profileEnv());

      expect(find.text('kate@example.com'), findsOneWidget);
    });

    testWidgets('format, required and the current email are checked on the '
        'device', (tester) async {
      final env = profileEnv();
      await open(tester, env);

      await submitEmail(tester, '');
      expect(
        errorOf(tester, EditEmailScreen.emailFieldKey),
        AuthErrorText.emailRequired,
      );
      await submitEmail(tester, 'not-an-email');
      expect(
        errorOf(tester, EditEmailScreen.emailFieldKey),
        AuthErrorText.emailInvalid,
      );
      await submitEmail(tester, 'KATE@example.com');
      expect(
        errorOf(tester, EditEmailScreen.emailFieldKey),
        ProfileText.sameEmail,
      );
      expect(env.backend.requestsTo(patchEmail), isEmpty);
    });

    testWidgets('an email of another account: "Email уже используется"', (
      tester,
    ) async {
      final container = await open(
        tester,
        profileEnv({
          patchEmail: FakeResponse.error(
            422,
            'EMAIL_TAKEN',
            fields: {
              'new_email': ['This email address is already registered.'],
            },
          ),
        }),
      );

      await submitEmail(tester, 'taken@example.com');

      expect(
        errorOf(tester, EditEmailScreen.emailFieldKey),
        AuthErrorText.emailTaken,
      );
      expect(currentPath(container), AppRoutes.profileEmail);
    });

    testWidgets('the email only changes after the code is confirmed', (
      tester,
    ) async {
      final env = profileEnv({
        patchEmail: const FakeResponse(200, {'message': 'sent'}),
        confirmEmail: profileResponse(email: 'new@example.com'),
      });
      final container = await open(tester, env);

      await submitEmail(tester, ' new@example.com ');

      expect(lastBody(env, patchEmail), {'new_email': 'new@example.com'});
      expect(currentPath(container), AppRoutes.profileEmailCode);
      expect(
        find.text('Мы отправили 6-значный код на new@example.com'),
        findsOneWidget,
      );
      // Not changed yet: waiting for the code.
      expect(_sessionUser(container)?.email, 'kate@example.com');

      await submitCode(tester, '123456');

      expect(lastBody(env, confirmEmail), {'code': '123456'});
      // Both the code and the email screens close.
      expect(currentPath(container), AppRoutes.profile);
      expect(find.text(ProfileText.emailChanged), findsOneWidget);
      expect(_sessionUser(container)?.email, 'new@example.com');
      expect(
        container.read(currentProfileProvider).value?.email,
        'new@example.com',
      );
      expect(container.read(emailChangeControllerProvider), isNull);
    });

    for (final (code, message) in [
      ('INVALID_CODE', AuthErrorText.invalidCode),
      ('CODE_EXPIRED', AuthErrorText.codeExpired),
      ('TOO_MANY_ATTEMPTS', AuthErrorText.tooManyAttemptsNewCode),
    ]) {
      testWidgets('$code is shown under the code field', (tester) async {
        final env = profileEnv({
          patchEmail: const FakeResponse(200, {'message': 'sent'}),
          confirmEmail: FakeResponse.error(422, code),
        });
        final container = await open(tester, env);
        await submitEmail(tester, 'new@example.com');

        await submitCode(tester, '000000');

        expect(errorOf(tester, EmailCodeScreen.codeFieldKey), message);
        expect(currentPath(container), AppRoutes.profileEmailCode);
        expect(_sessionUser(container)?.email, 'kate@example.com');
        await _drainTimers(tester);
      });
    }

    testWidgets('a code shorter than 6 digits is not sent', (tester) async {
      final env = profileEnv({
        patchEmail: const FakeResponse(200, {'message': 'sent'}),
      });
      await open(tester, env);
      await submitEmail(tester, 'new@example.com');

      await submitCode(tester, '123');

      expect(
        errorOf(tester, EmailCodeScreen.codeFieldKey),
        AuthErrorText.invalidCode,
      );
      expect(env.backend.requestsTo(confirmEmail), isEmpty);
      await _drainTimers(tester);
    });

    testWidgets('"Отправить еще раз" appears after 59s and re-sends the code', (
      tester,
    ) async {
      final env = profileEnv({
        patchEmail: const FakeResponse(200, {'message': 'sent'}),
      });
      await open(tester, env);
      await submitEmail(tester, 'new@example.com');

      expect(find.text('Отправить еще раз через 59с'), findsOneWidget);
      expect(find.byKey(EmailCodeScreen.resendKey), findsNothing);

      await _drainTimers(tester);
      await tapAndSettle(tester, find.byKey(EmailCodeScreen.resendKey));

      expect(env.backend.requestsTo(patchEmail), hasLength(2));
      expect(lastBody(env, patchEmail), {'new_email': 'new@example.com'});
      expect(find.text('Отправить еще раз через 59с'), findsOneWidget);
      await _drainTimers(tester);
    });

    testWidgets('"Изменить Email" returns to the email field', (tester) async {
      final container = await open(
        tester,
        profileEnv({
          patchEmail: const FakeResponse(200, {'message': 'sent'}),
        }),
      );
      await submitEmail(tester, 'new@example.com');

      await tapAndSettle(tester, find.byKey(EmailCodeScreen.changeEmailKey));

      expect(currentPath(container), AppRoutes.profileEmail);
      expect(_text(tester, EditEmailScreen.emailFieldKey), 'new@example.com');
    });

    testWidgets('the code screen without a pending email goes back to the '
        'email step', (tester) async {
      final container = await openProfile(
        tester,
        profileEnv(),
        location: AppRoutes.profileEmailCode,
      );

      expect(currentPath(container), AppRoutes.profileEmail);
    });
  });

  group('642:3533 — password', () {
    Future<ProviderContainer> open(WidgetTester tester, TestEnvironment env) =>
        openProfile(tester, env, location: AppRoutes.profilePassword);

    Future<void> fill(
      WidgetTester tester, {
      String old = 'oldpass1!',
      String password = 'newpass1!',
      String? confirmation,
    }) async {
      await tester.enterText(
        fieldIn(ChangePasswordScreen.oldPasswordFieldKey),
        old,
      );
      await tester.enterText(
        fieldIn(ChangePasswordScreen.passwordFieldKey),
        password,
      );
      await tester.enterText(
        fieldIn(ChangePasswordScreen.confirmationFieldKey),
        confirmation ?? password,
      );
      await tapAndSettle(tester, buttonIn(ChangePasswordScreen.submitKey));
    }

    testWidgets('checks required, format and the repeat on the device', (
      tester,
    ) async {
      final env = profileEnv();
      await open(tester, env);

      await fill(tester, old: '', password: 'short');
      expect(
        errorOf(tester, ChangePasswordScreen.oldPasswordFieldKey),
        AuthErrorText.passwordRequired,
      );
      expect(
        errorOf(tester, ChangePasswordScreen.passwordFieldKey),
        AuthErrorText.passwordFormat,
      );

      await fill(tester, confirmation: 'different1!');
      expect(
        errorOf(tester, ChangePasswordScreen.confirmationFieldKey),
        AuthErrorText.passwordsMismatch,
      );
      expect(env.backend.requestsTo(patchPassword), isEmpty);
    });

    testWidgets('a wrong old password is marked on its field', (tester) async {
      await open(
        tester,
        profileEnv({
          patchPassword: FakeResponse.error(422, 'INVALID_OLD_PASSWORD'),
        }),
      );

      await fill(tester);

      expect(
        errorOf(tester, ChangePasswordScreen.oldPasswordFieldKey),
        ProfileText.invalidOldPassword,
      );
    });

    testWidgets('sends the old and new password only and returns', (
      tester,
    ) async {
      final env = profileEnv({
        patchPassword: const FakeResponse(200, {'message': 'ok'}),
      });
      final container = await open(tester, env);

      await fill(tester);

      expect(lastBody(env, patchPassword), {
        'old_password': 'oldpass1!',
        'password': 'newpass1!',
      });
      expect(currentPath(container), AppRoutes.profile);
      expect(find.text(ProfileText.passwordChanged), findsOneWidget);
      // The session survives a password change.
      expect(env.tokenStorage.token, 'token');
    });

    testWidgets('rate limited: asks to wait', (tester) async {
      await open(
        tester,
        profileEnv({
          patchPassword: FakeResponse.error(
            429,
            'TOO_MANY_REQUESTS',
            headers: {'retry-after': '120'},
          ),
        }),
      );

      await fill(tester);

      expect(
        find.text(
          AuthErrorText.tooManyAttemptsWait(const Duration(minutes: 2)),
        ),
        findsOneWidget,
      );
    });
  });
}
