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

/// The 6×10.7 box of the `section arrow` (the chevron icon is cropped to
/// it).
Rect _arrowBox(WidgetTester tester) => tester.getRect(
  find
      .ancestor(
        of: find.byIcon(Icons.chevron_right_rounded),
        matching: find.byType(SizedBox),
      )
      .first,
);

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

      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      final arrow = _arrowBox(tester);
      expect(arrow.size, AppBadge.arrowSize);
      // Figma 2:33: 8px from the label to the arrow.
      expect(
        arrow.left - tester.getTopRight(find.text(label)).dx,
        AppBadge.arrowGap,
      );
      expect(AppBadge.arrowGap, AppSpacing.sm);
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

  testWidgets('padding: 8px sides, 7px split evenly top and bottom', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      const AppBadge(label: 'выражение', variant: AppBadgeVariant.tinted),
    );

    final badge = tester.getRect(find.byType(AppBadge));
    final text = tester.getRect(find.text('выражение'));
    expect(text.left - badge.left, AppSpacing.sm);
    expect(badge.right - text.right, AppSpacing.sm);
    expect(text.top - badge.top, AppBadge.verticalPadding);
    expect(badge.bottom - text.bottom, AppBadge.verticalPadding);
    expect(text.center.dy, badge.center.dy);
  });

  testWidgets('outlined: text and arrow centered on one line in the badge', (
    tester,
  ) async {
    await pumpThemed(tester, const AppBadge(label: 'все'));

    final badge = tester.getRect(find.byType(AppBadge));
    final text = tester.getCenter(find.text('все'));
    final arrow = _arrowBox(tester).center;
    expect(text.dy, arrow.dy);
    expect(arrow.dy, badge.center.dy);
    expect(
      tester
          .widget<Text>(find.text('все'))
          .textHeightBehavior
          ?.leadingDistribution,
      TextLeadingDistribution.even,
    );
  });

  for (final label in ['все', 'темы', 'инструменты']) {
    testWidgets('outlined "$label": same padding from the content to both '
        'edges', (tester) async {
      await pumpThemed(tester, AppBadge(label: label));

      final badge = tester.getRect(find.byType(AppBadge));
      final text = tester.getRect(find.text(label));
      final arrow = _arrowBox(tester);
      final left = text.left - badge.left;
      final right = badge.right - arrow.right;
      expect(left, AppSpacing.sm);
      expect(right, left);
    });
  }

  testWidgets('onTap is called', (tester) async {
    var taps = 0;
    await pumpThemed(tester, AppBadge(label: 'все', onTap: () => taps++));

    await tester.tap(find.byType(AppBadge));
    expect(taps, 1);
  });
}
