import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';

import 'pump_themed.dart';

InputDecoration _decorationOf(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).decoration!;

BorderSide _side(InputBorder? border) =>
    (border! as OutlineInputBorder).borderSide;

/// The border InputDecorator currently paints.
BorderSide _paintedSide(WidgetTester tester) {
  final decorator = tester.widget<InputDecorator>(find.byType(InputDecorator));
  final decoration = decorator.decoration;
  final InputBorder? border;
  if (!decoration.enabled) {
    border = decoration.disabledBorder;
  } else if (decorator.isFocused) {
    border = decoration.focusedBorder;
  } else {
    border = decoration.enabledBorder;
  }
  return _side(border);
}

void main() {
  testWidgets('idle: blueTint fill, 3px radius, no outline', (tester) async {
    await pumpThemed(tester, const AppTextField(label: 'Пароль'), width: 361);

    final decoration = _decorationOf(tester);
    expect(decoration.filled, isTrue);
    expect(decoration.fillColor, AppColors.blueTint);
    expect(
      (decoration.enabledBorder! as OutlineInputBorder).borderRadius,
      BorderRadius.circular(3),
    );
    expect(_paintedSide(tester), BorderSide.none);
    expect(find.byType(AppCard), findsNothing);
  });

  testWidgets('field box is 34px tall like in Figma', (tester) async {
    await pumpThemed(tester, const AppTextField(label: 'Пароль'), width: 361);

    expect(tester.getSize(find.byType(TextField)).height, closeTo(34, 0.5));
  });

  testWidgets('focused: same fill with a 0.5px black outline', (tester) async {
    await pumpThemed(tester, const AppTextField(label: 'Email'), width: 361);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(_decorationOf(tester).fillColor, AppColors.blueTint);
    final side = _paintedSide(tester);
    expect(side.color, AppColors.basicBlack);
    expect(side.width, 0.5);
  });

  testWidgets('error: fireRed 0.5px outline and message below', (tester) async {
    await pumpThemed(
      tester,
      const AppTextField(label: 'Email', errorText: 'Неверный формат email'),
      width: 361,
    );

    expect(_decorationOf(tester).fillColor, AppColors.blueTint);
    expect(_paintedSide(tester).color, AppColors.fireRed);
    expect(_paintedSide(tester).width, 0.5);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(_paintedSide(tester).color, AppColors.fireRed);

    final error = tester.widget<Text>(find.text('Неверный формат email'));
    expect(error.style?.color, AppColors.fireRed);
    expect(error.style?.fontSize, 12);
    expect(error.style?.fontWeight, FontWeight.w400);
    expect(
      tester.getTopLeft(find.text('Неверный формат email')).dy,
      greaterThan(tester.getBottomLeft(find.byType(TextField)).dy),
    );
  });

  testWidgets('disabled: grey fill, no outline', (tester) async {
    await pumpThemed(
      tester,
      const AppTextField(label: 'Пароль', enabled: false),
      width: 361,
    );

    expect(_decorationOf(tester).fillColor, AppColors.grey);
    expect(_paintedSide(tester), BorderSide.none);
  });

  testWidgets('helperText: black bodySmall below the field', (tester) async {
    await pumpThemed(
      tester,
      const AppTextField(
        label: 'Номер телефона',
        helperText: 'Введите номер телефона',
      ),
      width: 361,
    );

    final helper = tester.widget<Text>(find.text('Введите номер телефона'));
    expect(helper.style?.color, AppColors.basicBlack);
    expect(helper.style?.fontSize, 12);
    expect(
      tester.getTopLeft(find.text('Введите номер телефона')).dy,
      greaterThan(tester.getBottomLeft(find.byType(TextField)).dy),
    );
  });

  testWidgets('errorText replaces helperText', (tester) async {
    await pumpThemed(
      tester,
      const AppTextField(
        label: 'Номер телефона',
        helperText: 'Подсказка',
        errorText: 'Ошибка',
      ),
      width: 361,
    );

    expect(find.text('Подсказка'), findsNothing);
    expect(find.text('Ошибка'), findsOneWidget);
  });

  testWidgets('isRequired shows an asterisk after the label', (tester) async {
    await pumpThemed(
      tester,
      const AppTextField(label: 'Email', isRequired: true),
      width: 361,
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('*'), findsOneWidget);
  });

  testWidgets('no asterisk by default', (tester) async {
    await pumpThemed(tester, const AppTextField(label: 'Email'), width: 361);

    expect(find.text('*'), findsNothing);
  });

  testWidgets('forwards input to controller and onChanged', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? changed;
    await pumpThemed(
      tester,
      AppTextField(
        label: 'Имя',
        controller: controller,
        onChanged: (value) => changed = value,
      ),
      width: 361,
    );

    await tester.enterText(find.byType(TextField), 'Анна');
    expect(controller.text, 'Анна');
    expect(changed, 'Анна');
  });

  testWidgets('passes keyboardType, obscureText and enabled through', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      const AppTextField(
        label: 'Пароль',
        keyboardType: TextInputType.visiblePassword,
        obscureText: true,
        enabled: false,
      ),
      width: 361,
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.visiblePassword);
    expect(field.obscureText, isTrue);
    expect(field.enabled, isFalse);
  });
}
