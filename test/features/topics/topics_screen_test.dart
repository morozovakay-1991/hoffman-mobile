import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/home/index.dart';
import 'package:hoffman/features/tools/index.dart';
import 'package:hoffman/features/topics/index.dart';

import '../../helpers/app_harness.dart';
import '../tools/tools_harness.dart';

void main() {
  ThemeListCard card(WidgetTester tester, int id) =>
      tester.widget<ThemeListCard>(find.byKey(TopicsScreen.cardKey(id)));

  group('ТЗ 5.6 — список тем', () {
    testWidgets('section cover, featured topic, then a folded card per '
        'other topic, inside the tools tab', (tester) async {
      final harness = ToolsHarness.subscribed();
      final container = await harness.open(tester, AppRoutes.topics);

      expect(currentPath(container), AppRoutes.topics);
      expect(find.byType(TopicsScreen), findsOneWidget);
      expect(
        tester.widget<AppTabBar>(find.byType(AppTabBar)).currentIndex,
        AppTab.tools.index,
      );
      expect(harness.backend.requestsTo(getTopics), hasLength(1));

      expect(
        tester.widget<HomeSectionCover>(find.byType(HomeSectionCover)).title,
        HomeText.topics,
      );
      expect(
        tester
            .widget<HomeSectionCover>(find.byType(HomeSectionCover))
            .underStatusBar,
        isTrue,
      );
      expect(tester.getTopLeft(find.byType(HomeSectionCover)).dy, 0);
      final featured = tester.widget<HomeFeaturedItem>(
        find.byKey(TopicsScreen.featuredKey),
      );
      expect(featured.title, 'Я жертва');
      expect(featured.subtitle, 'Подзаголовок: Я жертва');

      final cards = tester
          .widgetList<ThemeListCard>(
            // Home stays mounted under the pushed list.
            find.descendant(
              of: find.byType(TopicsScreen),
              matching: find.byType(ThemeListCard, skipOffstage: false),
              skipOffstage: false,
            ),
          )
          .toList();
      expect(cards.map((c) => c.title), ['Границы', 'Тревога']);
      expect(cards.map((c) => c.subtitle), [
        'Подзаголовок: Границы',
        'Подзаголовок: Тревога',
      ]);
      expect(cards.map((c) => c.isExpanded), [false, false]);
      // Folded: no cover, no description.
      expect(find.text('Текст темы: Границы'), findsNothing);
    });

    testWidgets('accordion: a tap unfolds the topic to its cover thumbnail '
        'and short description, a second tap folds it back', (tester) async {
      const coverUrl = 'https://api.example.com/storage/covers/22.jpg';
      final harness = ToolsHarness.subscribed({
        getTopics: catalog(null, [
          topicJson(22, 'Границы', coverImageUrl: coverUrl),
          topicJson(23, 'Тревога'),
        ]),
      });
      await harness.open(tester, AppRoutes.topics);

      await tapAndSettle(tester, find.text('Границы'));
      expect(card(tester, 22).isExpanded, isTrue);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.text('Текст темы: Границы'), findsOneWidget);
      final cover = tester.widget<HomeCoverImage>(
        find.descendant(
          of: find.byKey(TopicsScreen.cardKey(22)),
          matching: find.byType(HomeCoverImage),
        ),
      );
      expect(cover.url, Uri.parse(coverUrl));
      expect(cover.fallback, HomeScreen.topicsCover);

      await tapAndSettle(tester, find.text('Границы'));
      expect(card(tester, 22).isExpanded, isFalse);
      expect(find.text('Текст темы: Границы'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(TopicsScreen.cardKey(22)),
          matching: find.byType(HomeCoverImage),
        ),
        findsNothing,
      );
    });

    testWidgets('one topic unfolded at a time', (tester) async {
      final harness = ToolsHarness.subscribed();
      await harness.open(tester, AppRoutes.topics);

      await tapAndSettle(tester, find.text('Границы'));
      await tapAndSettle(tester, find.text('Тревога'));

      expect(card(tester, 22).isExpanded, isFalse);
      expect(card(tester, 23).isExpanded, isTrue);
    });

    testWidgets('the short description comes from the backend when it has '
        'one, otherwise from the full description as plain text', (
      tester,
    ) async {
      final harness = ToolsHarness.subscribed({
        getTopics: catalog(null, [
          {...topicJson(22, 'Границы'), 'short_description': 'Коротко'},
          {
            ...topicJson(23, 'Тревога'),
            'full_description': '<p>Страх <b>неизвестности</b></p>',
          },
        ]),
      });
      await harness.open(tester, AppRoutes.topics);

      expect(card(tester, 22).body, 'Коротко');
      expect(card(tester, 23).body, 'Страх неизвестности');
    });

    testWidgets('"Читать" in the unfolded card opens the topic', (
      tester,
    ) async {
      final harness = ToolsHarness.subscribed();
      final container = await harness.open(tester, AppRoutes.topics);

      await tapAndSettle(tester, find.text('Границы'));
      await tapAndSettle(
        tester,
        find.descendant(
          of: find.byKey(TopicsScreen.cardKey(22)),
          matching: find.text(HomeText.read),
        ),
      );

      expect(currentPath(container), AppRoutes.topic(22));
      expect(find.byType(TopicDetailScreen), findsOneWidget);
    });

    testWidgets('the featured topic opens it', (tester) async {
      final harness = ToolsHarness.subscribed();
      final container = await harness.open(tester, AppRoutes.topics);

      await tapAndSettle(tester, find.byKey(TopicsScreen.featuredKey));
      expect(currentPath(container), AppRoutes.topic(21));
    });

    testWidgets('the "инструменты" badge switches back to the tools list', (
      tester,
    ) async {
      final harness = ToolsHarness.subscribed();
      final container = await harness.open(tester, AppRoutes.tools);
      await tapAndSettle(tester, find.byKey(ToolsScreen.topicsLinkKey));
      expect(currentPath(container), AppRoutes.topics);

      final link = find.byKey(TopicsScreen.toolsLinkKey);
      expect(tester.widget<AppBadge>(link).label, TopicsText.toolsLink);
      await tapAndSettle(tester, link);

      expect(currentPath(container), AppRoutes.tools);
      expect(find.byType(ToolsScreen), findsOneWidget);
      expect(find.byType(TopicsScreen), findsNothing);
    });
  });

  group('ТЗ 5.6 — состояния списка', () {
    testWidgets('an empty list says so', (tester) async {
      final harness = ToolsHarness.subscribed({getTopics: catalog(null)});
      await harness.open(tester, AppRoutes.topics);

      expect(find.byType(HomeSectionEmpty), findsOneWidget);
      expect(find.byType(ThemeListCard), findsNothing);
      expect(find.byKey(TopicsScreen.toolsLinkKey), findsOneWidget);
    });

    testWidgets('loading shows the spinner', (tester) async {
      final harness = ToolsHarness.subscribed({
        getTopics: FakeResponse(
          200,
          {'data': sectionJson(null)},
          const {},
          const Duration(seconds: 1),
        ),
      });
      final container = await pumpApp(tester, harness.env);
      container.read(appRouterProvider).go(AppRoutes.topics);
      await tester.pump();
      await tester.pump();

      expect(find.byType(LoadingIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(LoadingIndicator), findsNothing);
    });

    testWidgets('offline: the network error with a retry that reloads', (
      tester,
    ) async {
      final harness = ToolsHarness.subscribed();
      final container = await pumpApp(tester, harness.env);
      harness.backend.offline = true;
      container.read(appRouterProvider).go(AppRoutes.topics);
      await tester.pumpAndSettle();

      expect(find.text(AuthErrorText.network), findsOneWidget);

      harness.backend.offline = false;
      await tapAndSettle(tester, find.text('Повторить'));
      expect(find.byType(ThemeListCard), findsNWidgets(2));
    });

    testWidgets('a server error says the topics could not load', (
      tester,
    ) async {
      final harness = ToolsHarness.subscribed({
        getTopics: FakeResponse.error(500, 'SERVER_ERROR'),
      });
      await harness.open(tester, AppRoutes.topics);

      expect(find.text(TopicsText.loadFailed), findsOneWidget);
    });
  });
}
