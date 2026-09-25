import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/features/auth/index.dart';

import '../../helpers/app_harness.dart';

const _forgot = 'POST /api/v1/auth/password/forgot';
const _verify = 'POST /api/v1/auth/password/verify-code';
const _reset = 'POST /api/v1/auth/password/reset';

const _ok = FakeResponse(200, {'message': 'ok'});

FakeBackend _backend({FakeResponse verify = _ok, FakeResponse reset = _ok}) =>
    FakeBackend({_forgot: _ok, _verify: verify, _reset: reset});

Future<ProviderContainer> _openStep1(
  WidgetTester tester,
  TestEnvironment env,
) async {
  final container = await pumpApp(tester, env);
  await tapAndSettle(tester, find.text('Забыли пароль?'));
  expect(currentPath(container), AppRoutes.forgotPassword);
  return container;
}

Future<void> _submitEmail(
  WidgetTester tester, {
  String email = 'kate@example.com',
  bool acceptConsents = true,
}) async {
  await tester.enterText(fieldIn(ResetEmailScreen.emailFieldKey), email);
  if (acceptConsents) {
    await tapAndSettle(tester, find.byKey(const ValueKey('consent-privacy')));
    await tapAndSettle(
      tester,
      find.byKey(const ValueKey('consent-personal-data')),
    );
  }
  await tapAndSettle(tester, buttonIn(ResetEmailScreen.submitKey));
}

Future<ProviderContainer> _openStep2(
  WidgetTester tester,
  TestEnvironment env,
) async {
  final container = await _openStep1(tester, env);
  await _submitEmail(tester);
  expect(currentPath(container), AppRoutes.forgotPasswordCode);
  return container;
}

Future<void> _submitCode(WidgetTester tester, [String code = '123456']) async {
  await tester.enterText(fieldIn(ResetCodeScreen.codeFieldKey), code);
  await tapAndSettle(tester, buttonIn(ResetCodeScreen.submitKey));
}

