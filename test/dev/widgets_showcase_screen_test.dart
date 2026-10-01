import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/dev/widgets_showcase_screen.dart';

void main() {
  testWidgets('showcase builds and lists the components', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const WidgetsShowcaseScreen()),
    );

    expect(find.byType(AppButton), findsWidgets);
    expect(find.byType(AppCard), findsWidgets);
    expect(find.byType(AppTextField), findsWidgets);
  });

  testWidgets('showcase lists the AppBadge variants', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const WidgetsShowcaseScreen()),
    );

    await tester.scrollUntilVisible(
      find.widgetWithText(AppBadge, 'инструменты'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    for (final label in ['темы', 'все', 'инструменты']) {
      expect(find.widgetWithText(AppBadge, label), findsOneWidget);
    }
    expect(
      tester
          .widget<AppBadge>(find.widgetWithText(AppBadge, 'выражение').first)
          .variant,
      AppBadgeVariant.tinted,
    );
  });

  testWidgets('showcase lists the four content cards', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const WidgetsShowcaseScreen()),
    );

    for (final type in [
      MeditationCard,
      ArticleListCard,
      ToolListCard,
      ThemeListCard,
    ]) {
      // One of each (the ContentCardList demo has more ToolListCards).
      final card = find.byWidgetPredicate(
        (w) =>
            w.runtimeType == type &&
            (w is! ToolListCard || w.title == 'Выражение гнева'),
      );
      await tester.scrollUntilVisible(
        card,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(card, findsOneWidget);
    }
  });

  testWidgets('ThemeListCard demo toggles on tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const WidgetsShowcaseScreen()),
    );

    await tester.scrollUntilVisible(
      find.byType(ThemeListCard),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byIcon(Icons.add), findsOneWidget);
    await tester.tap(find.text('Границы'));
    await tester.pump();
    expect(find.byIcon(Icons.remove), findsOneWidget);
  });

  testWidgets('showcase lists the LockedOverlay presets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const WidgetsShowcaseScreen()),
    );

    for (final label in [
      'Создать аккаунт',
      'Восстановить доступ',
      'Пройти верификацию',
      LockedOverlayText.lockedDayTitle,
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('showcase opens the ConfirmSheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const WidgetsShowcaseScreen()),
    );

    await tester.scrollUntilVisible(
      find.widgetWithText(AppButton, 'Удалить аккаунт'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(AppButton, 'Удалить аккаунт'));
    await tester.pumpAndSettle();

    expect(find.byType(ConfirmSheet), findsOneWidget);
    expect(find.text('Данные будут удалены безвозвратно'), findsOneWidget);
  });
}
