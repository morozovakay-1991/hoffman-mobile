import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/features/auth/index.dart';

import '../../helpers/app_harness.dart';

Future<void> _acceptConsents(WidgetTester tester) async {
  await tapAndSettle(tester, find.byKey(const ValueKey('consent-privacy')));
  await tapAndSettle(
    tester,
    find.byKey(const ValueKey('consent-personal-data')),
  );
}

Future<void> _fill(
  WidgetTester tester, {
  String? email,
  String? password,
}) async {
  if (email != null) {
    await tester.enterText(fieldIn(LoginScreen.emailFieldKey), email);
  }
  if (password != null) {
    await tester.enterText(fieldIn(LoginScreen.passwordFieldKey), password);
  }
  await tester.pump();
}

Future<void> _submit(WidgetTester tester) =>
    tapAndSettle(tester, buttonIn(LoginScreen.submitKey));

void main() {
  testWidgets('139:5287 — empty fields show "Заполните email/пароль"', (
    tester,
  ) async {
    final env = TestEnvironment();
    await pumpApp(tester, env);
    await _acceptConsents(tester);

    await _submit(tester);

    expect(
      errorOf(tester, LoginScreen.emailFieldKey),
      AuthErrorText.emailRequired,
    );
    expect(
      errorOf(tester, LoginScreen.passwordFieldKey),
      AuthErrorText.passwordRequired,
    );
    expect(env.backend.requests, isEmpty);
  });

  testWidgets('139:5297 — malformed email shows "Неверный формат email"', (
    tester,
  ) async {
    final env = TestEnvironment();
    await pumpApp(tester, env);
    await _acceptConsents(tester);
    await _fill(tester, email: 'kate@example', password: 'secret1!');

    await _submit(tester);

    expect(
      errorOf(tester, LoginScreen.emailFieldKey),
      AuthErrorText.emailInvalid,
    );
    expect(env.backend.requests, isEmpty);
  });

  testWidgets('139:5285 — unchecked consents block the login', (tester) async {
    final env = TestEnvironment();
    await pumpApp(tester, env);
    await _fill(tester, email: 'kate@example.com', password: 'secret1!');
    // Only one of the two boxes.
    await tapAndSettle(tester, find.byKey(const ValueKey('consent-privacy')));

    await _submit(tester);

    expect(find.text(AuthErrorText.consentRequired), findsOneWidget);
    expect(env.backend.requests, isEmpty);

    // Checking the second box clears the message.
    await tapAndSettle(
      tester,
      find.byKey(const ValueKey('consent-personal-data')),
    );
    expect(find.text(AuthErrorText.consentRequired), findsNothing);
  });

  testWidgets('139:5298 — backend 401 shows "Неверный email или пароль"', (
    tester,
  ) async {
    final env = TestEnvironment(
      backend: FakeBackend({
        'POST /api/v1/auth/login': FakeResponse.error(
          401,
          'INVALID_CREDENTIALS',
        ),
      }),
    );
    final container = await pumpApp(tester, env);
    await _acceptConsents(tester);
    await _fill(tester, email: 'kate@example.com', password: 'wrong-pass');

    await _submit(tester);

    expect(
      errorOf(tester, LoginScreen.passwordFieldKey),
      AuthErrorText.invalidCredentials,
    );
    expect(currentPath(container), AppRoutes.login);
    expect(env.tokenStorage.token, isNull);
  });

  testWidgets('success stores the token and opens home', (tester) async {
    final env = TestEnvironment(
      backend: FakeBackend({'POST /api/v1/auth/login': authSuccess}),
    );
    final container = await pumpApp(tester, env);
    await _acceptConsents(tester);
    await _fill(tester, email: ' kate@example.com ', password: 'secret1!');

    await _submit(tester);

    final request = env.backend.requestsTo('POST /api/v1/auth/login').single;
    expect(request.data, {'email': 'kate@example.com', 'password': 'secret1!'});
    expect(env.tokenStorage.token, 'new-token');
    expect(currentPath(container), AppRoutes.home);
  });

  testWidgets('offline login shows a message instead of hanging', (
    tester,
  ) async {
    final env = TestEnvironment()..backend.offline = true;
    final container = await pumpApp(tester, env);
    await _acceptConsents(tester);
    await _fill(tester, email: 'kate@example.com', password: 'secret1!');

    await _submit(tester);

    expect(find.text(AuthErrorText.network), findsOneWidget);
    expect(currentPath(container), AppRoutes.login);
  });

  testWidgets('registration_enabled = true shows the sign-up link', (
    tester,
  ) async {
    final container = await pumpApp(tester, TestEnvironment());

    await tapAndSettle(tester, find.text('Зарегистрируйтесь'));

    expect(currentPath(container), AppRoutes.register);
  });

  testWidgets('registration_enabled = false hides the sign-up link and '
      'blocks /register', (tester) async {
    final container = await pumpApp(
      tester,
      TestEnvironment(registrationEnabled: false),
    );

    expect(find.text('Зарегистрируйтесь'), findsNothing);

    container.read(appRouterProvider).go(AppRoutes.register);
    await tester.pumpAndSettle();

    expect(currentPath(container), AppRoutes.login);
    expect(find.byType(RegisterScreen), findsNothing);
  });

  testWidgets('social sign-in is laid out but invisible', (tester) async {
    await pumpApp(tester, TestEnvironment());

    final label = find.text('Войти с');
    expect(label.hitTestable(), findsNothing);
    final visibility = tester.widget<Visibility>(
      find.ancestor(of: label, matching: find.byType(Visibility)).first,
    );
    expect(visibility.visible, isFalse);
    expect(visibility.maintainSize, isTrue);
  });
}