void main() {
  group('step 1 — email (139:5305)', () {
    testWidgets('139:5295 — empty email', (tester) async {
      final env = TestEnvironment(backend: _backend());
      await _openStep1(tester, env);

      await _submitEmail(tester, email: '');

      expect(
        errorOf(tester, ResetEmailScreen.emailFieldKey),
        AuthErrorText.emailRequired,
      );
      expect(env.backend.requestsTo(_forgot), isEmpty);
    });

    testWidgets('139:5294 — malformed email', (tester) async {
      final env = TestEnvironment(backend: _backend());
      await _openStep1(tester, env);

      await _submitEmail(tester, email: 'kate@');

      expect(
        errorOf(tester, ResetEmailScreen.emailFieldKey),
        AuthErrorText.emailInvalid,
      );
      expect(env.backend.requestsTo(_forgot), isEmpty);
    });

    testWidgets('consents are required', (tester) async {
      final env = TestEnvironment(backend: _backend());
      await _openStep1(tester, env);

      await _submitEmail(tester, acceptConsents: false);

      expect(find.text(AuthErrorText.consentRequired), findsOneWidget);
      expect(env.backend.requestsTo(_forgot), isEmpty);
    });

    testWidgets('139:5293 — unknown email (reported by verify-code) brings '
        'the user back to step 1', (tester) async {
      final env = TestEnvironment(
        backend: _backend(verify: FakeResponse.error(404, 'EMAIL_NOT_FOUND')),
      );
      final container = await _openStep2(tester, env);

      await _submitCode(tester);

      expect(currentPath(container), AppRoutes.forgotPassword);
      expect(
        errorOf(tester, ResetEmailScreen.emailFieldKey),
        AuthErrorText.emailNotFound,
      );

      // Editing the email clears it.
      await tester.enterText(
        fieldIn(ResetEmailScreen.emailFieldKey),
        'other@example.com',
      );
      await tester.pump();
      expect(errorOf(tester, ResetEmailScreen.emailFieldKey), isNull);
    });
  });

  group('step 2 — code (139:5304)', () {
    testWidgets('sends the code and shows the email and the 59s timer', (
      tester,
    ) async {
      final env = TestEnvironment(backend: _backend());
      await _openStep2(tester, env);

      expect(env.backend.requestsTo(_forgot).single.data, {
        'email': 'kate@example.com',
      });
      expect(
        find.text('Мы отправили 6-значный код на kate@example.com'),
        findsOneWidget,
      );
      expect(find.text('Отправить еще раз через 59с'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Отправить еще раз через 58с'), findsOneWidget);
    });

    testWidgets('resend is available only after 59 seconds and restarts '
        'the timer', (tester) async {
      final env = TestEnvironment(backend: _backend());
      await _openStep2(tester, env);

      await tester.pump(const Duration(seconds: 58));
      expect(find.text('Отправить еще раз через 1с'), findsOneWidget);
      expect(find.byKey(ResetCodeScreen.resendKey), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(ResetCodeScreen.resendKey), findsOneWidget);

      await tapAndSettle(tester, find.byKey(ResetCodeScreen.resendKey));

      expect(env.backend.requestsTo(_forgot), hasLength(2));
      expect(find.text('Отправить еще раз через 59с'), findsOneWidget);
    });

    testWidgets('139:5292 — wrong code', (tester) async {
      final env = TestEnvironment(
        backend: _backend(verify: FakeResponse.error(422, 'INVALID_CODE')),
      );
      await _openStep2(tester, env);

      await _submitCode(tester);

      expect(
        errorOf(tester, ResetCodeScreen.codeFieldKey),
        AuthErrorText.invalidCode,
      );
    });

    testWidgets('139:5292 — an incomplete code is rejected locally', (
      tester,
    ) async {
      final env = TestEnvironment(backend: _backend());
      await _openStep2(tester, env);

      await _submitCode(tester, '123');

      expect(
        errorOf(tester, ResetCodeScreen.codeFieldKey),
        AuthErrorText.invalidCode,
      );
      expect(env.backend.requestsTo(_verify), isEmpty);
    });

    testWidgets('139:5291 — expired code', (tester) async {
      final env = TestEnvironment(
        backend: _backend(verify: FakeResponse.error(422, 'CODE_EXPIRED')),
      );
      await _openStep2(tester, env);

      await _submitCode(tester);

      expect(
        errorOf(tester, ResetCodeScreen.codeFieldKey),
        AuthErrorText.codeExpired,
      );
    });

    testWidgets('139:5290 — rate limited (429 + Retry-After) shows the wait', (
      tester,
    ) async {
      final env = TestEnvironment(
        backend: _backend(
          verify: FakeResponse.error(
            429,
            'TOO_MANY_REQUESTS',
            headers: {'retry-after': '150'},
          ),
        ),
      );
      await _openStep2(tester, env);

      await _submitCode(tester);

      expect(
        errorOf(tester, ResetCodeScreen.codeFieldKey),
        'Слишком много попыток. Попробуйте через 3 минуты',
      );
    });

    testWidgets('139:5290 — TOO_MANY_ATTEMPTS asks for a new code', (
      tester,
    ) async {
      final env = TestEnvironment(
        backend: _backend(verify: FakeResponse.error(422, 'TOO_MANY_ATTEMPTS')),
      );
      await _openStep2(tester, env);

      await _submitCode(tester);

      expect(
        errorOf(tester, ResetCodeScreen.codeFieldKey),
        AuthErrorText.tooManyAttemptsNewCode,
      );
    });

    testWidgets('"Изменить Email" returns to step 1 with the email kept', (
      tester,
    ) async {
      final env = TestEnvironment(backend: _backend());
      final container = await _openStep2(tester, env);

      await tapAndSettle(tester, find.text('Изменить Email'));

      expect(currentPath(container), AppRoutes.forgotPassword);
      expect(find.text('kate@example.com'), findsOneWidget);
    });

    testWidgets('opening step 2 directly redirects to step 1', (tester) async {
      final env = TestEnvironment(backend: _backend());
      final container = await pumpApp(tester, env);

      container.read(appRouterProvider).go(AppRoutes.forgotPasswordCode);
      await tester.pumpAndSettle();

      expect(currentPath(container), AppRoutes.forgotPassword);
    });
  });

  group('step 3 — new password (139:5302)', () {
    Future<ProviderContainer> openStep3(
      WidgetTester tester,
      TestEnvironment env,
    ) async {
      final container = await _openStep2(tester, env);
      await _submitCode(tester);
      expect(currentPath(container), AppRoutes.forgotPasswordNewPassword);
      return container;
    }

    Future<void> submit(
      WidgetTester tester,
      String password,
      String confirmation,
    ) async {
      await tester.enterText(
        fieldIn(ResetNewPasswordScreen.passwordFieldKey),
        password,
      );
      await tester.enterText(
        fieldIn(ResetNewPasswordScreen.confirmationFieldKey),
        confirmation,
      );
      await tapAndSettle(tester, buttonIn(ResetNewPasswordScreen.submitKey));
    }

    testWidgets('139:5284 — passwords do not match', (tester) async {
      final env = TestEnvironment(backend: _backend());
      await openStep3(tester, env);

      await submit(tester, 'secret1!', 'secret2!');

      expect(
        errorOf(tester, ResetNewPasswordScreen.confirmationFieldKey),
        AuthErrorText.passwordsMismatch,
      );
      expect(env.backend.requestsTo(_reset), isEmpty);
    });

    testWidgets('139:5286 wording — weak password', (tester) async {
      final env = TestEnvironment(backend: _backend());
      await openStep3(tester, env);

      await submit(tester, 'password', 'password');

      expect(
        errorOf(tester, ResetNewPasswordScreen.passwordFieldKey),
        AuthErrorText.passwordFormat,
      );
      expect(env.backend.requestsTo(_reset), isEmpty);
    });

    testWidgets('success → "Пароль изменен" (139:5309) → Login', (
      tester,
    ) async {
      final env = TestEnvironment(backend: _backend());
      final container = await openStep3(tester, env);

      await submit(tester, 'secret1!', 'secret1!');

      expect(env.backend.requestsTo(_reset).single.data, {
        'email': 'kate@example.com',
        'code': '123456',
        'password': 'secret1!',
        'password_confirmation': 'secret1!',
      });
      expect(currentPath(container), AppRoutes.forgotPasswordDone);
      expect(find.text('Пароль изменен'), findsOneWidget);
      // The email and code are not kept around after the flow.
      final flow = container.read(resetPasswordControllerProvider);
      expect(flow.email, isNull);
      expect(flow.code, isNull);

      await tapAndSettle(tester, find.text('Войти'));

      expect(currentPath(container), AppRoutes.login);
    });
  });
}
