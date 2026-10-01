import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/home/index.dart';
import 'package:hoffman/features/tools/index.dart';
import 'package:hoffman/features/topics/index.dart';

import '../../helpers/app_harness.dart';
import 'tools_harness.dart';

void main() {
  group('ТЗ 5.5 — список инструментов', () {
    testWidgets('the tools tab: section cover, featured tool, then a card '
        'per other tool', (tester) async {
      final harness = ToolsHarness.subscribed();
      final container = await harness.open(tester, AppRoutes.tools);

      expect(currentPath(container), AppRoutes.tools);
      expect(find.byType(ToolsScreen), findsOneWidget);
      expect(
        tester.widget<AppTabBar>(find.byType(AppTabBar)).currentIndex,
        AppTab.tools.index,
      );
      expect(harness.backend.requestsTo(getTools), hasLength(1));

      final cover = tester.widget<HomeSectionCover>(
        find.byType(HomeSectionCover),
      );
      expect(cover.title, HomeText.tools);
      expect(cover.underStatusBar, isTrue);
      expect(tester.getTopLeft(find.byType(HomeSectionCover)).dy, 0);
      expect(cover.subtitle, HomeText.toolsSubtitle);

      final featured = tester.widget<HomeFeaturedItem>(
        find.byKey(ToolsScreen.featuredKey),
      );
      expect(featured.title, 'Распознавание паттернов');
      expect(featured.actionLabel, HomeText.read);

      final cards = tester
          .widgetList<ToolListCard>(
            find.byType(ToolListCard, skipOffstage: false),
          )
          .toList();
      expect(cards.map((c) => c.title), ['Выражение гнева', 'Письмо себе']);
      // featured is never repeated among the cards.
      expect(find.text('Распознавание паттернов'), findsOneWidget);
    });

    testWidgets('a card: title, short description, stage badge and the '
        '"Читать" link to the exercise, no cover', (tester) async {
      const coverUrl = 'https://api.example.com/storage/covers/12.jpg';
      final harness = ToolsHarness.subscribed({
        getTools: catalog(null, [
          toolJson(12, 'Выражение гнева', coverImageUrl: coverUrl),
          toolJson(13, 'Письмо себе', stageTag: null),
        ]),
      });
      final container = await harness.open(tester, AppRoutes.tools);

      final card = tester.widget<ToolListCard>(
        find.byKey(ToolsScreen.cardKey(12)),
      );
      expect(card.title, 'Выражение гнева');
      expect(card.description, 'Описание: Выражение гнева');
      expect(card.tag, 'выражение');
      expect(card.actionLabel, HomeText.read);
      // The tool has a cover_image_url, but the card shows no cover.
      expect(
        find.descendant(
          of: find.byKey(ToolsScreen.cardKey(12)),
          matching: find.byType(HomeCoverImage),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(ToolsScreen.cardKey(12)),
          matching: find.text('выражение'),
        ),
        findsOneWidget,
      );

      // A tool without a stage has no badge.
      expect(
        tester.widget<ToolListCard>(find.byKey(ToolsScreen.cardKey(13))).tag,
        isNull,
      );

      await tapAndSettle(
        tester,
        find.descendant(
          of: find.byKey(ToolsScreen.cardKey(12)),
          matching: find.text(HomeText.read),
        ),
      );
      expect(currentPath(container), AppRoutes.tool(12));
      expect(find.byType(ToolDetailScreen), findsOneWidget);
    });

    testWidgets('the featured tool and the cover open it', (tester) async {
      final harness = ToolsHarness.subscribed();
      final container = await harness.open(tester, AppRoutes.tools);
      final router = container.read(appRouterProvider);

      await tapAndSettle(tester, find.byKey(ToolsScreen.featuredKey));
      expect(currentPath(container), AppRoutes.tool(11));

      router.pop();
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.byKey(ToolsScreen.coverKey));
      expect(currentPath(container), AppRoutes.tool(11));
    });

    testWidgets('the "темы" badge opens the topics within the same tab; '
        'back returns to the tools', (tester) async {
      final harness = ToolsHarness.subscribed();
      final container = await harness.open(tester, AppRoutes.tools);

      final link = find.byKey(ToolsScreen.topicsLinkKey);
      expect(tester.widget<AppBadge>(link).label, ToolsText.topicsLink);

      await tapAndSettle(tester, link);
      expect(currentPath(container), AppRoutes.topics);
      expect(find.byType(TopicsScreen), findsOneWidget);
      expect(
        tester.widget<AppTabBar>(find.byType(AppTabBar)).currentIndex,
        AppTab.tools.index,
      );

      container.read(appRouterProvider).pop();
      await tester.pumpAndSettle();
      expect(currentPath(container), AppRoutes.tools);
      expect(find.byType(ToolsScreen), findsOneWidget);
    });
  });

  group('ТЗ 5.5 — состояния списка', () {
    testWidgets('loading shows the spinner', (tester) async {
      final harness = ToolsHarness.subscribed({
        getTools: FakeResponse(
          200,
          {'data': sectionJson(null)},
          const {},
          const Duration(seconds: 1),
        ),
      });
      final container = await pumpApp(tester, harness.env);
      container.read(appRouterProvider).go(AppRoutes.tools);
      await tester.pump();
      await tester.pump();

      expect(find.byType(LoadingIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(LoadingIndicator), findsNothing);
    });

    testWidgets('an empty list says so, and still links to the topics', (
      tester,
    ) async {
      final harness = ToolsHarness.subscribed({getTools: catalog(null)});
      await harness.open(tester, AppRoutes.tools);

      expect(find.byType(HomeSectionEmpty), findsOneWidget);
      expect(find.byType(ToolListCard), findsNothing);
      expect(find.byKey(ToolsScreen.topicsLinkKey), findsOneWidget);
    });

    testWidgets('offline: the network error with a retry that reloads', (
      tester,
    ) async {
      final harness = ToolsHarness.subscribed();
      final container = await pumpApp(tester, harness.env);
      harness.backend.offline = true;
      container.read(appRouterProvider).go(AppRoutes.tools);
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.text(AuthErrorText.network), findsOneWidget);

      harness.backend.offline = false;
      await tapAndSettle(tester, find.text('Повторить'));

      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.byType(ToolListCard), findsNWidgets(2));
    });

    testWidgets('a server error says the tools could not load', (tester) async {
      final harness = ToolsHarness.subscribed({
        getTools: FakeResponse.error(500, 'SERVER_ERROR'),
      });
      await harness.open(tester, AppRoutes.tools);

      expect(find.text(ToolsText.loadFailed), findsOneWidget);
    });
  });
}
