import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/features/auth/index.dart';

import '../../helpers/app_harness.dart';

// Goldens at the Figma frame size (393×852 @1x), as in auth_goldens_test.
// Record them in the Linux container CI runs on (see the README section
// "Golden tests"), not on macOS — glyph rendering differs between them.

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

void main() {
  testWidgets('Are you graduate — Figma 139:5310', (tester) async {
    await _pumpScreen(tester, const GraduateQuestionScreen());

    await expectLater(
      find.byType(GraduateQuestionScreen),
      matchesGoldenFile('goldens/graduate_question.png'),
    );
  });

  testWidgets('Graduate data — Figma 139:5303', (tester) async {
    await _pumpScreen(tester, const GraduateFormScreen());

    await expectLater(
      find.byType(GraduateFormScreen),
      matchesGoldenFile('goldens/graduate_form.png'),
    );
  });

  testWidgets('Graduate data, required fields + consents', (tester) async {
    await _pumpScreen(tester, const GraduateFormScreen());
    await tester.ensureVisible(buttonIn(GraduateFormScreen.submitKey));
    await tester.tap(buttonIn(GraduateFormScreen.submitKey));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(GraduateFormScreen),
      matchesGoldenFile('goldens/graduate_form_errors.png'),
    );
  });

  testWidgets('Status confirmed — Figma 139:5307', (tester) async {
    await _pumpScreen(tester, const GraduateConfirmedScreen());

    await expectLater(
      find.byType(GraduateConfirmedScreen),
      matchesGoldenFile('goldens/graduate_confirmed.png'),
    );
  });

  testWidgets('Status not confirmed — Figma 139:5306', (tester) async {
    await _pumpScreen(tester, const GraduateNotConfirmedScreen());

    await expectLater(
      find.byType(GraduateNotConfirmedScreen),
      matchesGoldenFile('goldens/graduate_not_confirmed.png'),
    );
  });
}
