import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/widgets/index.dart';

import 'pump_themed.dart';

void main() {
  group('ErrorStateWidget', () {
    testWidgets('shows message and default retry label', (tester) async {
      await pumpThemed(
        tester,
        ErrorStateWidget(message: 'Нет сети', onRetry: () {}),
      );

      expect(find.text('Нет сети'), findsOneWidget);
      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.label, 'Повторить');
      expect(button.variant, AppButtonVariant.primary);
      expect(
        tester.getTopLeft(find.byType(AppButton)).dy,
        greaterThan(tester.getBottomLeft(find.text('Нет сети')).dy),
      );
    });

    testWidgets('retry button calls onRetry with custom label', (tester) async {
      var retries = 0;
      await pumpThemed(
        tester,
        ErrorStateWidget(
          message: 'Ошибка',
          retryLabel: 'Ещё раз',
          onRetry: () => retries++,
        ),
      );

      await tester.tap(find.text('Ещё раз'));
      expect(retries, 1);
    });
  });

  group('EmptyStateWidget', () {
    testWidgets('shows message with default inbox icon and no button', (
      tester,
    ) async {
      await pumpThemed(tester, const EmptyStateWidget(message: 'Пусто'));

      expect(find.text('Пусто'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.byType(AppButton), findsNothing);
    });

    testWidgets('locked-day state: lock icon below centered titleLarge text', (
      tester,
    ) async {
      const message = 'Этот день заблокирован.\nПопробуйте завтра';
      await pumpThemed(
        tester,
        const EmptyStateWidget(message: message, icon: Icons.lock),
      );

      final text = tester.widget<Text>(find.text(message));
      final textTheme = Theme.of(tester.element(find.text(message))).textTheme;
      expect(text.textAlign, TextAlign.center);
      expect(text.style?.fontSize, textTheme.titleLarge?.fontSize);
      expect(
        tester.getTopLeft(find.byIcon(Icons.lock)).dy,
        greaterThan(tester.getBottomLeft(find.text(message)).dy),
      );
      expect(find.byType(AppButton), findsNothing);
    });

    testWidgets('illustration replaces the icon', (tester) async {
      await pumpThemed(
        tester,
        const EmptyStateWidget(
          message: 'Пусто',
          illustration: SizedBox(key: Key('illustration')),
        ),
      );

      expect(find.byKey(const Key('illustration')), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsNothing);
    });
  });
}
