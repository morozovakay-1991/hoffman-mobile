import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/features/auth/index.dart';

import '../../helpers/app_harness.dart';

// Goldens at the Figma frame size (393×852 @1x, 49px status bar, 34px home
// indicator) so they can be laid over the mockups 1:1. Regenerate with
// `flutter test --update-goldens test/features/auth/auth_goldens_test.dart`.

Future<void> _pumpScreen(WidgetTester tester, Widget screen) async {
  useFigmaViewport(tester, pixelRatio: 1);
  await tester.pumpWidget(
    ProviderScope(
      overrides: TestEnvironment().overrides,
      child: MaterialApp(
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester, Key key) async {
  await tester.ensureVisible(buttonIn(key));
  await tester.tap(buttonIn(key));
  await tester.pumpAndSettle();
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Login — Figma 139:5312', (tester) async {
    await _pumpScreen(tester, const LoginScreen());

    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login.png'),
    );
  });

  testWidgets('Login, required fields + consents — Figma 139:5287/139:5285', (
    tester,
  ) async {
    await _pumpScreen(tester, const LoginScreen());
    await _submit(tester, LoginScreen.submitKey);

    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_errors.png'),
    );
  });

  testWidgets('Register — Figma 139:5311', (tester) async {
    await _pumpScreen(tester, const RegisterScreen());

    await expectLater(
      find.byType(RegisterScreen),
      matchesGoldenFile('goldens/register.png'),
    );
  });

  testWidgets('Register, field errors — Figma 139:5297/139:5286/139:5284', (
    tester,
  ) async {
    await _pumpScreen(tester, const RegisterScreen());
    await tester.enterText(fieldIn(RegisterScreen.nameFieldKey), 'Kate');
    await tester.enterText(fieldIn(RegisterScreen.emailFieldKey), 'kate@');
    await tester.enterText(fieldIn(RegisterScreen.passwordFieldKey), 'short');
    await _submit(tester, RegisterScreen.submitKey);

    await expectLater(
      find.byType(RegisterScreen),
      matchesGoldenFile('goldens/register_errors.png'),
    );
  });
}
