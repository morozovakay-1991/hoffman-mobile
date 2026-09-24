import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';

import 'pump_themed.dart';

Material _materialOf(WidgetTester tester) {
  return tester.widget<Material>(
    find.descendant(
      of: find.byType(AppButton),
      matching: find.byType(Material),
    ),
  );
}

BorderSide _sideOf(WidgetTester tester) =>
    (_materialOf(tester).shape! as RoundedRectangleBorder).side;

Color? _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

void main() {
  testWidgets('calls onPressed on tap', (tester) async {
    var taps = 0;
    await pumpThemed(
      tester,
      AppButton(label: 'Войти', onPressed: () => taps++),
    );

    await tester.tap(find.text('Войти'));
    expect(taps, 1);
  });

  testWidgets('primary, secondary and text tap through an InkWell', (
    tester,
  ) async {
    for (final variant in AppButtonVariant.values) {
      var taps = 0;
      await pumpThemed(
        tester,
        AppButton(label: 'Ок', variant: variant, onPressed: () => taps++),
      );

      final inkWell = tester.widget<InkWell>(
        find.descendant(
          of: find.byType(AppButton),
          matching: find.byType(InkWell),
        ),
      );
      expect(inkWell.onTap, isNotNull, reason: variant.name);
      expect(inkWell.customBorder, _materialOf(tester).shape);
      await tester.tap(find.text('Ок'));
      expect(taps, 1, reason: variant.name);
    }
  });

  testWidgets('uses a fixed 3px corner radius', (tester) async {
    await pumpThemed(tester, AppButton(label: 'Ок', onPressed: () {}));

    final shape = _materialOf(tester).shape! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(3));
    expect(AppButton.radius, 3);
  });

  testWidgets('primary: black fill, light blue tint with icon', (tester) async {
    await pumpThemed(
      tester,
      AppButton(
        label: 'Читать',
        trailingIcon: Icons.arrow_forward_rounded,
        onPressed: () {},
      ),
    );

    expect(_materialOf(tester).color, AppColors.basicBlack);
    expect(_sideOf(tester), BorderSide.none);
    expect(_labelColor(tester, 'Читать'), AppColors.lightBlueTint);
    final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_forward_rounded));
    expect(icon.color, AppColors.lightBlueTint);
    expect(icon.size, 16);
  });

  testWidgets('primary without icon uses white label', (tester) async {
    await pumpThemed(tester, AppButton(label: 'Сохранить', onPressed: () {}));

    expect(_labelColor(tester, 'Сохранить'), AppColors.background);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('secondary: white fill with 0.5px black outline', (tester) async {
    await pumpThemed(
      tester,
      AppButton(
        label: 'Продолжить',
        variant: AppButtonVariant.secondary,
        onPressed: () {},
      ),
    );

    expect(_materialOf(tester).color, AppColors.background);
    final side = _sideOf(tester);
    expect(side.width, 0.5);
    expect(side.color, AppColors.basicBlack);
    expect(_labelColor(tester, 'Продолжить'), AppColors.basicBlack);
  });

  testWidgets('primary and secondary are at least 130x25', (tester) async {
    await pumpThemed(tester, AppButton(label: 'Ок', onPressed: () {}));

    final size = tester.getSize(find.byType(AppButton));
    expect(size.width, greaterThanOrEqualTo(AppButton.minWidth));
    expect(size.height, greaterThanOrEqualTo(AppButton.minHeight));
  });

  testWidgets('text variant has no fill or outline', (tester) async {
    await pumpThemed(
      tester,
      AppButton(
        label: 'Начать',
        variant: AppButtonVariant.text,
        onPressed: () {},
      ),
    );

    final material = _materialOf(tester);
    expect(material.type, MaterialType.transparency);
    expect(material.color, isNull);
    expect(_sideOf(tester), BorderSide.none);
    expect(_labelColor(tester, 'Начать'), AppColors.basicBlack);
  });

  group('disabled (null onPressed)', () {
    for (final variant in [
      AppButtonVariant.primary,
      AppButtonVariant.secondary,
    ]) {
      testWidgets('${variant.name}: grey fill, black label, no icon', (
        tester,
      ) async {
        await pumpThemed(
          tester,
          AppButton(
            label: 'Войти',
            variant: variant,
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: null,
          ),
        );

        expect(_materialOf(tester).color, AppColors.grey);
        expect(_sideOf(tester), BorderSide.none);
        expect(_labelColor(tester, 'Войти'), AppColors.basicBlack);
        expect(find.byType(Icon), findsNothing);
      });
    }

    testWidgets('is announced as a disabled button', (tester) async {
      await pumpThemed(
        tester,
        const AppButton(label: 'Войти', onPressed: null),
      );

      expect(
        tester.getSemantics(find.byType(AppButton)),
        matchesSemantics(isButton: true, hasEnabledState: true, label: 'Войти'),
      );
      await tester.tap(find.text('Войти'));
    });
  });
}
