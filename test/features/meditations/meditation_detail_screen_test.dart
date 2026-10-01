import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/meditations/index.dart';

import '../../helpers/app_harness.dart';
import 'meditations_harness.dart';

void main() {
  group('ТЗ 5.4.2 — детальный экран медитации', () {
    testWidgets('shows the cover, title, duration, both descriptions and '
        'the share icon', (tester) async {
      final harness = MeditationsHarness();
      await harness.open(tester, AppRoutes.meditation(1));

      expect(harness.backend.requestsTo(getMeditation(1)), hasLength(1));
      expect(find.text('Утренняя медитация'), findsOneWidget);
      expect(find.text('25 минут'), findsOneWidget);
      expect(find.text('Описание: Утренняя медитация'), findsOneWidget);
      expect(
        find.textContaining('Полное описание практики', findRichText: true),
        findsOneWidget,
      );
      expect(find.byType(MeditationShareButton), findsOneWidget);
      expect(
        find.byKey(MeditationDetailScreen.playerButtonKey),
        findsOneWidget,
      );
      // Nothing is played before the player opens.
      expect(harness.backend.requestsTo(getAudio(1)), isEmpty);
    });

    testWidgets('the player button pushes /meditations/:id/player', (
      tester,
    ) async {
      final harness = MeditationsHarness();
      final container = await harness.open(tester, AppRoutes.meditation(1));
      expectGridButton(
        tester,
        find.byKey(MeditationDetailScreen.playerButtonKey),
      );

      await tapAndSettle(
        tester,
        find.byKey(MeditationDetailScreen.playerButtonKey),
      );

      expect(currentPath(container), '${AppRoutes.meditation(1)}/player');
      expect(find.byType(MeditationPlayerScreen), findsOneWidget);

      container.read(appRouterProvider).pop();
      await tester.pumpAndSettle();
      expect(currentPath(container), AppRoutes.meditation(1));
    });

    testWidgets('share sends the title and the short description', (
      tester,
    ) async {
      final harness = MeditationsHarness();
      await harness.open(tester, AppRoutes.meditation(1));

      await tapAndSettle(tester, find.byType(MeditationShareButton));

      expect(harness.shared, hasLength(1));
      expect(
        harness.shared.single.text,
        'Утренняя медитация\n\nОписание: Утренняя медитация',
      );
      expect(harness.shared.single.subject, 'Утренняя медитация');
      expect(harness.shared.single.origin, isNotNull);
    });

    testWidgets('403 ACCESS_DENIED shows the lock instead of the content '
        'and never offers the player', (tester) async {
      final harness = MeditationsHarness({getMeditation(3): accessDenied});
      await harness.open(tester, AppRoutes.meditation(3));

      expect(tester.takeException(), isNull);
      expect(find.byKey(MeditationLockedView.viewKey), findsOneWidget);
      expect(
        find.text(LockedOverlayText.graduatesOnlySectionTitle),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.byKey(MeditationDetailScreen.playerButtonKey), findsNothing);
      expect(find.byType(MeditationShareButton), findsNothing);
      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(harness.backend.requestsTo(getAudio(3)), isEmpty);
    });

    testWidgets('the lock screen follows Figma 139:5278', (tester) async {
      final harness = MeditationsHarness({getMeditation(3): accessDenied});
      await harness.open(tester, AppRoutes.meditation(3));

      final screen = tester.getRect(find.byKey(MeditationLockedView.viewKey));
      final title = find.text(LockedOverlayText.graduatesOnlySectionTitle);
      final lock = find.byIcon(Icons.lock);

      // "Этот раздел доступен только для выпускников Процесса Хоффмана":
      // Golos Text 20/38, centered, in the 218px box of the mockup — whole
      // 38px lines, more of them than the mockup's two.
      final text = tester.widget<Text>(title);
      expect(text.textAlign, TextAlign.center);
      expect(text.style?.fontSize, 20);
      expect(text.style?.fontWeight, FontWeight.w400);
      expect(text.style!.fontSize! * text.style!.height!, closeTo(38, 0.01));
      final titleRect = tester.getRect(title);
      expect(titleRect.width, lessThanOrEqualTo(LockedOverlay.titleMaxWidth));
      final lines = titleRect.height / 38;
      expect(lines, closeTo(lines.roundToDouble(), 0.01));
      expect(lines.round(), greaterThan(2));

      // The 20px black lock 16px under the text; both centered on screen.
      final lockRect = tester.getRect(lock);
      expect(lockRect.size, const Size.square(20));
      expect(tester.widget<Icon>(lock).color, AppColors.basicBlack);
      expect(lockRect.top - titleRect.bottom, closeTo(AppSpacing.md, 0.5));
      expect(titleRect.center.dx, closeTo(screen.center.dx, 0.5));
      expect(lockRect.center.dx, closeTo(screen.center.dx, 0.5));
      // The block keeps the mockup's place between the back bar and the tab
      // bar (393×852 frame: 89…771): the two-line block from y = 356 there,
      // this taller one the same fraction of the free space down.
      final area = tester.getRect(find.byType(LockedOverlay));
      expect((area.top, area.bottom), (89, 771));
      final free = area.height - (lockRect.bottom - titleRect.top);
      expect(
        titleRect.top - area.top,
        closeTo(free * (1 + MeditationLockedView.blockAlignment.y) / 2, 0.5),
      );
      expect(
        (area.height - 112) * (1 + MeditationLockedView.blockAlignment.y) / 2,
        closeTo(356 - 89, 0.5),
      );

      // The flower background behind it all, the back chevron on top, the
      // tab bar under it; no buttons, share or other lock.
      final background = tester.getRect(find.byType(FlowerBackground));
      expect(background, screen);
      expect(find.byIcon(MeditationTopBar.backIcon), findsOneWidget);
      expect(
        tester.getCenter(find.byIcon(MeditationTopBar.backIcon)).dy,
        lessThan(titleRect.top),
      );
      expect(find.byType(AppTabBar), findsOneWidget);
      expect(find.byType(AppButton), findsNothing);
      expect(find.byType(LockedMark), findsNothing);
      expect(find.text(LockedOverlayText.restrictedTitle), findsNothing);
    });

    testWidgets('the back chevron of the lock screen leaves it', (
      tester,
    ) async {
      final harness = MeditationsHarness({getMeditation(3): accessDenied});
      final container = await harness.open(tester, AppRoutes.meditations);
      await tapAndSettle(tester, find.byKey(MeditationsScreen.cardKey(3)));
      expect(find.byKey(MeditationLockedView.viewKey), findsOneWidget);

      await tapAndSettle(tester, find.byIcon(MeditationTopBar.backIcon));

      expect(find.byKey(MeditationLockedView.viewKey), findsNothing);
      expect(currentPath(container), AppRoutes.meditations);
    });

    testWidgets('a locked card of the list leads to the lock screen', (
      tester,
    ) async {
      final harness = MeditationsHarness({getMeditation(3): accessDenied});
      await harness.open(tester, AppRoutes.meditations);

      await tapAndSettle(tester, find.byKey(MeditationsScreen.cardKey(3)));

      expect(find.byKey(MeditationLockedView.viewKey), findsOneWidget);
    });

    testWidgets('offline: a retry, then the content', (tester) async {
      final harness = MeditationsHarness();
      final container = await pumpApp(tester, harness.env);
      harness.backend.offline = true;
      unawaited(
        container.read(appRouterProvider).push(AppRoutes.meditation(1)),
      );
      await tester.pumpAndSettle();

      expect(find.text(AuthErrorText.network), findsOneWidget);

      harness.backend.offline = false;
      await tapAndSettle(tester, find.byType(AppButton));

      expect(find.text('Утренняя медитация'), findsOneWidget);
    });

    testWidgets('a non-numeric id says it is not found without a request', (
      tester,
    ) async {
      final harness = MeditationsHarness();
      await harness.open(tester, '/meditations/abc');

      expect(find.text(MeditationsText.notFound), findsOneWidget);
      expect(
        harness.backend.requests.where(
          (r) => r.path.startsWith('/api/v1/meditations'),
        ),
        isEmpty,
      );
    });

    testWidgets('an unknown meditation says it is not found', (tester) async {
      final harness = MeditationsHarness();
      await harness.open(tester, AppRoutes.meditation(99));

      expect(find.text(MeditationsText.notFound), findsOneWidget);
      expect(find.byType(ErrorStateWidget), findsNothing);
    });
  });
}
