import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/home/index.dart';
import 'package:hoffman/features/meditations/index.dart';

import '../../helpers/app_harness.dart';
import 'meditations_harness.dart';

void main() {
  group('ТЗ 5.4.1 — список медитаций', () {
    testWidgets('featured heads the list like on home, the others are '
        'meditation cards', (tester) async {
      final harness = MeditationsHarness();
      final container = await harness.open(tester, AppRoutes.meditations);

      expect(currentPath(container), AppRoutes.meditations);
      expect(find.byType(MeditationsScreen), findsOneWidget);
      expect(find.byType(AppTabBar), findsOneWidget);
      expect(harness.backend.requestsTo(getMeditations), hasLength(1));

      final cover = tester.widget<HomeSectionCover>(
        find.byType(HomeSectionCover),
      );
      expect(cover.title, HomeText.meditations);
      expect(cover.underStatusBar, isTrue);
      expect(tester.getTopLeft(find.byType(HomeSectionCover)).dy, 0);
      expect(cover.onSeeAll, isNull);
      expect(cover.onTap, isNotNull);
      expect(find.byType(AppBadge), findsNothing);

      final featured = tester.widget<HomeFeaturedItem>(
        find.byKey(MeditationsScreen.featuredKey),
      );
      expect(featured.title, 'Утренняя медитация');
      expect(featured.actionLabel, MeditationsText.start);

      final cards = tester
          .widgetList<MeditationCard>(
            find.byType(MeditationCard, skipOffstage: false),
          )
          .toList();
      expect(cards.map((c) => c.title), [
        'Visioning – образ будущего',
        'Закрытая практика',
      ]);
      expect(cards.map((c) => c.duration), ['25 минут', '25 минут']);
      // The locked one looks like the others: no lock on the list.
      expect(find.byType(LockedMark, skipOffstage: false), findsNothing);
      expect(find.byIcon(Icons.lock, skipOffstage: false), findsNothing);
      // featured is never repeated among the cards.
      expect(find.text('Утренняя медитация'), findsOneWidget);
    });

    testWidgets('without featured: no highlighted item, the cover is '
        'inert', (tester) async {
      final harness = MeditationsHarness({
        getMeditations: catalogResponse(null, [
          meditationJson(2, 'Вечерняя'),
          meditationJson(4, 'Дневная'),
        ]),
      });
      await harness.open(tester, AppRoutes.meditations);

      expect(find.byType(HomeFeaturedItem), findsNothing);
      expect(
        tester.widget<HomeSectionCover>(find.byType(HomeSectionCover)).onTap,
        isNull,
      );
      expect(
        find.byType(MeditationCard, skipOffstage: false),
        findsNWidgets(2),
      );
    });

    testWidgets('an empty catalog says so', (tester) async {
      final harness = MeditationsHarness({
        getMeditations: catalogResponse(null),
      });
      await harness.open(tester, AppRoutes.meditations);

      expect(find.byType(HomeSectionEmpty), findsOneWidget);
      expect(find.byType(MeditationCard), findsNothing);
    });

    testWidgets('featured, its cover and each card (locked too) open the '
        'meditation', (tester) async {
      final harness = MeditationsHarness();
      final container = await harness.open(tester, AppRoutes.meditations);
      final router = container.read(appRouterProvider);

      Future<void> expectOpens(Finder target, int id) async {
        await tapAndSettle(tester, target);
        expect(currentPath(container), AppRoutes.meditation(id));
        expect(find.byType(MeditationDetailScreen), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
        expect(currentPath(container), AppRoutes.meditations);
      }

      await expectOpens(
        find.descendant(
          of: find.byKey(MeditationsScreen.featuredKey),
          matching: find.widgetWithText(AppButton, MeditationsText.start),
        ),
        1,
      );
      await expectOpens(find.byKey(MeditationsScreen.coverKey), 1);
      await expectOpens(find.byKey(MeditationsScreen.cardKey(2)), 2);
      await expectOpens(find.byKey(MeditationsScreen.cardKey(3)), 3);
    });

    testWidgets('offline: the error state with a retry, then the list', (
      tester,
    ) async {
      final harness = MeditationsHarness();
      await harness.open(tester, AppRoutes.home);
      harness.backend.offline = true;

      await tester.tap(find.byIcon(Icons.play_circle_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.text(AuthErrorText.network), findsOneWidget);

      harness.backend.offline = false;
      await tapAndSettle(tester, find.byType(AppButton));

      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.byType(HomeFeaturedItem), findsOneWidget);
    });

    testWidgets('a server error has its own text', (tester) async {
      final harness = MeditationsHarness({
        getMeditations: FakeResponse.error(500, 'SERVER_ERROR'),
      });
      await harness.open(tester, AppRoutes.meditations);

      expect(find.text(MeditationsText.loadFailed), findsOneWidget);
    });
  });
}
