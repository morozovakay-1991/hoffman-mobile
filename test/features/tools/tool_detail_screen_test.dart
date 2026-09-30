import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/home/index.dart';
import 'package:hoffman/features/profile/index.dart';
import 'package:hoffman/features/tools/index.dart';

import '../../helpers/app_harness.dart';
import 'tools_harness.dart';

void main() {
  group('ТЗ 5.5 — детальный экран инструмента', () {
    testWidgets('cover, title, short description, stage badge and the full '
        'description as rich text', (tester) async {
      const coverUrl = 'https://api.example.com/storage/covers/11.jpg';
      final harness = ToolsHarness.subscribed({
        getTool(11): toolDetail(
          toolJson(11, 'Распознавание паттернов', coverImageUrl: coverUrl),
        ),
      });
      final container = await harness.open(tester, AppRoutes.tool(11));

      expect(currentPath(container), AppRoutes.tool(11));
      expect(find.byType(ToolDetailScreen), findsOneWidget);
      expect(harness.backend.requestsTo(getTool(11)), hasLength(1));
      // Inside the tools tab.
      expect(
        tester.widget<AppTabBar>(find.byType(AppTabBar)).currentIndex,
        AppTab.tools.index,
      );

      final content = find.byKey(ToolDetailScreen.contentKey);
      final cover = tester.widget<HomeCoverImage>(
        find.descendant(of: content, matching: find.byType(HomeCoverImage)),
      );
      expect(cover.url, Uri.parse(coverUrl));
      expect(cover.fallback, HomeScreen.toolsCover);

      expect(find.text('Распознавание паттернов'), findsOneWidget);
      expect(find.text('Описание: Распознавание паттернов'), findsOneWidget);
      expect(
        tester
            .widget<AppBadge>(
              find.descendant(of: content, matching: find.byType(AppBadge)),
            )
            .label,
        'выражение',
      );

      final body = tester.widget<LegalDocumentBody>(
        find.byType(LegalDocumentBody),
      );
      expect(body.html, '<p>Полное описание упражнения</p>');
      expect(find.byType(Html), findsOneWidget);
    });

    testWidgets('share sends the title and the short description', (
      tester,
    ) async {
      final harness = ToolsHarness.subscribed();
      await harness.open(tester, AppRoutes.tool(12));

      await tapAndSettle(tester, find.byKey(ToolDetailScreen.shareKey));

      expect(
        harness.shared.single.text,
        'Выражение гнева\n\nОписание: '
        'Выражение гнева',
      );
      expect(harness.shared.single.subject, 'Выражение гнева');
    });

    testWidgets('back returns to the list', (tester) async {
      final harness = ToolsHarness.subscribed();
      final container = await harness.open(tester, AppRoutes.tools);

      await tapAndSettle(tester, find.byKey(ToolsScreen.cardKey(12)));
      expect(currentPath(container), AppRoutes.tool(12));

      await tapAndSettle(tester, find.byIcon(Icons.chevron_left));
      expect(currentPath(container), AppRoutes.tools);
    });

    testWidgets('an unknown or malformed id says the tool is not found', (
      tester,
    ) async {
      final harness = ToolsHarness.subscribed();
      final container = await harness.open(tester, AppRoutes.tool(99));
      expect(find.text(ToolsText.notFound), findsOneWidget);

      container.read(appRouterProvider).go('/tools/abc');
      await tester.pumpAndSettle();
      expect(find.text(ToolsText.notFound), findsOneWidget);
    });

    testWidgets('offline: the network error; retry loads the tool', (
      tester,
    ) async {
      final harness = ToolsHarness.subscribed();
      final container = await pumpApp(tester, harness.env);
      harness.backend.offline = true;
      container.read(appRouterProvider).go(AppRoutes.tool(11));
      await tester.pumpAndSettle();

      expect(find.text(AuthErrorText.network), findsOneWidget);

      harness.backend.offline = false;
      await tapAndSettle(tester, find.text('Повторить'));
      expect(find.byKey(ToolDetailScreen.contentKey), findsOneWidget);
    });
  });
}
