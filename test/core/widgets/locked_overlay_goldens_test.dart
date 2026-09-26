import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';

import '../../helpers/app_harness.dart';

// LockedOverlay presets at the Figma frame size (393×852 @1x). Record in the
// Linux container CI runs on (see the README section "Golden tests").

Future<void> _pump(WidgetTester tester, Widget overlay) async {
  useFigmaViewport(tester, pixelRatio: 1);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: overlay),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final presets = <String, Widget>{
    'signed_out': LockedOverlay.signedOut(
      onSignIn: () {},
      onCreateAccount: () {},
    ),
    'inactive_account': LockedOverlay.inactiveAccount(onRestoreAccess: () {}),
    'graduate_only': LockedOverlay.graduateOnly(onVerify: () {}),
    // Figma 131:3602, without the page background image.
    'locked_day': const LockedOverlay.lockedDay(),
  };

  for (final MapEntry(key: name, value: overlay) in presets.entries) {
    testWidgets('LockedOverlay — $name', (tester) async {
      await _pump(tester, overlay);

      await expectLater(
        find.byType(LockedOverlay),
        matchesGoldenFile('goldens/locked_overlay_$name.png'),
      );
    });
  }
}
