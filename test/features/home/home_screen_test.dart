import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/articles/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/home/index.dart';
import 'package:hoffman/features/meditations/index.dart';
import 'package:hoffman/features/onboarding/index.dart';
import 'package:hoffman/features/tools/index.dart';
import 'package:hoffman/features/topics/index.dart';

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
    testWidgets('32px from the featured item to the list and from the list '
        'to the next cover, no divider around a single card', (tester) async {
      await pumpApp(tester, homeEnv());

      final featured = tester.getRect(
        find.byType(HomeFeaturedItem, skipOffstage: false).first,
      );
      final card = tester.getRect(
        find.byType(MeditationCard, skipOffstage: false),
      );
      final toolsCover = tester.getRect(
        find.byType(HomeSectionCover, skipOffstage: false).at(1),
      );
      expect(card.top - featured.bottom, AppSpacing.xl);
      expect(toolsCover.top - card.bottom, AppSpacing.xl);
      expect(
        find.descendant(
          of: find.byType(ContentCardList, skipOffstage: false).first,
          matching: find.byType(ContentDivider, skipOffstage: false),
        ),
        findsNothing,
      );
    });

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

      // The featured item of each section is highlighted, the rest are the
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
      for (final route in [
        AppRoutes.meditations,
        AppRoutes.tools,
        AppRoutes.topics,
        AppRoutes.diary,
        AppRoutes.articles,
      ]) {
        testWidgets(route, (tester) async {
          final container = await pumpApp(tester, homeEnv());

          await tapAndSettle(tester, find.byKey(HomeScreen.seeAllKey(route)));

          expect(currentPath(container), route);
          expect(
            find.byType(switch (route) {
              AppRoutes.meditations => MeditationsScreen,
              AppRoutes.articles => ArticlesScreen,
              AppRoutes.tools => ToolsScreen,
              AppRoutes.topics => TopicsScreen,
              _ => PlaceholderScreen,
            }),
            findsOneWidget,
          );
          // Every section keeps the bar and marks its tab; the topics
          // share the tools one.
          expect(find.byType(AppTabBar), findsOneWidget);
          expect(
            tester.widget<AppTabBar>(find.byType(AppTabBar)).currentIndex,
            AppTab.sectionOf(route)!.index,
          );
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

    testWidgets('no card or featured item shows a lock, whatever '
        'is_locked says', (tester) async {
      await pumpApp(
        tester,
        homeEnv({
          getHome: homeResponse(
            meditations: sectionJson(
              meditationJson(1, 'Закрытая главная', isLocked: true),
              [meditationJson(2, 'Закрытая', isLocked: true)],
            ),
            tools: sectionJson(toolJson(11, 'Инструмент', isLocked: true), [
              toolJson(12, 'Ещё инструмент', isLocked: true),
            ]),
            topics: sectionJson(topicJson(21, 'Тема', isLocked: true), [
              topicJson(22, 'Ещё тема', isLocked: true),
            ]),
          ),
        }),
      );

      expect(
        find.text('Закрытая главная', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Закрытая', skipOffstage: false), findsOneWidget);
      expect(find.byType(LockedMark, skipOffstage: false), findsNothing);
      expect(find.byIcon(Icons.lock, skipOffstage: false), findsNothing);
    });

    testWidgets('an empty section says so and keeps its "все"', (tester) async {
      await pumpApp(
        tester,
        homeEnv({
          getHome: homeResponse(
            meditations: sectionJson(null),
            tools: sectionJson(null),
            topics: sectionJson(null),
            articles: sectionJson(null),
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

  group('featured item', () {
    const cover = 'https://api.example.com/storage/covers/featured.jpg';

    HomeSectionCover sectionCover(WidgetTester tester, String title) =>
        tester.widget<HomeSectionCover>(
          find.byWidgetPredicate(
            (w) => w is HomeSectionCover && w.title == title,
            skipOffstage: false,
          ),
        );

    testWidgets('the section cover shows the featured item cover', (
      tester,
    ) async {
      await pumpApp(
        tester,
        homeEnv({
          getHome: homeResponse(
            meditations: sectionJson(
              meditationJson(1, 'Заглавная', coverImageUrl: cover),
            ),
            tools: sectionJson(toolJson(11, 'Заглавный', coverImageUrl: cover)),
            topics: sectionJson(
              topicJson(21, 'Заглавная', coverImageUrl: cover),
            ),
            articles: sectionJson(
              articleJson(31, 'Заглавная', coverImageUrl: cover),
            ),
          ),
        }),
      );

      for (final title in [
        HomeText.meditations,
        HomeText.tools,
        HomeText.topics,
        HomeText.articles,
      ]) {
        expect(sectionCover(tester, title).imageUrl, Uri.parse(cover));
      }
      // The diary has no featured item: always its stock image.
      expect(sectionCover(tester, HomeText.diary).imageUrl, isNull);
      expect(sectionCover(tester, HomeText.diary).image, HomeScreen.diaryCover);
    });

    Finder inCover(String title, Finder matching) => find.descendant(
      of: find.byWidgetPredicate(
        (w) => w is HomeSectionCover && w.title == title,
        skipOffstage: false,
      ),
      matching: matching,
      skipOffstage: false,
    );

    const featuredSections = [
      HomeText.meditations,
      HomeText.tools,
      HomeText.topics,
      HomeText.articles,
    ];

    testWidgets('a featured item without cover_image_url shows the '
        'placeholder, not a stock image of the section', (tester) async {
      await pumpApp(
        tester,
        homeEnv({
          getHome: homeResponse(
            meditations: sectionJson(meditationJson(1, 'Заглавная')),
            tools: sectionJson(toolJson(11, 'Заглавный')),
            topics: sectionJson(topicJson(21, 'Заглавная')),
            articles: sectionJson(articleJson(31, 'Заглавная')),
          ),
        }),
      );

      for (final title in featuredSections) {
        expect(sectionCover(tester, title).imageUrl, isNull, reason: title);
        expect(
          inCover(title, find.byType(HomeCoverPlaceholder)),
          findsOneWidget,
          reason: title,
        );
        expect(inCover(title, find.byType(Image)), findsNothing, reason: title);
      }
    });

    testWidgets('the diary cover is its stock image, never the placeholder', (
      tester,
    ) async {
      await pumpApp(tester, homeEnv());

      expect(
        inCover(HomeText.diary, find.byType(HomeCoverPlaceholder)),
        findsNothing,
      );
      expect(
        tester
            .widgetList<Image>(inCover(HomeText.diary, find.byType(Image)))
            .map((i) => i.image),
        contains(const AssetImage(HomeScreen.diaryCover)),
      );
    });

    testWidgets('a section without a featured item shows the placeholder', (
      tester,
    ) async {
      await pumpApp(
        tester,
        homeEnv({
          getHome: homeResponse(
            meditations: sectionJson(null, [meditationJson(2, 'Другая')]),
          ),
        }),
      );

      expect(
        inCover(HomeText.meditations, find.byType(HomeCoverPlaceholder)),
        findsOneWidget,
      );
      expect(inCover(HomeText.meditations, find.byType(Image)), findsNothing);
    });

    testWidgets('an unloadable cover falls back to the placeholder', (
      tester,
    ) async {
      // Test HTTP answers 400 to every request.
      await pumpApp(
        tester,
        homeEnv({
          getHome: homeResponse(
            meditations: sectionJson(
              meditationJson(1, 'Заглавная', coverImageUrl: cover),
            ),
          ),
        }),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();

      final meditations = find.byWidgetPredicate(
        (w) => w is HomeSectionCover && w.title == HomeText.meditations,
      );
      expect(
        find.descendant(
          of: meditations,
          matching: find.byType(HomeCoverPlaceholder),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widgetList<Image>(
              find.descendant(of: meditations, matching: find.byType(Image)),
            )
            .map((i) => i.image),
        isNot(contains(isA<AssetImage>())),
      );
    });

    group('the cover opens the featured item', () {
      for (final (section, route) in [
        (AppRoutes.meditations, AppRoutes.meditation(1)),
        (AppRoutes.tools, AppRoutes.tool(11)),
        (AppRoutes.topics, AppRoutes.topic(21)),
        (AppRoutes.articles, AppRoutes.article(31)),
      ]) {
        testWidgets(section, (tester) async {
          final container = await pumpApp(tester, homeEnv());

          await tapAndSettle(tester, find.byKey(HomeScreen.coverKey(section)));

          expect(currentPath(container), route);
        });
      }
    });

    testWidgets('without a featured item: no highlighted block, every item '
        'is a card and the cover is the stock image, not tappable', (
      tester,
    ) async {
      final container = await pumpApp(
        tester,
        homeEnv({
          getHome: homeResponse(
            meditations: sectionJson(null, [
              meditationJson(1, 'Первая', coverImageUrl: cover),
              meditationJson(2, 'Вторая'),
            ]),
          ),
        }),
      );

      final featured = tester
          .widgetList<HomeFeaturedItem>(
            find.byType(HomeFeaturedItem, skipOffstage: false),
          )
          .map((f) => f.title);
      expect(featured, isNot(contains('Первая')));
      expect(featured, hasLength(3));
      expect(
        tester
            .widgetList<MeditationCard>(
              find.byType(MeditationCard, skipOffstage: false),
            )
            .map((c) => c.title),
        ['Первая', 'Вторая'],
      );
      expect(find.text(HomeText.sectionEmpty), findsNothing);

      final meditations = sectionCover(tester, HomeText.meditations);
      expect(meditations.imageUrl, isNull);
      expect(meditations.onTap, isNull);
      expect(
        find.byKey(HomeScreen.coverKey(AppRoutes.meditations)),
        findsNothing,
      );

      await tester.tap(find.text(bindShortWords(HomeText.meditationsSubtitle)));
      await tester.pumpAndSettle();
      expect(currentPath(container), AppRoutes.home);

      // "все" still leads to the list.
      await tapAndSettle(
        tester,
        find.byKey(HomeScreen.seeAllKey(AppRoutes.meditations)),
      );
      expect(currentPath(container), AppRoutes.meditations);
    });

    testWidgets('only a featured item: no cards, no empty message', (
      tester,
    ) async {
      await pumpApp(
        tester,
        homeEnv({
          getHome: homeResponse(
            meditations: sectionJson(meditationJson(1, 'Единственная')),
          ),
        }),
      );

      expect(find.byType(MeditationCard, skipOffstage: false), findsNothing);
      expect(find.text(HomeText.sectionEmpty), findsNothing);
      expect(
        tester
            .widget<HomeFeaturedItem>(find.byType(HomeFeaturedItem).first)
            .title,
        'Единственная',
      );
    });

    testWidgets('list cards show their own covers', (tester) async {
      await pumpApp(
        tester,
        homeEnv({
          getHome: homeResponse(
            meditations: sectionJson(null, [
              meditationJson(2, 'С обложкой', coverImageUrl: cover),
            ]),
          ),
        }),
      );

      final card = tester.widget<MeditationCard>(
        find.byType(MeditationCard, skipOffstage: false),
      );
      expect(card.cover, isA<HomeCoverImage>());
      expect((card.cover as HomeCoverImage).url, Uri.parse(cover));
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

      await tester.ensureVisible(find.byKey(HomeScreen.diaryContinueKey));
      expectGridButton(tester, find.byKey(HomeScreen.diaryContinueKey));

      await tapAndSettle(tester, find.byKey(HomeScreen.diaryContinueKey));
      expect(currentPath(container), AppRoutes.diary);
    });

    // Not a confirmed graduate: no diary section at all — no cover, no
    // "все", no lock, no verification prompt; the articles follow topics.
    void expectNoDiarySection(WidgetTester tester) {
      expect(
        tester
            .widgetList<HomeSectionCover>(
              find.byType(HomeSectionCover, skipOffstage: false),
            )
            .map((c) => c.title),
        [
          HomeText.meditations,
          HomeText.tools,
          HomeText.topics,
          HomeText.articles,
        ],
      );
      for (final finder in [
        find.byKey(HomeScreen.seeAllKey(AppRoutes.diary), skipOffstage: false),
        find.byKey(HomeScreen.diaryLockedKey, skipOffstage: false),
        find.byKey(HomeScreen.diaryContinueKey, skipOffstage: false),
        find.byType(DiaryProgressBar, skipOffstage: false),
        find.byType(LockedMark, skipOffstage: false),
        find.byIcon(Icons.lock, skipOffstage: false),
        find.text(HomeText.diary, skipOffstage: false),
        find.text(LockedOverlayText.graduateOnlyTitle, skipOffstage: false),
        find.text(LockedOverlayText.restrictedTitle, skipOffstage: false),
        find.text(LockedOverlayText.verify, skipOffstage: false),
      ]) {
        expect(finder, findsNothing);
      }
    }

    for (final (name, status) in [
      ('never verified', verification(null)),
      ('pending', verification('pending')),
      ('rejected', verification('rejected')),
      ('status failed to load', FakeResponse.error(500, 'SERVER_ERROR')),
    ]) {
      testWidgets('not a confirmed graduate ($name): no diary section', (
        tester,
      ) async {
        await pumpApp(
          tester,
          homeEnv({
            getHome: homeResponse(diary: diaryJson(available: false)),
            verificationStatus: status,
          }),
        );

        expect(find.byType(HomeScreen), findsOneWidget);
        expectNoDiarySection(tester);
      });
    }

    testWidgets('no diary section while the graduate status is loading', (
      tester,
    ) async {
      await pumpApp(
        tester,
        homeEnv({
          getHome: homeResponse(diary: diaryJson(available: false)),
          verificationStatus: verification(
            'confirmed',
            delay: const Duration(seconds: 5),
          ),
        }),
        skipSplash: false,
      );
      await tester.pump();
      await tester.pump(SplashScreen.totalDuration);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(HomeSectionCover), findsWidgets);
      expectNoDiarySection(tester);

      // Confirmed once loaded: the section appears.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(
        find.byKey(HomeScreen.diaryLockedKey, skipOffstage: false),
        findsOneWidget,
      );
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
        find.byKey(HomeScreen.seeAllKey(AppRoutes.diary), skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.byKey(HomeScreen.diaryLockedKey, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(LockedOverlayText.verify, skipOffstage: false),
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
