import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';

import 'pump_themed.dart';

Material _materialOf(WidgetTester tester) {
  return tester.widget<Material>(
    find.descendant(of: find.byType(AppCard), matching: find.byType(Material)),
  );
}

RoundedRectangleBorder _shapeOf(WidgetTester tester) =>
    _materialOf(tester).shape! as RoundedRectangleBorder;

void main() {
  testWidgets('white background, radius/md, grey 0.5px outline', (
    tester,
  ) async {
    await pumpThemed(tester, const AppCard(child: Text('child')));

    expect(_materialOf(tester).color, AppColors.background);
    final shape = _shapeOf(tester);
    expect(shape.borderRadius, AppRadius.mdAll);
    expect(shape.side.color, AppColors.grey);
    expect(shape.side.width, 0.5);
    expect(find.text('child'), findsOneWidget);
  });

  testWidgets('pads its child with spacing/md', (tester) async {
    await pumpThemed(
      tester,
      const AppCard(child: SizedBox(width: 10, height: 10)),
    );

    expect(
      tester.getSize(find.byType(AppCard)),
      const Size(10 + 2 * AppSpacing.md, 10 + 2 * AppSpacing.md),
    );
  });

  testWidgets('borderColor: null removes the outline', (tester) async {
    await pumpThemed(
      tester,
      const AppCard(borderColor: null, child: Text('child')),
    );

    expect(_shapeOf(tester).side, BorderSide.none);
  });

  testWidgets('without onTap there is no InkWell', (tester) async {
    await pumpThemed(tester, const AppCard(child: Text('child')));

    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('onTap goes through an InkWell clipped to the card shape', (
    tester,
  ) async {
    var taps = 0;
    await pumpThemed(
      tester,
      AppCard(onTap: () => taps++, child: const Text('child')),
    );

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.customBorder, _shapeOf(tester));
    await tester.tap(find.text('child'));
    expect(taps, 1);
  });
}
