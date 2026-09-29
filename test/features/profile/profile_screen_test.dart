import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/profile/index.dart';

import '../../helpers/app_harness.dart';
import 'profile_harness.dart';

void main() {
  group('651:3334 / 651:3729 — "Личный кабинет"', () {
    testWidgets('menu: personal data, notifications, legal, sign out — no '
        'subscription item', (tester) async {
      await openProfile(tester, profileEnv());

      expect(find.text('Личный кабинет'), findsOneWidget);
      for (final item in [
        'Личные данные',
        'Уведомления',
        'Правовая информация',
        'Выйти',
      ]) {
        expect(find.widgetWithText(ProfileMenuTile, item), findsOneWidget);
      }
      expect(find.textContaining('Подписк'), findsNothing);
    });

    testWidgets('not verified: "Начать" opens the verification form of the '
        'profile flow (ТЗ 5.2.4)', (tester) async {
      final container = await openProfile(tester, profileEnv());

      expect(find.text('Выпускник Процесса Хоффмана?'), findsOneWidget);
      expect(find.byKey(ProfileScreen.graduateConfirmedKey), findsNothing);

      await tapAndSettle(
        tester,
        find.byKey(ProfileScreen.startVerificationKey),
      );

      expect(currentPath(container), AppRoutes.profileVerification);
      expect(find.byType(GraduateFormScreen), findsOneWidget);
      expect(find.byType(GraduateQuestionScreen), findsNothing);
    });

    for (final status in ['pending', 'rejected']) {
      testWidgets('a $status request still offers verification', (
        tester,
      ) async {
        await openProfile(
          tester,
          profileEnv({verificationStatus: verification(status)}),
        );

        expect(find.byKey(ProfileScreen.startVerificationKey), findsOneWidget);
        expect(find.byKey(ProfileScreen.graduateConfirmedKey), findsNothing);
      });
    }

    testWidgets('confirmed: "Выпускник Процесса Хоффмана" with a check and no '
        '"Начать"', (tester) async {
      await openProfile(
        tester,
        profileEnv({verificationStatus: verification('confirmed')}),
      );

      expect(find.byKey(ProfileScreen.graduateConfirmedKey), findsOneWidget);
      expect(find.text('Выпускник Процесса Хоффмана'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byKey(ProfileScreen.startVerificationKey), findsNothing);
    });

    testWidgets('status unavailable offline: no graduate block, the menu '
        'still works', (tester) async {
      final env = profileEnv();
      final container = await pumpApp(tester, env);
      env.backend.offline = true;
      container.read(appRouterProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();

      expect(find.byKey(ProfileScreen.startVerificationKey), findsNothing);
      expect(find.byKey(ProfileScreen.graduateConfirmedKey), findsNothing);

      await tapAndSettle(
        tester,
        find.widgetWithText(ProfileMenuTile, 'Личные данные'),
      );
      expect(currentPath(container), AppRoutes.profilePersonalData);
    });

    testWidgets('each menu item opens its screen, back returns', (
      tester,
    ) async {
      final container = await openProfile(
        tester,
        profileEnv({
          legalList: const FakeResponse(200, {'data': <Object>[]}),
        }),
      );

      for (final (item, path) in [
        ('Личные данные', AppRoutes.profilePersonalData),
        ('Уведомления', AppRoutes.profileNotifications),
        ('Правовая информация', AppRoutes.profileLegal),
      ]) {
        await tapAndSettle(tester, find.widgetWithText(ProfileMenuTile, item));
        expect(currentPath(container), path, reason: item);

        await tapAndSettle(tester, find.byTooltip('Back'));
        expect(currentPath(container), AppRoutes.profile, reason: item);
      }
    });
  });

  group('1000:3424 — sign out', () {
    testWidgets('"Отменить" keeps the session', (tester) async {
      final env = profileEnv();
      final container = await openProfile(tester, env);

      await tapAndSettle(tester, find.widgetWithText(ProfileMenuTile, 'Выйти'));
      expect(find.text(ProfileScreen.logoutMessage), findsOneWidget);
      await tapAndSettle(tester, find.byKey(ConfirmSheet.cancelKey));

      expect(find.byType(ConfirmSheet), findsNothing);
      expect(currentPath(container), AppRoutes.profile);
      expect(env.backend.requestsTo(logout), isEmpty);
      expect(env.tokenStorage.token, 'token');
    });

    testWidgets('"Выйти" revokes the token and opens the login screen', (
      tester,
    ) async {
      final env = profileEnv();
      final container = await openProfile(tester, env);

      await tapAndSettle(tester, find.widgetWithText(ProfileMenuTile, 'Выйти'));
      await tapAndSettle(tester, find.byKey(ConfirmSheet.confirmKey));

      expect(env.backend.requestsTo(logout), hasLength(1));
      expect(env.tokenStorage.token, isNull);
      expect(currentPath(container), AppRoutes.login);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('offline sign out still ends the session locally', (
      tester,
    ) async {
      final env = profileEnv();
      final container = await openProfile(tester, env);
      env.backend.offline = true;

      await tapAndSettle(tester, find.widgetWithText(ProfileMenuTile, 'Выйти'));
      await tapAndSettle(tester, find.byKey(ConfirmSheet.confirmKey));

      expect(env.tokenStorage.token, isNull);
      expect(currentPath(container), AppRoutes.login);
    });
  });

  testWidgets('the next account on the device never sees the previous '
      "account's profile", (tester) async {
    final env = profileEnv();
    final container = await openProfile(
      tester,
      env,
      location: AppRoutes.profileName,
    );
    expect(
      tester
          .widget<TextField>(fieldIn(EditNameScreen.nameFieldKey))
          .controller!
          .text,
      'Kate',
    );

    unawaited(container.read(authControllerProvider.notifier).logout());
    await tester.pumpAndSettle();
    env.backend.routes
      ..['POST /api/v1/auth/login'] = const FakeResponse(200, {
        'user': {'id': 2, 'name': 'Olga', 'email': 'olga@example.com'},
        'token': 'token-2',
      })
      ..[getProfile] = FakeResponse(200, {
        'profile': profileJson(id: 2, name: 'Olga', email: 'olga@example.com'),
      });
    unawaited(
      container
          .read(authControllerProvider.notifier)
          .login(email: 'olga@example.com', password: 'secret1!'),
    );
    await tester.pumpAndSettle();
    container.read(appRouterProvider).go(AppRoutes.profileName);
    await tester.pump();

    expect(container.read(currentProfileProvider).value?.name, isNot('Kate'));
    await tester.pumpAndSettle();
    expect(container.read(currentProfileProvider).value?.name, 'Olga');
    expect(
      tester
          .widget<TextField>(fieldIn(EditNameScreen.nameFieldKey))
          .controller!
          .text,
      'Olga',
    );
  });
}
