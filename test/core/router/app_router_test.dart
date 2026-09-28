import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';

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
];

/// Protected routes still served by [PlaceholderScreen].
final Iterable<String> _placeholderRoutes = _protectedRoutes.where(
  (p) =>
      p != AppRoutes.verification &&
      p != AppRoutes.home &&
      !p.startsWith(AppRoutes.profile),
);

/// Bottom tabs other than home, which needs the providers.
const _placeholderTabs = <String>[
  AppRoutes.articles,
  AppRoutes.meditations,
  AppRoutes.tools,
  AppRoutes.diary,
];

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
      initialLocation: AppRoutes.meditations,
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
      // The tab bar is on the tab lists only; content screens are full
      // screen.
      expect(
        find.byType(AppTabBar),
        _placeholderTabs.contains(path) ? findsOneWidget : findsNothing,
        reason: path,
      );
    }
  });

  testWidgets('tab bar: five tabs in the mockup order, tapping one opens its '
      'section and marks it selected', (tester) async {
    final router = createAppRouter(
      initialLocation: AppRoutes.meditations,
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
    expect(bar.currentIndex, AppTab.meditations.index);

    for (final tab in [AppTab.articles, AppTab.tools, AppTab.diary]) {
      await tester.tap(find.bySemanticsLabel(tab.item.label));
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, tab.route);
      expect(
        tester.widget<AppTabBar>(find.byType(AppTabBar)).currentIndex,
        tab.index,
      );
    }
  });

  testWidgets('shows the :id path parameter on a detail route', (tester) async {
    final router = createAppRouter(
      initialLocation: '/meditations/abc-123',
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
