import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/home/index.dart';
import 'package:hoffman/features/meditations/index.dart';
import 'package:hoffman/features/profile/index.dart';
import 'package:hoffman/features/tools/index.dart';
import 'package:hoffman/features/topics/index.dart';

import '../../helpers/app_harness.dart';
import '../tools/tools_harness.dart';

void main() {
  Finder inContent(Finder finder) => find.descendant(
    of: find.byKey(TopicDetailScreen.contentKey),
    matching: finder,
  );

  group('ТЗ 5.6 — детальный экран темы', () {
    testWidgets('cover, title, subtitle, full description and "Возможная '
        'работа" as a separate list', (tester) async {
      const coverUrl = 'https://api.example.com/storage/covers/21.jpg';
      final harness = ToolsHarness.subscribed({
        getTopic(21): topicDetail(
          topicJson(21, 'Я жертва', coverImageUrl: coverUrl),
        ),
      });
      final container = await harness.open(tester, AppRoutes.topic(21));

      expect(currentPath(container), AppRoutes.topic(21));
      expect(find.byType(TopicDetailScreen), findsOneWidget);
      expect(
        tester.widget<AppTabBar>(find.byType(AppTabBar)).currentIndex,
        AppTab.tools.index,
      );

      final cover = tester.widget<HomeCoverImage>(
        inContent(find.byType(HomeCoverImage)).first,
      );
      expect(cover.url, Uri.parse(coverUrl));
      expect(cover.fallback, HomeScreen.topicsCover);

      expect(inContent(find.text('Я жертва')), findsOneWidget);
      // The subtitle is its own line, apart from the title.
      expect(
        inContent(find.text(bindShortWords('Подзаголовок: Я жертва'))),
        findsOneWidget,
      );

      final bodies = tester
          .widgetList<LegalDocumentBody>(
            inContent(find.byType(LegalDocumentBody)),
          )
          .map((b) => b.html)
          .toList();
      expect(bodies, [
        '<p>Полное описание темы</p>',
        [
          '<ul><li>Распознавание паттернов: что именно произошло?</li>',
          '<li>Выход в состояние взрослого</li></ul>',
        ].join(),
      ]);

      final possibleWork = find.byKey(TopicDetailScreen.possibleWorkKey);
      await tester.ensureVisible(possibleWork);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: possibleWork,
          matching: find.text(TopicsText.possibleWork),
        ),
        findsOneWidget,
      );
      // Each recommendation is rendered, not only handed over.
      expect(
        find.textContaining(
          'Распознавание паттернов: что именно произошло?',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Выход в состояние взрослого', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a numbered "Возможная работа" from the admin stays numbered', (
      tester,
    ) async {
      const html = '<ol><li>Первое</li><li>Второе</li></ol>';
      final harness = ToolsHarness.subscribed({
        getTopic(22): topicDetail(topicJson(22, 'Границы'), possibleWork: html),
      });
      await harness.open(tester, AppRoutes.topic(22));

      final possibleWork = find.byKey(TopicDetailScreen.possibleWorkKey);
      expect(
        tester
            .widget<LegalDocumentBody>(
              find.descendant(
                of: possibleWork,
                matching: find.byType(LegalDocumentBody),
              ),
            )
            .html,
        html,
      );
    });

    testWidgets('no "Возможная работа" block when the topic has none', (
      tester,
    ) async {
      final harness = ToolsHarness.subscribed({
        getTopic(22): topicDetail(topicJson(22, 'Границы'), possibleWork: null),
      });
      await harness.open(tester, AppRoutes.topic(22));

      expect(find.byKey(TopicDetailScreen.contentKey), findsOneWidget);
      expect(find.byKey(TopicDetailScreen.possibleWorkKey), findsNothing);
      expect(find.text(TopicsText.possibleWork), findsNothing);
    });

    testWidgets('share sends the title and the subtitle', (tester) async {
      final harness = ToolsHarness.subscribed();
      await harness.open(tester, AppRoutes.topic(21));

      await tapAndSettle(tester, find.byKey(TopicDetailScreen.shareKey));

      expect(harness.shared.single.text, 'Я жертва\n\nПодзаголовок: Я жертва');
    });
  });

  group('ТЗ 5.6 — связанные инструменты и медитации', () {
    testWidgets('both kinds of content linked to the topic, in its order', (
      tester,
    ) async {
      final harness = ToolsHarness.subscribed();
      await harness.open(tester, AppRoutes.topic(21));

      final tools = find.byKey(TopicDetailScreen.relatedToolsKey);
      await tester.ensureVisible(tools);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: tools,
          matching: find.text(TopicsText.relatedTools),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widgetList<ToolListCard>(
              find.descendant(of: tools, matching: find.byType(ToolListCard)),
            )
            .map((c) => c.title),
        // tool_ids [12, 11]; the featured tool 11 is found too.
        ['Выражение гнева', 'Распознавание паттернов'],
      );

      final meditations = find.byKey(TopicDetailScreen.relatedMeditationsKey);
      await tester.ensureVisible(meditations);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: meditations,
          matching: find.text(TopicsText.relatedMeditations),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widgetList<MeditationCard>(
              find.descendant(
                of: meditations,
                matching: find.byType(MeditationCard),
              ),
            )
            .map((c) => c.title),
        ['Медитация сочувствия себе'],
      );
      expect(harness.backend.requestsTo(getTools), hasLength(1));
      expect(harness.backend.requestsTo(getMeditationsList), hasLength(1));
    });

    testWidgets('a related tool opens the tool; back returns to the topic', (
      tester,
    ) async {
      final harness = ToolsHarness.subscribed();
      final container = await harness.open(tester, AppRoutes.topic(21));

      await tapAndSettle(tester, find.byKey(TopicDetailScreen.toolCardKey(12)));
      expect(currentPath(container), AppRoutes.tool(12));
      expect(find.byType(ToolDetailScreen), findsOneWidget);

      await tapAndSettle(tester, find.byIcon(Icons.chevron_left));
      expect(currentPath(container), AppRoutes.topic(21));
    });

    testWidgets('a related meditation opens the meditation', (tester) async {
      final harness = ToolsHarness.subscribed({
        'GET /api/v1/meditations/2': FakeResponse(200, {
          'data': meditationJson(2, 'Медитация сочувствия себе'),
        }),
      });
      final container = await harness.open(tester, AppRoutes.topic(21));

      await tapAndSettle(
        tester,
        find.byKey(TopicDetailScreen.meditationCardKey(2)),
      );
      expect(currentPath(container), AppRoutes.meditation(2));
      expect(find.byType(MeditationDetailScreen), findsOneWidget);
    });

    testWidgets('a topic without links asks for no catalog', (tester) async {
      final harness = ToolsHarness.subscribed();
      await harness.open(tester, AppRoutes.topic(22));

      expect(find.byKey(TopicDetailScreen.relatedToolsKey), findsNothing);
      expect(find.byKey(TopicDetailScreen.relatedMeditationsKey), findsNothing);
      expect(harness.backend.requestsTo(getTools), isEmpty);
      expect(harness.backend.requestsTo(getMeditationsList), isEmpty);
    });

    testWidgets('ids missing from the catalogs are skipped', (tester) async {
      final harness = ToolsHarness.subscribed({
        getTopic(21): topicDetail(
          topicJson(21, 'Я жертва'),
          toolIds: [12, 404],
          meditationIds: [404],
        ),
      });
      await harness.open(tester, AppRoutes.topic(21));

      expect(
        find.byKey(TopicDetailScreen.toolCardKey(12), skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byKey(TopicDetailScreen.relatedMeditationsKey), findsNothing);
    });

    testWidgets('a failed catalog keeps the topic and offers a retry', (
      tester,
    ) async {
      final harness = ToolsHarness.subscribed({
        getTools: FakeResponse.error(500, 'SERVER_ERROR'),
      });
      await harness.open(tester, AppRoutes.topic(21));

      expect(find.text('Я жертва'), findsOneWidget);
      final error = find.text(
        TopicsText.relatedLoadFailed,
        skipOffstage: false,
      );
      expect(error, findsOneWidget);

      harness.backend.routes[getTools] = subscribedRoutes[getTools]!;
      await tapAndSettle(tester, find.text('Повторить'));

      expect(error, findsNothing);
      expect(
        find.byKey(TopicDetailScreen.relatedToolsKey, skipOffstage: false),
        findsOneWidget,
      );
    });
  });

  group('ТЗ 5.6 — состояния детального экрана', () {
    testWidgets('an unknown id says the topic is not found', (tester) async {
      final harness = ToolsHarness.subscribed();
      await harness.open(tester, AppRoutes.topic(99));

      expect(find.text(TopicsText.notFound), findsOneWidget);
    });

    testWidgets('offline: the network error; retry loads the topic', (
      tester,
    ) async {
      final harness = ToolsHarness.subscribed();
      final container = await pumpApp(tester, harness.env);
      harness.backend.offline = true;
      container.read(appRouterProvider).go(AppRoutes.topic(22));
      await tester.pumpAndSettle();

      expect(find.text(AuthErrorText.network), findsOneWidget);

      harness.backend.offline = false;
      await tapAndSettle(tester, find.text('Повторить'));
      expect(find.byKey(TopicDetailScreen.contentKey), findsOneWidget);
    });
  });
}
