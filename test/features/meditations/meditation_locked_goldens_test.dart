import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/meditations/index.dart';
import 'package:hoffman/main.dart';

import '../../helpers/app_harness.dart';
import 'meditations_harness.dart';

// The locked meditation, Figma 139:5278 (`Closed section/content`), with the
// tab bar, at the Figma frame size (393×852 @1x). Record in the Linux
// container CI runs on (see the README section "Golden tests").

void main() {
  testWidgets('MeditationLockedView — Figma 139:5278', (tester) async {
    useFigmaViewport(tester, pixelRatio: 1);
    final harness = MeditationsHarness({getMeditation(3): accessDenied});
    final container = harness.env.createContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HoffmanApp(),
      ),
    );
    await finishSplash(tester);
    final router = container.read(appRouterProvider)..go(AppRoutes.meditations);
    await tester.pumpAndSettle();
    unawaited(router.push<Object?>(AppRoutes.meditation(3)));
    await tester.pumpAndSettle();
    // Asset images decode outside the fake clock.
    await tester.runAsync(
      () => precacheImage(
        const AssetImage(FlowerBackground.asset),
        tester.element(find.byKey(MeditationLockedView.viewKey)),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(HoffmanApp),
      matchesGoldenFile('goldens/meditation_locked.png'),
    );
  });
}
