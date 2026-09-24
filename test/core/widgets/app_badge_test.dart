import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';

import 'pump_themed.dart';

BoxDecoration _decoration(WidgetTester tester, String label) {
  final box = tester.widget<DecoratedBox>(
    find
        .ancestor(of: find.text(label), matching: find.byType(DecoratedBox))
        .first,
  );
  return box.decoration as BoxDecoration;
}

void main() {
  testWidgets('outlined is the default variant', (tester) async {
    await pumpThemed(tester, const AppBadge(label: 'темы'));

    expect(
      tester.widget<AppBadge>(find.byType(AppBadge)).variant,
      AppBadgeVariant.outlined,
    );
  });

  for (final label in ['темы', 'все', 'инструменты']) {
    testWidgets('outlined "$label": white, black 0.5px outline, arrow', (
      tester,
    ) async {
      await pumpThemed(tester, AppBadge(label: label));

      final decoration = _decoration(tester, label);
      expect(decoration.color, AppColors.background);
      expect(decoration.borderRadius, AppRadius.mdAll);
      final border = decoration.border! as Border;
      expect(border.top.width, 0.5);
      expect(border.top.color, AppColors.basicBlack);

      final arrow = find.byIcon(Icons.chevron_right_rounded);
      expect(arrow, findsOneWidget);
      expect(
        tester.getTopLeft(arrow).dx - tester.getTopRight(find.text(label)).dx,
        AppSpacing.sm,
      );
    });
  }

  testWidgets('tinted: lightBlueTint, no outline, no arrow', (tester) async {
    await pumpThemed(
      tester,
      const AppBadge(label: 'выражение', variant: AppBadgeVariant.tinted),
    );

    final decoration = _decoration(tester, 'выражение');
    expect(decoration.color, AppColors.lightBlueTint);
    expect(decoration.borderRadius, AppRadius.mdAll);
    expect(decoration.border, isNull);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('label uses labelMedium', (tester) async {
    await pumpThemed(tester, const AppBadge(label: 'все'));

    final style = tester.widget<Text>(find.text('все')).style;
    final labelMedium = Theme.of(tester.element(find.text('все')))
        .textTheme
        .labelMedium;
    expect(style, labelMedium);
  });

  testWidgets('padding: 8px sides, 2px top, 5px bottom', (tester) async {
    await pumpThemed(
      tester,
      const AppBadge(label: 'выражение', variant: AppBadgeVariant.tinted),
    );

    final badge = tester.getRect(find.byType(AppBadge));
    final text = tester.getRect(find.text('выражение'));
    expect(text.left - badge.left, AppSpacing.sm);
    expect(badge.right - text.right, AppSpacing.sm);
    expect(text.top - badge.top, AppSpacing.xxs);
    expect(badge.bottom - text.bottom, 5);
  });

  testWidgets('onTap is called', (tester) async {
    var taps = 0;
    await pumpThemed(tester, AppBadge(label: 'все', onTap: () => taps++));

    await tester.tap(find.byType(AppBadge));
    expect(taps, 1);
  });
}
