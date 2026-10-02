import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/articles/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/home/index.dart';

import '../../helpers/app_harness.dart';
import 'articles_harness.dart';

void main() {
  group('ТЗ 5.7 — список статей', () {
    testWidgets('featured heads the list like on home, the others are '
        'article cards with cover, title, date and description', (
      tester,
    ) async {
      const cover = 'https://cdn.example.com/covers/2.jpg';
      final env = homeEnv({
        getArticles: articlesResponse(articleJson(1, 'Что такое Процесс?'), [
          articleJson(2, 'Стресс', coverImageUrl: cover),
          articleJson(3, 'Роли в семье', publishedAt: '2025-11-02T10:00:00Z'),
        ]),
      });
      final container = await openAt(tester, env, AppRoutes.articles);

      expect(currentPath(container), AppRoutes.articles);
      expect(find.byType(ArticlesScreen), findsOneWidget);
      expect(find.byType(AppTabBar), findsOneWidget);
      expect(env.backend.requestsTo(getArticles), hasLength(1));

      final sectionCover = tester.widget<HomeSectionCover>(
        find.byType(HomeSectionCover),
      );
      expect(sectionCover.title, HomeText.articles);
      expect(sectionCover.underStatusBar, isTrue);
      expect(tester.getTopLeft(find.byType(HomeSectionCover)).dy, 0);
      expect(sectionCover.onSeeAll, isNull);
      expect(sectionCover.onTap, isNotNull);

      final featured = tester.widget<HomeFeaturedItem>(
        find.byKey(ArticlesScreen.featuredKey),
      );
      expect(featured.title, 'Что такое Процесс?');
      expect(featured.actionLabel, HomeText.read);

      final cards = tester
          .widgetList<ArticleListCard>(
            find.byType(ArticleListCard, skipOffstage: false),
          )
          .toList();
      expect(cards.map((c) => c.title), ['Стресс', 'Роли в семье']);
      expect(cards.map((c) => c.date), ['Март, 2025', 'Ноябрь, 2025']);
      expect(cards.map((c) => c.description), [
        'Описание: Стресс',
        'Описание: Роли в семье',
      ]);
      // Articles are never locked: no lock anywhere on the list.
      expect(find.byType(LockedMark, skipOffstage: false), findsNothing);
      expect(find.byIcon(Icons.lock, skipOffstage: false), findsNothing);
      // The card cover is cover_image_url as is.
      expect((cards.first.cover as HomeCoverImage).url, Uri.parse(cover));
      // featured is never repeated among the cards.
      expect(find.text('Что такое Процесс?'), findsOneWidget);

      // featured → 32 → card → 16 → line → 16 → card → 32: one divider,
      // only between the cards.
      final featuredRect = tester.getRect(
        find.byKey(ArticlesScreen.featuredKey),
      );
      final first = tester.getRect(find.byKey(ArticlesScreen.cardKey(2)));
      final second = tester.getRect(
        find.byKey(ArticlesScreen.cardKey(3), skipOffstage: false),
      );
      final dividers = find.byType(ContentDivider, skipOffstage: false);
      expect(dividers, findsOneWidget);
      final line = tester.getRect(dividers);
      expect(first.top - featuredRect.bottom, AppSpacing.xl);
      expect(line.top - first.bottom, AppSpacing.md);
      expect(second.top - line.bottom, AppSpacing.md);
      expect(line.width, tester.getSize(find.byType(ArticlesScreen)).width);
      final list = tester.getRect(
        find.byType(ContentCardList, skipOffstage: false),
      );
      expect(list.bottom - second.bottom, AppSpacing.xl);
    });

    testWidgets('is_new puts the "новое" badge on that card only', (
      tester,
    ) async {
      final env = homeEnv({
        getArticles: articlesResponse(null, [
          articleJson(2, 'Новая', isNew: true),
          articleJson(3, 'Старая'),
        ]),
      });
      await openAt(tester, env, AppRoutes.articles);

      Finder badgeIn(int id) => find.descendant(
        of: find.byKey(ArticlesScreen.cardKey(id)),
        matching: find.widgetWithText(AppBadge, HomeText.newBadge),
      );
      expect(badgeIn(2), findsOneWidget);
      expect(badgeIn(3), findsNothing);
      expect(
        tester.widget<AppBadge>(badgeIn(2)).variant,
        AppBadgeVariant.tinted,
      );
    });

    testWidgets('without featured: no highlighted item, the cover is '
        'inert', (tester) async {
      final env = homeEnv({
        getArticles: articlesResponse(null, [
          articleJson(2, 'Вторая'),
          articleJson(3, 'Третья'),
        ]),
      });
      await openAt(tester, env, AppRoutes.articles);

      expect(find.byType(HomeFeaturedItem), findsNothing);
      expect(
        tester.widget<HomeSectionCover>(find.byType(HomeSectionCover)).onTap,
        isNull,
      );
      expect(
        find.byType(ArticleListCard, skipOffstage: false),
        findsNWidgets(2),
      );
    });

    testWidgets('an empty list says so', (tester) async {
      final env = homeEnv({getArticles: articlesResponse(null)});
      await openAt(tester, env, AppRoutes.articles);

      expect(find.byType(HomeSectionEmpty), findsOneWidget);
      expect(find.byType(ArticleListCard), findsNothing);
    });

    testWidgets('featured, its cover and each card open the article', (
      tester,
    ) async {
      final container = await openAt(tester, homeEnv(), AppRoutes.articles);
      final router = container.read(appRouterProvider);

      Future<void> expectOpens(Finder target, int id, String title) async {
        await tapAndSettle(tester, target);
        expect(currentPath(container), AppRoutes.article(id));
        expect(find.byType(ArticleDetailScreen), findsOneWidget);
        expect(find.text(title), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
        expect(currentPath(container), AppRoutes.articles);
      }

      const featured = 'Что такое Процесс Хоффмана?';
      await expectOpens(
        find.descendant(
          of: find.byKey(ArticlesScreen.featuredKey),
          matching: find.widgetWithText(AppButton, HomeText.read),
        ),
        31,
        featured,
      );
      await expectOpens(find.byKey(ArticlesScreen.coverKey), 31, featured);
      await expectOpens(
        find.byKey(ArticlesScreen.cardKey(32)),
        32,
        '«Навсегда твой» или про роли в семье',
      );
    });

    testWidgets('offline: the error state with a retry, then the list', (
      tester,
    ) async {
      final env = homeEnv();
      await openAt(tester, env, AppRoutes.home);
      env.backend.offline = true;

      await tester.tap(find.byIcon(Icons.article_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.text(AuthErrorText.network), findsOneWidget);

      env.backend.offline = false;
      await tapAndSettle(tester, find.byType(AppButton));

      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.byKey(ArticlesScreen.featuredKey), findsOneWidget);
    });

    testWidgets('a server error has its own text', (tester) async {
      final env = homeEnv({
        getArticles: FakeResponse.error(500, 'SERVER_ERROR'),
      });
      await openAt(tester, env, AppRoutes.articles);

      expect(find.text(ArticlesText.loadFailed), findsOneWidget);
    });

    testWidgets('pull to refresh offline keeps the list and shows a '
        'snackbar', (tester) async {
      final env = homeEnv();
      await openAt(tester, env, AppRoutes.articles);
      env.backend.offline = true;

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text(ArticlesText.refreshFailed), findsOneWidget);
      expect(find.byKey(ArticlesScreen.featuredKey), findsOneWidget);
    });
  });

  group('home → articles', () {
    testWidgets('"все" of the articles section opens the list', (tester) async {
      final container = await openAt(tester, homeEnv(), AppRoutes.home);

      await tapAndSettle(
        tester,
        find.byKey(HomeScreen.seeAllKey(AppRoutes.articles)),
      );

      expect(currentPath(container), AppRoutes.articles);
      expect(find.byType(ArticlesScreen), findsOneWidget);
      expect(find.byType(ArticleListCard, skipOffstage: false), findsWidgets);
      expect(
        tester.widget<AppTabBar>(find.byType(AppTabBar)).currentIndex,
        AppTab.articles.index,
      );
    });

    testWidgets('a home article card opens that same article', (tester) async {
      final env = homeEnv();
      final container = await openAt(tester, env, AppRoutes.home);

      await tapAndSettle(tester, find.byType(ArticleListCard));

      expect(currentPath(container), AppRoutes.article(32));
      expect(env.backend.requestsTo(getArticle(32)), hasLength(1));
      expect(find.byType(ArticleDetailScreen), findsOneWidget);
      expect(find.text('«Навсегда твой» или про роли в семье'), findsOneWidget);
    });

    testWidgets('the home featured article and its cover open it', (
      tester,
    ) async {
      final container = await openAt(tester, homeEnv(), AppRoutes.home);
      final router = container.read(appRouterProvider);

      await tapAndSettle(
        tester,
        find.byKey(HomeScreen.coverKey(AppRoutes.articles)),
      );
      expect(currentPath(container), AppRoutes.article(31));
      expect(find.text('Что такое Процесс Хоффмана?'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      final featured = find.byWidgetPredicate(
        (w) =>
            w is HomeFeaturedItem && w.title == 'Что такое Процесс Хоффмана?',
        skipOffstage: false,
      );
      await tester.ensureVisible(featured);
      await tester.pumpAndSettle();
      await tapAndSettle(
        tester,
        find.descendant(
          of: featured,
          matching: find.widgetWithText(AppButton, HomeText.read),
        ),
      );
      expect(currentPath(container), AppRoutes.article(31));
      expect(find.byType(ArticleDetailScreen), findsOneWidget);
    });

    testWidgets('home shows the "новое" badge from is_new', (tester) async {
      await openAt(
        tester,
        homeEnv({
          getHome: homeResponse(
            articles: sectionJson(null, [
              articleJson(32, 'Новая', isNew: true),
              articleJson(33, 'Старая'),
            ]),
          ),
        }),
        AppRoutes.home,
      );

      final cards = tester
          .widgetList<ArticleListCard>(
            find.byType(ArticleListCard, skipOffstage: false),
          )
          .toList();
      expect(cards.map((c) => c.badge), [HomeText.newBadge, null]);
    });
  });
}
