import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/features/auth/index.dart';

import '../../helpers/app_harness.dart';

const _register = 'POST /api/v1/auth/register';

Future<ProviderContainer> _openRegister(
  WidgetTester tester,
  TestEnvironment env,
) async {
  final container = await pumpApp(tester, env);
  await tapAndSettle(tester, find.text('Зарегистрируйтесь'));
  expect(currentPath(container), AppRoutes.register);
  return container;
}

Future<void> _fill(
  WidgetTester tester, {
  String name = 'Kate',
  String email = 'kate@example.com',
  String password = 'secret1!',
  String? confirmation,
  bool acceptConsents = true,
}) async {
  await tester.enterText(fieldIn(RegisterScreen.nameFieldKey), name);
  await tester.enterText(fieldIn(RegisterScreen.emailFieldKey), email);
  await tester.enterText(fieldIn(RegisterScreen.passwordFieldKey), password);
  await tester.enterText(
    fieldIn(RegisterScreen.confirmationFieldKey),
    confirmation ?? password,
  );
  await tester.pump();
  if (acceptConsents) {
    await tapAndSettle(tester, find.byKey(const ValueKey('consent-privacy')));
    await tapAndSettle(
      tester,
      find.byKey(const ValueKey('consent-personal-data')),
    );
  }
}

Future<void> _submit(WidgetTester tester) =>
    tapAndSettle(tester, buttonIn(RegisterScreen.submitKey));

void main() {
  testWidgets('139:5297 — malformed email', (tester) async {
    final env = TestEnvironment();
    await _openRegister(tester, env);
    await _fill(tester, email: 'kate.example.com');

    await _submit(tester);

    expect(
      errorOf(tester, RegisterScreen.emailFieldKey),
      AuthErrorText.emailInvalid,
    );
    expect(env.backend.requestsTo(_register), isEmpty);
  });

  testWidgets(
    '139:5296 — backend "email taken" shows "Email уже используется"',
    (tester) async {
      final env = TestEnvironment(
        backend: FakeBackend({
          // Real hoffman-backend body for a `unique` failure.
          _register: FakeResponse.error(
            422,
            'VALIDATION_ERROR',
            fields: {
              'email': ['The email has already been taken.'],
            },
          ),
        }),
      );
      await _openRegister(tester, env);
      await _fill(tester);

      await _submit(tester);

      expect(
        errorOf(tester, RegisterScreen.emailFieldKey),
        AuthErrorText.emailTaken,
      );
      expect(env.tokenStorage.token, isNull);
    },
  );

  for (final weak in ['short1!', 'longpassword!', 'longpassword1']) {
    testWidgets('139:5286 — password "$weak" does not match the format', (
      tester,
    ) async {
      final env = TestEnvironment();
      await _openRegister(tester, env);
      await _fill(tester, password: weak);

      await _submit(tester);

      expect(
        errorOf(tester, RegisterScreen.passwordFieldKey),
        AuthErrorText.passwordFormat,
      );
      expect(env.backend.requestsTo(_register), isEmpty);
    });
  }

  testWidgets('139:5284 — passwords do not match', (tester) async {
    final env = TestEnvironment();
    await _openRegister(tester, env);
    await _fill(tester, confirmation: 'secret2!');

    await _submit(tester);

    expect(
      errorOf(tester, RegisterScreen.confirmationFieldKey),
      AuthErrorText.passwordsMismatch,
    );
    expect(env.backend.requestsTo(_register), isEmpty);
  });

  testWidgets('139:5285 — consents are required', (tester) async {
    final env = TestEnvironment();
    await _openRegister(tester, env);
    await _fill(tester, acceptConsents: false);

    await _submit(tester);

    expect(find.text(AuthErrorText.consentRequired), findsOneWidget);
    expect(env.backend.requestsTo(_register), isEmpty);
  });

  testWidgets('empty name is rejected (backend requires `name`)', (
    tester,
  ) async {
    final env = TestEnvironment();
    await _openRegister(tester, env);
    await _fill(tester, name: '  ');

    await _submit(tester);

    expect(
      errorOf(tester, RegisterScreen.nameFieldKey),
      AuthErrorText.nameRequired,
    );
  });

  testWidgets('success → /verification question → "Нет" → /home', (
    tester,
  ) async {
    final env = TestEnvironment(backend: FakeBackend({_register: authSuccess}));
    final container = await pumpApp(tester, env);
    await tapAndSettle(tester, find.text('Зарегистрируйтесь'));
    await _fill(tester, email: 'kate@example.com ');

    await _submit(tester);

    final request = env.backend.requestsTo(_register).single;
    expect(request.data, {
      'name': 'Kate',
      'email': 'kate@example.com',
      'password': 'secret1!',
      'password_confirmation': 'secret1!',
    });
    expect(env.tokenStorage.token, 'new-token');
    expect(currentPath(container), AppRoutes.verification);
    expect(find.byType(GraduateQuestionScreen), findsOneWidget);

    await tapAndSettle(tester, buttonIn(GraduateQuestionScreen.noKey));

    expect(currentPath(container), AppRoutes.home);
  });

  testWidgets('"Войти" goes back to Login', (tester) async {
    final env = TestEnvironment();
    await _openRegister(tester, env);

    await tapAndSettle(tester, find.text('Войти').last);

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
