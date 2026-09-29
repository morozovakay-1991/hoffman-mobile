import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/home/index.dart';
import 'package:hoffman/features/meditations/index.dart';
import 'package:hoffman/features/profile/index.dart';

import '../../features/home/home_harness.dart';
import '../../features/meditations/meditations_harness.dart';
import '../../helpers/app_harness.dart';

const _protectedRoutes = <String>[
  '/verification',
  '/home',
  '/meditations',
  '/meditations/42',
  '/meditations/42/player',
  '/tools',
  '/tools/42',
  '/topics',
  '/topics/42',
  '/diary',
  '/diary/42',
  '/articles',
  '/articles/42',
  AppRoutes.profile,
  AppRoutes.profilePersonalData,
  AppRoutes.profileName,
  AppRoutes.profileEmail,
  AppRoutes.profileEmailCode,
  AppRoutes.profilePassword,
  AppRoutes.profileDeleteAccount,
  AppRoutes.profileNotifications,
  AppRoutes.profileLegal,
  '/profile/legal/privacy',
  AppRoutes.profileVerification,
  AppRoutes.profileVerificationConfirmed,
  AppRoutes.profileVerificationNotConfirmed,
];

/// Protected routes still served by [PlaceholderScreen].
final Iterable<String> _placeholderRoutes = _protectedRoutes.where(
  (p) =>
      p != AppRoutes.verification &&
      p != AppRoutes.home &&
      !p.startsWith(AppRoutes.meditations) &&
      !p.startsWith(AppRoutes.profile),
);

const _authRoutes = <String>[
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
  AppRoutes.forgotPasswordCode,
  AppRoutes.forgotPasswordNewPassword,
  AppRoutes.forgotPasswordDone,
];

AuthGuardState _state(AuthStatus status, {bool registration = true}) =>
    (status: status, registrationEnabled: registration);

