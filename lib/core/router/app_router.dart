import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/config/feature_flags.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/router/placeholder_screen.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/onboarding/index.dart';

/// Where the session stands, as far as routing is concerned.
enum AuthStatus {
  /// Session not restored yet (splash is checking `/auth/me`, or it failed
  /// offline and offers a retry).
  unknown,
  signedOut,
  signedIn,

  /// Signed in by `/auth/register` in this app session.
  justRegistered,
}

AuthStatus authStatusOf(AsyncValue<AuthState> auth) => switch (auth.value) {
  Authenticated(justRegistered: true) => AuthStatus.justRegistered,
  Authenticated() => AuthStatus.signedIn,
  Unauthenticated() => AuthStatus.signedOut,
  null => AuthStatus.unknown,
};

/// Inputs of [authGuard], read on every navigation.
typedef AuthGuardState = ({AuthStatus status, bool registrationEnabled});

/// Onboarding and auth screens — the only ones a signed-out user may open.
bool isAuthRoute(String location) =>
    location == AppRoutes.onboarding ||
    location == AppRoutes.login ||
    location == AppRoutes.register ||
    location == AppRoutes.forgotPassword ||
    location.startsWith('${AppRoutes.forgotPassword}/');

/// Access control redirect, wired as the router's top-level `redirect`.
///
/// - `/splash` is always reachable; it decides where to go on its own.
/// - `/register` is blocked (→ `/login`) when `registration_enabled` is off.
/// - Before the session is restored everything else waits on `/splash`.
/// - Signed out: only [isAuthRoute] routes; the rest → `/login`.
/// - Signed in: auth routes → `/home`, or → `/verification` right after
///   registration (the verification screens are otherwise normal signed-in
///   routes).
String? authGuard({required String location, required AuthGuardState state}) {
  if (location == AppRoutes.splash) return null;
  if (location == AppRoutes.register && !state.registrationEnabled) {
    return AppRoutes.login;
  }

  switch (state.status) {
    case AuthStatus.unknown:
      return AppRoutes.splash;
    case AuthStatus.signedOut:
      return isAuthRoute(location) ? null : AppRoutes.login;
    case AuthStatus.signedIn:
      return isAuthRoute(location) ? AppRoutes.home : null;
    case AuthStatus.justRegistered:
      return isAuthRoute(location) ? AppRoutes.verification : null;
  }
}

GoRoute _placeholderRoute(String path, String title) {
  return GoRoute(
    path: path,
    builder: (context, state) =>
        PlaceholderScreen(title: title, pathParameters: state.pathParameters),
  );
}

/// Builds a fresh [GoRouter]. [readGuardState] is called on every
/// navigation and on each [refreshListenable] tick; tests pass fixed values.
GoRouter createAppRouter({
  required AuthGuardState Function() readGuardState,
  Listenable? refreshListenable,
  String initialLocation = AppRoutes.splash,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
    redirect: (context, state) =>
        authGuard(location: state.matchedLocation, state: readGuardState()),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      // The four reset steps are siblings (not nested) so `go` to the last
      // one leaves a single page; steps 2–3 are `push`ed for the back stack.
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ResetEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordCode,
        builder: (context, state) => const ResetCodeScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordNewPassword,
        builder: (context, state) => const ResetNewPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordDone,
        builder: (context, state) => const ResetDoneScreen(),
      ),
      // Graduate verification. Siblings like the reset steps: the form is
      // `push`ed from the question, the two results replace the stack.
      GoRoute(
        path: AppRoutes.verification,
        builder: (context, state) => const GraduateQuestionScreen(),
      ),
      GoRoute(
        path: AppRoutes.verificationForm,
        builder: (context, state) => const GraduateFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.verificationConfirmed,
        builder: (context, state) => const GraduateConfirmedScreen(),
      ),
      GoRoute(
        path: AppRoutes.verificationNotConfirmed,
        builder: (context, state) => const GraduateNotConfirmedScreen(),
      ),
      _placeholderRoute(AppRoutes.home, 'Home'),
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

/// App-wide router, wired into `MaterialApp.router`. Re-runs [authGuard]
/// whenever the auth state or the `registration_enabled` flag changes.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(authControllerProvider, (_, _) => refresh.value++)
    ..listen(registrationEnabledProvider, (_, _) => refresh.value++);

  final router = createAppRouter(
    refreshListenable: refresh,
    readGuardState: () => (
      status: authStatusOf(ref.read(authControllerProvider)),
      registrationEnabled: ref.read(registrationEnabledProvider).value ?? true,
    ),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
