import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/home/index.dart';
import 'package:hoffman/features/onboarding/index.dart';

import '../../helpers/app_harness.dart';
import 'home_harness.dart';

/// Taps the [AppButton] labelled [label] inside the widget [of].
Future<void> _tapButtonIn(WidgetTester tester, Finder of, String label) =>
    tapAndSettle(
      tester,
      find.descendant(of: of, matching: find.widgetWithText(AppButton, label)),
    );

void main() {
  group('612:7209 — Главная', () {
    testWidgets('greets the user by name and builds every section from a '
        'single GET /home', (tester) async {
      final env = homeEnv();
      final container = await pumpApp(tester, env);

      expect(currentPath(container), AppRoutes.home);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('hoffman'), findsOneWidget);
      expect(find.text('С возвращением, Kate'), findsOneWidget);
      expect(env.backend.requestsTo(getHome), hasLength(1));

      // Top to bottom: meditations, tools, topics, diary, articles.
      final covers = tester
          .widgetList<HomeSectionCover>(find.byType(HomeSectionCover))
          .map((c) => c.title);
      expect(covers, [
        HomeText.meditations,
        HomeText.tools,
        HomeText.topics,
        HomeText.diary,
        HomeText.articles,
      ]);

      // The first item of each section is highlighted, the rest are the
      // core/widgets content cards.
      final featured = tester
          .widgetList<HomeFeaturedItem>(find.byType(HomeFeaturedItem))
          .map((f) => f.title);
      expect(featured, [
        'Утренняя медитация',
        'Распознавание паттернов',
        'Я жертва',
        'Что такое Процесс Хоффмана?',
      ]);
      expect(
        tester
            .widget<MeditationCard>(
              find.byType(MeditationCard, skipOffstage: false),
            )
            .title,
        'Visioning – образ будущего',
      );
      expect(
        tester
            .widget<ToolListCard>(
              find.byType(ToolListCard, skipOffstage: false),
            )
            .tag,
        'выражение',
      );
      expect(
        tester
            .widget<ThemeListCard>(
              find.byType(ThemeListCard, skipOffstage: false),
            )
            .title,
        'Границы',
      );
      final article = tester.widget<ArticleListCard>(
        find.byType(ArticleListCard, skipOffstage: false),
      );
      expect(article.title, '«Навсегда твой» или про роли в семье');
      expect(article.date, 'Март, 2025');

      // The duration of the featured meditation (1500 s).
      expect(find.text('25 минут', skipOffstage: false), findsWidgets);
    });

    testWidgets('bottom tabs: Главная, Статьи, Медитации, Инструменты, '
        'Дневник — home selected', (tester) async {
      await pumpApp(tester, homeEnv());

      final bar = tester.widget<AppTabBar>(find.byType(AppTabBar));
      expect(bar.items.map((i) => i.label), [
        'Главная',
        'Статьи',
        'Медитации',
        'Инструменты',
        'Дневник',
      ]);
      expect(bar.currentIndex, AppTab.home.index);
    });

    testWidgets('a tab switches the section; "Главная" comes back', (
      tester,
    ) async {
      final env = homeEnv();
      final container = await pumpApp(tester, env);

      await tester.tap(find.byIcon(Icons.play_circle_rounded));
      await tester.pumpAndSettle();
      expect(currentPath(container), AppRoutes.meditations);
      expect(find.byType(HomeScreen), findsNothing);

      await tester.tap(find.byIcon(Icons.home_rounded));
      await tester.pumpAndSettle();
      expect(currentPath(container), AppRoutes.home);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    group('"все" opens the full list of the section', () {
      for (final (route, isTab) in [
        (AppRoutes.meditations, true),
        (AppRoutes.tools, true),
        (AppRoutes.topics, false),
        (AppRoutes.diary, true),
        (AppRoutes.articles, true),
      ]) {
        testWidgets(route, (tester) async {
          final container = await pumpApp(tester, homeEnv());

          await tapAndSettle(tester, find.byKey(HomeScreen.seeAllKey(route)));

          expect(currentPath(container), route);
          expect(find.byType(PlaceholderScreen), findsOneWidget);
          // Tab sections keep the bar; topics is pushed over it.
          expect(find.byType(AppTabBar), isTab ? findsOneWidget : findsNothing);
        });
      }
    });

    testWidgets('items open their content screens', (tester) async {
      final container = await pumpApp(tester, homeEnv());
      final router = container.read(appRouterProvider);

      Future<void> expectOpens(Future<void> Function() tap, String path) async {
        await tap();
        expect(currentPath(container), path);
        router.pop();
        await tester.pumpAndSettle();
        expect(currentPath(container), AppRoutes.home);
      }

      await expectOpens(
        () => _tapButtonIn(
          tester,
          find.byType(HomeFeaturedItem).first,
          HomeText.start,
        ),
        AppRoutes.meditation(1),
      );
      await expectOpens(
        () => tapAndSettle(tester, find.byType(MeditationCard)),
        AppRoutes.meditation(2),
      );
      await expectOpens(
        () => tapAndSettle(tester, find.byType(ToolListCard)),
        AppRoutes.tool(12),
      );
      await expectOpens(
        () => tapAndSettle(tester, find.byType(ArticleListCard)),
        AppRoutes.article(32),
      );
      await expectOpens(
        () => tapAndSettle(
          tester,
          find.byKey(HomeScreen.menuKey, skipOffstage: false),
        ),
        AppRoutes.profile,
      );
    });

    testWidgets('a topic card unfolds on tap; its "Читать" opens the topic', (
      tester,
    ) async {
      final container = await pumpApp(tester, homeEnv());
      ThemeListCard card() =>
          tester.widget<ThemeListCard>(find.byType(ThemeListCard));

      await tester.ensureVisible(find.byType(ThemeListCard));
      await tester.pumpAndSettle();
      expect(card().isExpanded, isFalse);

      await tapAndSettle(tester, find.text('Границы'));
      expect(card().isExpanded, isTrue);
      expect(find.text('Текст темы: Границы'), findsOneWidget);

      await tapAndSettle(
        tester,
        find.descendant(
          of: find.byType(ThemeListCard),
          matching: find.text(HomeText.read),
        ),
      );
      expect(currentPath(container), AppRoutes.topic(22));
    });

    testWidgets('locked content is marked with a lock', (tester) async {
      await pumpApp(
        tester,
        homeEnv({
          getHome: homeResponse(
            meditations: [
              meditationJson(1, 'Открытая'),
              meditationJson(2, 'Закрытая', isLocked: true),
            ],
            tools: [toolJson(11, 'Закрытый', isLocked: true)],
            topics: [topicJson(21, 'Открытая тема')],
          ),
        }),
      );

      expect(
        tester.widget<MeditationCard>(find.byType(MeditationCard)).isLocked,
        isTrue,
      );
      final featured = tester
          .widgetList<HomeFeaturedItem>(
            find.byType(HomeFeaturedItem, skipOffstage: false),
          )
          .map((f) => (f.title, f.isLocked));
      expect(featured, contains(('Открытая', false)));
      expect(featured, contains(('Закрытый', true)));
      expect(find.byType(LockedMark, skipOffstage: false), findsNWidgets(2));
    });

    testWidgets('an empty section says so and keeps its "все"', (tester) async {
      await pumpApp(
        tester,
        homeEnv({
          getHome: homeResponse(
            meditations: [],
            tools: [],
            topics: [],
            articles: [],
          ),
        }),
      );

      expect(
        find.text(HomeText.sectionEmpty, skipOffstage: false),
        findsNWidgets(4),
      );
      expect(find.byType(HomeFeaturedItem, skipOffstage: false), findsNothing);
      for (final route in [
        AppRoutes.meditations,
        AppRoutes.tools,
        AppRoutes.topics,
        AppRoutes.articles,
      ]) {
        expect(
          find.byKey(HomeScreen.seeAllKey(route), skipOffstage: false),
          findsOneWidget,
        );
      }
    });
  });

  group('diary block', () {
    testWidgets('available: current day, progress and "Продолжить" → diary', (
      tester,
    ) async {
      final container = await pumpApp(tester, homeEnv());

      final bar = tester.widget<DiaryProgressBar>(
        find.byType(DiaryProgressBar, skipOffstage: false),
      );
      expect((bar.day, bar.totalDays, bar.value), (25, 100, 0.25));
      expect(find.text('День 25', skipOffstage: false), findsOneWidget);
      expect(find.text('из 100', skipOffstage: false), findsOneWidget);
      expect(
        find.byKey(HomeScreen.diaryLockedKey, skipOffstage: false),
        findsNothing,
      );

      await tapAndSettle(tester, find.byKey(HomeScreen.diaryContinueKey));
      expect(currentPath(container), AppRoutes.diary);
    });

    testWidgets('not available to an unverified user: no progress, '
        'verification is offered', (tester) async {
      final container = await pumpApp(
        tester,
        homeEnv({getHome: homeResponse(diary: diaryJson(available: false))}),
      );

      expect(find.byType(DiaryProgressBar, skipOffstage: false), findsNothing);
      expect(
        find.byKey(HomeScreen.diaryContinueKey, skipOffstage: false),
        findsNothing,
      );
      expect(
        find.text(LockedOverlayText.graduateOnlyTitle, skipOffstage: false),
        findsOneWidget,
      );

      await tapAndSettle(tester, find.byKey(HomeScreen.diaryVerifyKey));
      expect(currentPath(container), AppRoutes.verification);
      expect(find.byType(GraduateQuestionScreen), findsOneWidget);
    });

    testWidgets('not available to a confirmed graduate: restore access, no '
        'verification prompt', (tester) async {
      await pumpApp(
        tester,
        homeEnv({
          getHome: homeResponse(diary: diaryJson(available: false)),
          verificationStatus: verification('confirmed'),
        }),
      );

      expect(
        find.byKey(HomeScreen.diaryLockedKey, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.byKey(HomeScreen.diaryVerifyKey, skipOffstage: false),
        findsNothing,
      );
      expect(
        find.text(
          LockedOverlayText.restoreAccessDescription,
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });
  });

  group('loading and errors (11.7)', () {
    testWidgets('shows a loader while GET /home is in flight', (tester) async {
      await pumpApp(
        tester,
        homeEnv({getHome: homeResponse(delay: const Duration(seconds: 5))}),
        skipSplash: false,
      );
      await tester.pump();
      await tester.pump(SplashScreen.totalDuration);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoadingIndicator), findsOneWidget);
      expect(find.text('С возвращением, Kate'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(LoadingIndicator), findsNothing);
      expect(find.byType(HomeFeaturedItem), findsWidgets);
    });

    testWidgets('offline: a network message and a retry that recovers', (
      tester,
    ) async {
      final env = homeEnv();
      final container = await pumpApp(tester, env);
      // Leaving home drops the feed; it is fetched again, offline, on the
      // way back.
      final router = container.read(appRouterProvider)
        ..go(AppRoutes.meditations);
      await tester.pumpAndSettle();
      env.backend.offline = true;
      router.go(AppRoutes.home);
      await tester.pumpAndSettle();

      expect(env.backend.requestsTo(getHome), hasLength(2));
      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.text(AuthErrorText.network), findsOneWidget);

      env.backend.offline = false;
      await tapAndSettle(tester, find.widgetWithText(AppButton, 'Повторить'));

      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.byType(HomeFeaturedItem), findsWidgets);
    });

    testWidgets('a server error shows the generic message', (tester) async {
      await pumpApp(
        tester,
        homeEnv({getHome: FakeResponse.error(500, 'SERVER_ERROR')}),
      );

      expect(find.text(HomeText.loadFailed), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Повторить'), findsOneWidget);
    });

    testWidgets('a failed pull-to-refresh keeps the feed and says so', (
      tester,
    ) async {
      final env = homeEnv();
      await pumpApp(tester, env);
      env.backend.offline = true;

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text(HomeText.refreshFailed), findsOneWidget);
      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.text('Утренняя медитация'), findsOneWidget);
    });
  });
}
