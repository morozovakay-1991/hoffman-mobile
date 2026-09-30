import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
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
  group('ТЗ 5.7 — детальный экран статьи', () {
    testWidgets('cover, title, short description, date and the full '
        'description as HTML', (tester) async {
      const cover = 'https://cdn.example.com/covers/5.jpg';
      final env = homeEnv({
        getArticle(5): articleResponse({
          ...articleJson(5, 'Стресс', coverImageUrl: cover),
          'full_description': '<p>Первый абзац</p><ul><li>Пункт</li></ul>',
        }),
      });
      await openAt(tester, env, AppRoutes.article(5));

      expect(env.backend.requestsTo(getArticle(5)), hasLength(1));
      expect(find.byType(AppTabBar), findsOneWidget);

      final image = tester.widget<HomeCoverImage>(find.byType(HomeCoverImage));
      expect(image.url, Uri.parse(cover));
      expect(image.fallback, HomeScreen.articlesCover);

      expect(find.text('Стресс'), findsOneWidget);
      expect(find.text('Описание: Стресс'), findsOneWidget);
      expect(find.text('Март, 2025'), findsOneWidget);

      final html = tester.widget<Html>(find.byType(Html));
      expect(html.data, '<p>Первый абзац</p><ul><li>Пункт</li></ul>');
    });

    testWidgets('share sends the title and the short description', (
      tester,
    ) async {
      final shared = <SharedText>[];
      await openAt(tester, shareEnv(shared), AppRoutes.article(32));

      final share = find.byKey(ArticleDetailScreen.shareKey);
      expect(share, findsOneWidget);
      // Over the cover, white like the back chevron (Figma 414:2903).
      expect(tester.widget<ShareButton>(share).color, AppColors.background);

      await tapAndSettle(tester, share);

      expect(shared, hasLength(1));
      expect(
        shared.single.text,
        '«Навсегда твой» или про роли в семье\n\n'
        'Описание: «Навсегда твой» или про роли в семье',
      );
      expect(shared.single.subject, '«Навсегда твой» или про роли в семье');
      expect(shared.single.origin, isNotNull);
    });

    testWidgets('no share while the article is not loaded', (tester) async {
      await openAt(tester, homeEnv(), AppRoutes.article(999));

      expect(find.text(ArticlesText.notFound), findsOneWidget);
      expect(find.byType(ShareButton), findsNothing);
    });

    testWidgets('no date and no full description: neither is shown', (
      tester,
    ) async {
      final env = homeEnv({
        getArticle(5): articleResponse({
          ...articleJson(5, 'Стресс', publishedAt: null),
          'full_description': null,
        }),
      });
      await openAt(tester, env, AppRoutes.article(5));

      expect(find.text('Стресс'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month), findsNothing);
      expect(find.byType(Html), findsNothing);
    });

    testWidgets('back returns to the list', (tester) async {
      final container = await openAt(tester, homeEnv(), AppRoutes.articles);
      await tapAndSettle(tester, find.byKey(ArticlesScreen.cardKey(32)));
      expect(currentPath(container), AppRoutes.article(32));

      await tapAndSettle(tester, find.byIcon(Icons.chevron_left));

      expect(currentPath(container), AppRoutes.articles);
      expect(find.byType(ArticlesScreen), findsOneWidget);
    });

    testWidgets('opened directly, back goes to the list', (tester) async {
      final container = await pumpApp(tester, homeEnv());
      container.read(appRouterProvider).go(AppRoutes.article(31));
      await tester.pumpAndSettle();

      await tapAndSettle(tester, find.byIcon(Icons.chevron_left));

      expect(currentPath(container), AppRoutes.articles);
    });

    testWidgets('a missing article says so', (tester) async {
      await openAt(tester, homeEnv(), AppRoutes.article(999));

      expect(find.text(ArticlesText.notFound), findsOneWidget);
      expect(find.byType(ErrorStateWidget), findsNothing);
    });

    testWidgets('a non-numeric id says so without a request', (tester) async {
      final env = homeEnv();
      await openAt(tester, env, '${AppRoutes.articles}/abc');

      expect(find.text(ArticlesText.notFound), findsOneWidget);
      expect(
        env.backend.requests.where(
          (r) => r.path.startsWith('/api/v1/articles/'),
        ),
        isEmpty,
      );
    });

    testWidgets('offline: the error state with a retry, then the article', (
      tester,
    ) async {
      final env = homeEnv();
      await openAt(tester, env, AppRoutes.home);
      env.backend.offline = true;

      await tapAndSettle(tester, find.byType(ArticleListCard));

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.text(AuthErrorText.network), findsOneWidget);
      // The way back stays.
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);

      env.backend.offline = false;
      await tapAndSettle(tester, find.byType(AppButton));

      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.text('«Навсегда твой» или про роли в семье'), findsOneWidget);
    });

    testWidgets('a server error has its own text', (tester) async {
      await openAt(
        tester,
        homeEnv({getArticle(31): FakeResponse.error(500, 'SERVER_ERROR')}),
        AppRoutes.article(31),
      );

      expect(find.text(ArticlesText.articleLoadFailed), findsOneWidget);
    });
  });
}
