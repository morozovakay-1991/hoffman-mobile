import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/app_router.dart';

const _allRoutes = <String>[
  '/splash',
  '/onboarding',
  '/login',
  '/register',
  '/forgot-password',
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

void main() {
  testWidgets('navigates to every placeholder route', (tester) async {
    final router = createAppRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    for (final path in _allRoutes) {
      router.go(path);
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, path);
      expect(find.byType(Scaffold), findsOneWidget);
    }
  });

  testWidgets('shows the :id path parameter on a detail route', (tester) async {
    final router = createAppRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/meditations/abc-123');
    await tester.pumpAndSettle();

    expect(find.text('id: abc-123'), findsOneWidget);
  });

  testWidgets('authGuard (wired as the top-level redirect) lets navigation through unchanged', (
    tester,
  ) async {
    final router = createAppRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/profile');
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/profile');
  });
}