void main() {
  group('authGuard', () {
    test('signed out: every protected route redirects to /login', () {
      for (final path in _protectedRoutes) {
        expect(
          authGuard(location: path, state: _state(AuthStatus.signedOut)),
          AppRoutes.login,
          reason: path,
        );
      }
    });

    test('signed out: onboarding and auth routes are open', () {
      for (final path in [AppRoutes.splash, ..._authRoutes]) {
        expect(
          authGuard(location: path, state: _state(AuthStatus.signedOut)),
          isNull,
          reason: path,
        );
      }
    });

    test('signed in: protected routes are open, auth routes → /home', () {
      for (final path in _protectedRoutes) {
        expect(
          authGuard(location: path, state: _state(AuthStatus.signedIn)),
          isNull,
          reason: path,
        );
      }
      for (final path in _authRoutes) {
        expect(
          authGuard(location: path, state: _state(AuthStatus.signedIn)),
          AppRoutes.home,
          reason: path,
        );
      }
    });

    test('right after registration auth routes lead to /verification', () {
      final state = _state(AuthStatus.justRegistered);
      expect(
        authGuard(location: AppRoutes.register, state: state),
        AppRoutes.verification,
      );
      expect(authGuard(location: AppRoutes.verification, state: state), isNull);
      expect(authGuard(location: AppRoutes.home, state: state), isNull);
    });

    test('session not restored yet: everything waits on /splash', () {
      final state = _state(AuthStatus.unknown);
      expect(authGuard(location: AppRoutes.splash, state: state), isNull);
      expect(
        authGuard(location: AppRoutes.home, state: state),
        AppRoutes.splash,
      );
      expect(
        authGuard(location: AppRoutes.login, state: state),
        AppRoutes.splash,
      );
    });

    test('/account-deleted stays open whatever the session', () {
      for (final status in AuthStatus.values) {
        expect(
          authGuard(location: AppRoutes.accountDeleted, state: _state(status)),
          isNull,
          reason: '$status',
        );
      }
    });

    test('registration_enabled = false blocks /register for everyone', () {
      for (final status in AuthStatus.values) {
        expect(
          authGuard(
            location: AppRoutes.register,
            state: _state(status, registration: false),
          ),
          AppRoutes.login,
          reason: '$status',
        );
      }
      expect(
        authGuard(
          location: AppRoutes.login,
          state: _state(AuthStatus.signedOut, registration: false),
        ),
        isNull,
      );
    });
  });

  testWidgets('signed in: navigates to every placeholder route', (
    tester,
  ) async {
    final router = createAppRouter(
      initialLocation: AppRoutes.articles,
      readGuardState: () => _state(AuthStatus.signedIn),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    for (final path in _placeholderRoutes) {
      router.go(path);
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, path);
      expect(find.byType(PlaceholderScreen), findsOneWidget);
      // Tab lists and content screens alike sit above the tab bar; a
      // content screen marks the tab of its section.
      expect(find.byType(AppTabBar), findsOneWidget, reason: path);
      expect(
        tester.widget<AppTabBar>(find.byType(AppTabBar)).currentIndex,
        AppTab.sectionOf(path)?.index ?? -1,
        reason: path,
      );
    }
  });

  testWidgets('tab bar: five tabs in the mockup order, tapping one opens its '
      'section and marks it selected', (tester) async {
    final router = createAppRouter(
      initialLocation: AppRoutes.articles,
      readGuardState: () => _state(AuthStatus.signedIn),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final bar = tester.widget<AppTabBar>(find.byType(AppTabBar));
    expect(bar.items.map((i) => i.label), [
      'Главная',
      'Статьи',
      'Медитации',
      'Инструменты',
      'Дневник',
    ]);
    expect(bar.currentIndex, AppTab.articles.index);

    // Meditations needs the providers; home_screen_test covers its tab.
    for (final tab in [AppTab.tools, AppTab.diary, AppTab.articles]) {
      await tester.tap(find.bySemanticsLabel(tab.item.label));
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, tab.route);
      expect(
        tester.widget<AppTabBar>(find.byType(AppTabBar)).currentIndex,
        tab.index,
      );
    }
  });

  test('AppTab.sectionOf: a tab list or a screen under it', () {
    expect(AppTab.sectionOf(AppRoutes.meditations), AppTab.meditations);
    expect(AppTab.sectionOf(AppRoutes.meditation(42)), AppTab.meditations);
    expect(AppTab.sectionOf('/tools/42'), AppTab.tools);
    expect(AppTab.sectionOf('/meditationsx'), isNull);
    expect(AppTab.sectionOf(AppRoutes.profile), isNull);
    expect(AppTab.sectionOf(AppRoutes.topics), isNull);
    // `of` still matches the tab lists only.
    expect(AppTab.of(AppRoutes.meditation(42)), isNull);
  });

  group('tab bar on the content and profile screens (Figma "ui", '
      '"Профиль")', () {
    AppTabBar bar(WidgetTester tester) =>
        tester.widget<AppTabBar>(find.byType(AppTabBar));

    testWidgets('profile (ТЗ 5.9.1) and its sub-screens keep the bar, with '
        'no tab selected', (tester) async {
      final container = await pumpApp(tester, MeditationsHarness().env);
      final router = container.read(appRouterProvider);

      await tapAndSettle(tester, find.byKey(HomeScreen.menuKey));
      expect(currentPath(container), AppRoutes.profile);
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.byType(AppTabBar), findsOneWidget);
      expect(bar(tester).currentIndex, -1);

      for (final path in [
        AppRoutes.profilePersonalData,
        AppRoutes.profileName,
        AppRoutes.profileNotifications,
        AppRoutes.profileLegal,
      ]) {
        unawaited(router.push(path));
        await tester.pumpAndSettle();
        expect(currentPath(container), path);
        expect(find.byType(AppTabBar), findsOneWidget, reason: path);
      }

      // Back walks the pushed stack down to the profile, then home.
      for (var i = 0; i < 4; i++) {
        router.pop();
        await tester.pumpAndSettle();
      }
      expect(currentPath(container), AppRoutes.profile);
      router.pop();
      await tester.pumpAndSettle();
      expect(currentPath(container), AppRoutes.home);
      expect(bar(tester).currentIndex, AppTab.home.index);
    });

    testWidgets('a tab tapped on the profile switches to that tab', (
      tester,
    ) async {
      final container = await pumpApp(tester, MeditationsHarness().env);

      await tapAndSettle(tester, find.byKey(HomeScreen.menuKey));
      await tapAndSettle(
        tester,
        find.bySemanticsLabel(AppTab.meditations.item.label),
      );

      expect(currentPath(container), AppRoutes.meditations);
      expect(find.byType(MeditationsScreen), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);
    });

    testWidgets('meditation (ТЗ 5.4.2) keeps the bar on the meditations tab; '
        'the player covers it', (tester) async {
      final harness = MeditationsHarness();
      final container = await harness.open(tester, AppRoutes.meditation(1));

      expect(find.byType(MeditationDetailScreen), findsOneWidget);
      expect(find.byType(AppTabBar), findsOneWidget);
      expect(bar(tester).currentIndex, AppTab.meditations.index);

      await tapAndSettle(
        tester,
        find.byKey(MeditationDetailScreen.playerButtonKey),
      );
      expect(currentPath(container), '${AppRoutes.meditation(1)}/player');
      expect(find.byType(MeditationPlayerScreen), findsOneWidget);
      // The shell stays mounted under the player, offstage.
      expect(find.byType(AppTabBar), findsNothing);

      container.read(appRouterProvider).pop();
      await tester.pumpAndSettle();
      expect(currentPath(container), AppRoutes.meditation(1));
      expect(find.byType(AppTabBar), findsOneWidget);
    });

    testWidgets('a deep link to the player opens it without the bar', (
      tester,
    ) async {
      final harness = MeditationsHarness();
      final container = await pumpApp(tester, harness.env);
      container.read(appRouterProvider).go('${AppRoutes.meditation(1)}/player');
      await tester.pumpAndSettle();

      expect(find.byType(MeditationPlayerScreen), findsOneWidget);
      expect(find.byType(AppTabBar), findsNothing);
    });

    group('graduate verification (ТЗ 5.2.4)', () {
      const submit = 'POST /api/v1/verification/submit';

      /// A signed-in user whose previous request was rejected, so the form
      /// is prefilled; the next submit answers [result].
      TestEnvironment verificationEnv(String result) => homeEnv({
        verificationStatus: verification('rejected'),
        submit: verification(result),
      });

      Future<void> submitForm(WidgetTester tester) async {
        for (final key in ['consent-privacy', 'consent-personal-data']) {
          await tapAndSettle(
            tester,
            find.descendant(
              of: find.byKey(ValueKey(key)),
              matching: find.byType(Icon),
            ),
          );
        }
        await tapAndSettle(
          tester,
          find.descendant(
            of: find.byKey(GraduateFormScreen.submitKey),
            matching: find.byType(AppButton),
          ),
        );
      }

      testWidgets('from the profile: the form and the result keep the bar; '
          'back from the form returns to the profile', (tester) async {
        final env = verificationEnv('confirmed');
        final container = await pumpApp(tester, env);
        container.read(appRouterProvider).go(AppRoutes.profile);
        await tester.pumpAndSettle();

        await tapAndSettle(
          tester,
          find.byKey(ProfileScreen.startVerificationKey),
        );
        expect(currentPath(container), AppRoutes.profileVerification);
        expect(find.byType(GraduateFormScreen), findsOneWidget);
        expect(find.byType(AppTabBar), findsOneWidget);
        expect(bar(tester).currentIndex, -1);

        await tapAndSettle(tester, find.byTooltip('Back'));
        expect(currentPath(container), AppRoutes.profile);

        await tapAndSettle(
          tester,
          find.byKey(ProfileScreen.startVerificationKey),
        );
        await submitForm(tester);

        expect(env.backend.requestsTo(submit), hasLength(1));
        expect(currentPath(container), AppRoutes.profileVerificationConfirmed);
        expect(find.byType(GraduateConfirmedScreen), findsOneWidget);
        expect(find.byType(AppTabBar), findsOneWidget);
      });

      testWidgets('from the profile: "не подтвержден" keeps the bar, and '
          '"Попробовать снова" stays in the profile flow', (tester) async {
        final env = verificationEnv('rejected');
        final container = await pumpApp(tester, env);
        container.read(appRouterProvider).go(AppRoutes.profileVerification);
        await tester.pumpAndSettle();

        await submitForm(tester);
        expect(
          currentPath(container),
          AppRoutes.profileVerificationNotConfirmed,
        );
        expect(find.byType(GraduateNotConfirmedScreen), findsOneWidget);
        expect(find.byType(AppTabBar), findsOneWidget);

        await tapAndSettle(
          tester,
          find.descendant(
            of: find.byKey(GraduateNotConfirmedScreen.retryKey),
            matching: find.byType(AppButton),
          ),
        );
        expect(currentPath(container), AppRoutes.profileVerification);
        expect(find.byType(AppTabBar), findsOneWidget);

        // Opened with `go`: back has nothing to pop and falls back to the
        // profile, not to the registration question.
        await tapAndSettle(tester, find.byTooltip('Back'));
        expect(currentPath(container), AppRoutes.profile);
      });

      testWidgets('after registration: the same screens stay full screen, '
          'without the bar', (tester) async {
        final env = verificationEnv('rejected');
        final container = await pumpApp(tester, env);
        final router = container.read(appRouterProvider);

        for (final (path, screen) in [
          (AppRoutes.verification, GraduateQuestionScreen),
          (AppRoutes.verificationForm, GraduateFormScreen),
          (AppRoutes.verificationConfirmed, GraduateConfirmedScreen),
          (AppRoutes.verificationNotConfirmed, GraduateNotConfirmedScreen),
        ]) {
          router.go(path);
          await tester.pumpAndSettle();
          expect(find.byType(screen), findsOneWidget, reason: path);
          expect(find.byType(AppTabBar), findsNothing, reason: path);
        }

        // The registration form still leads to the registration results.
        router.go(AppRoutes.verificationForm);
        await tester.pumpAndSettle();
        await submitForm(tester);
        expect(currentPath(container), AppRoutes.verificationNotConfirmed);
        expect(find.byType(AppTabBar), findsNothing);
      });
    });

    testWidgets('the logout sheet opens over the bar', (tester) async {
      await pumpApp(tester, MeditationsHarness().env);
      await tapAndSettle(tester, find.byKey(HomeScreen.menuKey));

      await tapAndSettle(tester, find.text('Выйти'));

      final sheet = find.byType(ConfirmSheet);
      expect(sheet, findsOneWidget);
      // On the root navigator: the sheet is not a descendant of the shell.
      expect(
        find.ancestor(of: sheet, matching: find.byType(AppTabShell)),
        findsNothing,
      );
    });
  });

  testWidgets('shows the :id path parameter on a detail route', (tester) async {
    final router = createAppRouter(
      initialLocation: '/tools/abc-123',
      readGuardState: () => _state(AuthStatus.signedIn),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('id: abc-123'), findsOneWidget);
  });

  testWidgets('signed out: a deep link to a protected route opens /login', (
    tester,
  ) async {
    final router = createAppRouter(
      initialLocation: '/diary/7',
      readGuardState: () => _state(AuthStatus.signedOut),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: TestEnvironment().overrides,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
