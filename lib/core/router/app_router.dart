import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/config/feature_flags.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/router/app_tab_shell.dart';
import 'package:hoffman/core/router/placeholder_screen.dart';
import 'package:hoffman/features/articles/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/home/index.dart';
import 'package:hoffman/features/meditations/index.dart';
import 'package:hoffman/features/onboarding/index.dart';
import 'package:hoffman/features/profile/index.dart';

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
/// - `/account-deleted` is always reachable: it is opened while the deleted
///   account is still signed in and must survive the sign-out that follows.
/// - `/register` is blocked (→ `/login`) when `registration_enabled` is off.
/// - Before the session is restored everything else waits on `/splash`.
/// - Signed out: only [isAuthRoute] routes; the rest → `/login`.
/// - Signed in: auth routes → `/home`, or → `/verification` right after
///   registration (the verification screens are otherwise normal signed-in
///   routes).
String? authGuard({required String location, required AuthGuardState state}) {
  if (location == AppRoutes.splash) return null;
  if (location == AppRoutes.accountDeleted) return null;
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

/// An [AppTab] route: switching tabs replaces the screen without a
/// transition.
GoRoute _tabRoute(String path, Widget screen) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) =>
        NoTransitionPage(key: state.pageKey, child: screen),
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
      // Everything signed-in users browse sits in the shell, above the tab
      // bar (Figma "ui" and "Профиль"): the tab lists are switched with `go`,
      // content and profile screens are `push`ed inside the shell. The
      // player, full screen by design, is the only one left outside.
      ShellRoute(
        builder: (context, state, child) =>
            AppTabShell(location: state.uri.path, child: child),
        routes: [
          _tabRoute(AppRoutes.home, const HomeScreen()),
          _tabRoute(AppRoutes.articles, const ArticlesScreen()),
          _tabRoute(AppRoutes.meditations, const MeditationsScreen()),
          _tabRoute(AppRoutes.tools, const PlaceholderScreen(title: 'Tools')),
          _tabRoute(AppRoutes.diary, const PlaceholderScreen(title: 'Diary')),
          GoRoute(
            path: '/meditations/:id',
            builder: (context, state) => MeditationDetailScreen(
              id: int.tryParse(state.pathParameters['id']!),
            ),
          ),
          _placeholderRoute('/tools/:id', 'Tool'),
          _placeholderRoute(AppRoutes.topics, 'Topics'),
          _placeholderRoute('/topics/:id', 'Topic'),
          _placeholderRoute('/diary/:id', 'Diary entry'),
          GoRoute(
            path: '/articles/:id',
            builder: (context, state) => ArticleDetailScreen(
              id: int.tryParse(state.pathParameters['id']!),
            ),
          ),
          // Profile. Flat siblings like the auth steps: every sub-screen is
          // `push`ed, so back returns to wherever it was opened from. There
          // is no subscription screen by design — subscriptions are managed
          // on the website only.
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.profilePersonalData,
            builder: (context, state) => const PersonalDataScreen(),
          ),
          GoRoute(
            path: AppRoutes.profileName,
            builder: (context, state) => const EditNameScreen(),
          ),
          GoRoute(
            path: AppRoutes.profileEmail,
            builder: (context, state) => const EditEmailScreen(),
          ),
          GoRoute(
            path: AppRoutes.profileEmailCode,
            builder: (context, state) => const EmailCodeScreen(),
          ),
          GoRoute(
            path: AppRoutes.profilePassword,
            builder: (context, state) => const ChangePasswordScreen(),
          ),
          // Graduate verification retried from the profile (ТЗ 5.2.4): the
          // `/verification` screens again, but with the bar and starting on
          // the form. The post-registration flow stays outside the shell.
          GoRoute(
            path: AppRoutes.profileVerification,
            builder: (context, state) =>
                const GraduateFormScreen(flow: VerificationFlow.profile),
          ),
          GoRoute(
            path: AppRoutes.profileVerificationConfirmed,
            builder: (context, state) => const GraduateConfirmedScreen(),
          ),
          GoRoute(
            path: AppRoutes.profileVerificationNotConfirmed,
            builder: (context, state) => const GraduateNotConfirmedScreen(
              flow: VerificationFlow.profile,
            ),
          ),
          GoRoute(
            path: AppRoutes.profileDeleteAccount,
            builder: (context, state) => const DeleteAccountScreen(),
          ),
          GoRoute(
            path: AppRoutes.profileNotifications,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profileLegal,
            builder: (context, state) => const LegalDocumentsScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.profileLegal}/:slug',
            builder: (context, state) =>
                LegalDocumentScreen(slug: state.pathParameters['slug']!),
          ),
        ],
      ),
      // Pushed from the meditation (inside the shell) onto the root
      // navigator, so it covers the tab bar.
      GoRoute(
        path: '/meditations/:id/player',
        builder: (context, state) => MeditationPlayerScreen(
          id: int.tryParse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.accountDeleted,
        builder: (context, state) => const AccountDeletedScreen(),
      ),
    ],
  );
}

/// App-wide router, wired into `MaterialApp.router`. Re-runs [authGuard]
/// whenever the auth state or the `registration_enabled` flag changes.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    // Only the session status matters to the guard. Refreshing on every
    // AuthState change (e.g. the profile renaming the user) would re-apply
    // a stale location over a navigation made in the same frame.
    ..listen(
      authControllerProvider.select(authStatusOf),
      (_, _) => refresh.value++,
    )
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
