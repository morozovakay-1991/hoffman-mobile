import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/services/text_sharer.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';

typedef _Shared = ({String text, String? subject, Rect? origin});

Future<void> _pump(WidgetTester tester, TextSharer sharer, Widget child) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [textSharerProvider.overrideWithValue(sharer)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  group('ShareButton', () {
    testWidgets('a 24px share icon in the given color, with a tooltip', (
      tester,
    ) async {
      await _pump(
        tester,
        (text, {subject, origin}) async {},
        const ShareButton(text: 'Текст', color: AppColors.background),
      );

      final icon = tester.widget<Icon>(find.byIcon(ShareButton.icon));
      expect(icon.size, ShareButton.iconSize);
      expect(icon.color, AppColors.background);
      expect(find.byTooltip(ShareButton.label), findsOneWidget);
    });

    testWidgets('sends the text and subject, anchored at the button', (
      tester,
    ) async {
      final shared = <_Shared>[];
      await _pump(
        tester,
        (text, {subject, origin}) async =>
            shared.add((text: text, subject: subject, origin: origin)),
        const ShareButton(text: 'Заголовок\n\nОписание', subject: 'Заголовок'),
      );

      await tester.tap(find.byType(ShareButton));
      await tester.pumpAndSettle();

      expect(shared, hasLength(1));
      expect(shared.single.text, 'Заголовок\n\nОписание');
      expect(shared.single.subject, 'Заголовок');
      expect(shared.single.origin, tester.getRect(find.byType(ShareButton)));
    });

    testWidgets('a failure shows a snackbar', (tester) async {
      await _pump(
        tester,
        (text, {subject, origin}) async => throw Exception('no sheet'),
        const ShareButton(text: 'Текст'),
      );

      await tester.tap(find.byType(ShareButton));
      await tester.pumpAndSettle();

      expect(find.text(ShareButton.failed), findsOneWidget);
    });
  });

  group('shareTextOf', () {
    test('title and description apart', () {
      expect(shareTextOf('Статья', ' Описание '), 'Статья\n\nОписание');
    });

    test('no description: the title alone', () {
      expect(shareTextOf('Статья', '  '), 'Статья');
    });
  });
}
