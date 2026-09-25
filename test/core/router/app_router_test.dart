import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
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
  '/profile',
  '/profile/personal-data',
  '/profile/subscription',
  '/profile/notifications',
  '/profile/legal',
  '/profile/delete-account',
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
      initialLocation: AppRoutes.home,
      readGuardState: () => _state(AuthStatus.signedIn),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    for (final path in _protectedRoutes.where(
      (p) => p != AppRoutes.verification,
    )) {
      router.go(path);
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, path);
      expect(find.byType(PlaceholderScreen), findsOneWidget);
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
