import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/placeholder_screen.dart';

/// Placeholder for the access-control redirect. Currently lets every
/// navigation through unchanged — the real auth-state check (redirect to
/// `/login` when signed out, gate `/profile/**` etc.) lands with the auth
/// feature.
FutureOr<String?> authGuard(BuildContext context, GoRouterState state) {
  return null;
}

GoRoute _placeholderRoute(String path, String title) {
  return GoRoute(
    path: path,
    builder: (context, state) =>
        PlaceholderScreen(title: title, pathParameters: state.pathParameters),
  );
}

/// Builds a fresh [GoRouter] instance. Exposed as a factory (rather than
/// only the [appRouter] singleton) so tests can create isolated routers.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/splash',
    redirect: authGuard,
    routes: [
      _placeholderRoute('/splash', 'Splash'),
      _placeholderRoute('/onboarding', 'Onboarding'),
      _placeholderRoute('/login', 'Login'),
      _placeholderRoute('/register', 'Register'),
      _placeholderRoute('/forgot-password', 'Forgot password'),
      _placeholderRoute('/verification', 'Verification'),
      _placeholderRoute('/home', 'Home'),
      _placeholderRoute('/meditations', 'Meditations'),
      _placeholderRoute('/meditations/:id', 'Meditation'),
      _placeholderRoute('/meditations/:id/player', 'Meditation player'),
      _placeholderRoute('/tools', 'Tools'),
      _placeholderRoute('/tools/:id', 'Tool'),
      _placeholderRoute('/topics', 'Topics'),
      _placeholderRoute('/topics/:id', 'Topic'),
      _placeholderRoute('/diary', 'Diary'),
      _placeholderRoute('/diary/:id', 'Diary entry'),
      _placeholderRoute('/articles', 'Articles'),
      _placeholderRoute('/articles/:id', 'Article'),
      _placeholderRoute('/profile', 'Profile'),
      _placeholderRoute('/profile/personal-data', 'Personal data'),
      _placeholderRoute('/profile/subscription', 'Subscription'),
      _placeholderRoute('/profile/notifications', 'Notifications'),
      _placeholderRoute('/profile/legal', 'Legal'),
      _placeholderRoute('/profile/delete-account', 'Delete account'),
    ],
  );
}

/// App-wide router singleton, wired into `MaterialApp.router`.
final GoRouter appRouter = createAppRouter();
