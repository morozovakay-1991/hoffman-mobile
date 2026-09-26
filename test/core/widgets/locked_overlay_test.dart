import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/widgets/index.dart';

import 'pump_themed.dart';

Future<void> _pump(WidgetTester tester, Widget overlay) =>
    pumpThemed(tester, SizedBox(width: 393, height: 700, child: overlay));

List<AppButton> _buttons(WidgetTester tester) =>
    tester.widgetList<AppButton>(find.byType(AppButton)).toList();

void main() {
  group('LockedOverlay', () {
    testWidgets('lays out caller texts: title, description, lock, buttons', (
      tester,
    ) async {
      var primary = 0;
      var secondary = 0;
      await _pump(
        tester,
        LockedOverlay(
          title: 'Заголовок',
          description: 'Описание',
          primaryAction: LockedOverlayAction(
            label: 'Первая',
            onPressed: () => primary++,
          ),
          secondaryAction: LockedOverlayAction(
            label: 'Вторая',
            onPressed: () => secondary++,
          ),
        ),
      );

      final titleBottom = tester.getBottomLeft(find.text('Заголовок')).dy;
      final descriptionTop = tester.getTopLeft(find.text('Описание')).dy;
      final lockTop = tester.getTopLeft(find.byIcon(Icons.lock)).dy;
      final firstTop = tester.getTopLeft(find.text('Первая')).dy;
      final secondTop = tester.getTopLeft(find.text('Вторая')).dy;
      expect(descriptionTop, greaterThan(titleBottom));
      expect(lockTop, greaterThan(descriptionTop));
      expect(firstTop, greaterThan(lockTop));
      expect(secondTop, greaterThan(firstTop));

      final buttons = _buttons(tester);
      expect(buttons.map((b) => b.variant), [
        AppButtonVariant.primary,
        AppButtonVariant.secondary,
      ]);
      expect(
        tester.getSize(find.byType(AppButton).first),
        const Size(LockedOverlay.buttonWidth, LockedOverlay.buttonHeight),
      );

      await tester.tap(find.text('Первая'));
      await tester.tap(find.text('Вторая'));
      expect((primary, secondary), (1, 1));
    });

    testWidgets('signedOut preset: sign in / create account', (tester) async {
      var signIn = 0;
      var create = 0;
      await _pump(
        tester,
        LockedOverlay.signedOut(
          onSignIn: () => signIn++,
          onCreateAccount: () => create++,
        ),
      );

      expect(find.text('Доступ ограничен'), findsOneWidget);
      expect(
        find.text('Войдите в аккаунт, чтобы открыть этот раздел'),
        findsOneWidget,
      );
      expect(_buttons(tester).map((b) => b.label), [
        'Войти',
        'Создать аккаунт',
      ]);

      await tester.tap(find.text('Войти'));
      await tester.tap(find.text('Создать аккаунт'));
      expect((signIn, create), (1, 1));
    });

    testWidgets('signedOut preset hides "Создать аккаунт" without callback', (
      tester,
    ) async {
      await _pump(
        tester,
        LockedOverlay.signedOut(onSignIn: () {}, onCreateAccount: null),
      );

      expect(_buttons(tester).map((b) => b.label), ['Войти']);
    });

    testWidgets('inactiveAccount preset: "Восстановить доступ"', (
      tester,
    ) async {
      var restores = 0;
      await _pump(
        tester,
        LockedOverlay.inactiveAccount(onRestoreAccess: () => restores++),
      );

      expect(find.text('Доступ ограничен'), findsOneWidget);
      expect(_buttons(tester).map((b) => b.label), ['Восстановить доступ']);
      await tester.tap(find.text('Восстановить доступ'));
      expect(restores, 1);
    });

    testWidgets('graduateOnly preset: "Пройти верификацию"', (tester) async {
      var verifies = 0;
      await _pump(
        tester,
        LockedOverlay.graduateOnly(onVerify: () => verifies++),
      );

      expect(
        find.text('Доступно после подтверждения статуса выпускника'),
        findsOneWidget,
      );
      expect(_buttons(tester).map((b) => b.label), ['Пройти верификацию']);
      await tester.tap(find.text('Пройти верификацию'));
      expect(verifies, 1);
    });

    testWidgets('lockedDay preset: title and lock only (Figma 131:3602)', (
      tester,
    ) async {
      await _pump(tester, const LockedOverlay.lockedDay());

      expect(
        find.text('Этот день заблокирован. Попробуйте завтра'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.byType(AppButton), findsNothing);
      expect(
        tester.getSize(find.byType(Text)).width,
        lessThanOrEqualTo(LockedOverlay.titleMaxWidth),
      );
    });

    testWidgets('locked child is drawn but not tappable or announced', (
      tester,
    ) async {
      var childTaps = 0;
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        LockedOverlay.graduateOnly(
          onVerify: () {},
          child: GestureDetector(
            onTap: () => childTaps++,
            child: const ColoredBox(
              color: Colors.red,
              child: Center(child: Text('Секретный день')),
            ),
          ),
        ),
      );

      expect(find.text('Секретный день'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      expect(childTaps, 0);
      expect(find.bySemanticsLabel('Секретный день'), findsNothing);
      semantics.dispose();
    });
  });

  group('LockedOverlayText', () {
    // App Store guideline 3.1.1: locked-content copy must not point to a
    // purchase outside the app. Word stems, so every inflection is caught.
    const bannedStems = [
      'подписк',
      'тариф',
      'оплат',
      'купит',
      'покупк',
      'цена',
      'цену',
      'цены',
      'стоимост',
      'на сайт',
      'оформлен',
      'пробный период',
      'пробного период',
      'бесплатн',
    ];

    test('presets use status-only wording', () {
      for (final text in LockedOverlayText.all) {
        for (final stem in bannedStems) {
          expect(
            text.toLowerCase(),
            isNot(contains(stem)),
            reason: '"$text" contains "$stem"',
          );
        }
      }
    });

    test('actions are limited to the approved labels', () {
      expect(
        {
          LockedOverlayText.signIn,
          LockedOverlayText.createAccount,
          LockedOverlayText.restoreAccess,
          LockedOverlayText.verify,
        },
        {
          'Войти',
          'Создать аккаунт',
          'Восстановить доступ',
          'Пройти верификацию',
        },
      );
    });
  });
}
