import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/onboarding/index.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/app_harness.dart';

const _me = 'GET /api/v1/auth/me';

void main() {
  group('splash (131:2674 → 131:2679 → 131:2685)', () {
    testWidgets('plays logo → wordmark → statistics before routing', (
      tester,
    ) async {
      final container = await pumpApp(
        tester,
        TestEnvironment(),
        skipSplash: false,
      );
      await tester.pump();

      expect(find.byType(Image), findsNWidgets(2)); // background + logo
      expect(find.text('hoffman'), findsNothing);

      await tester.pump(SplashScreen.phaseDurations[0]);
      await tester.pumpAndSettle();
      expect(find.text('hoffman'), findsOneWidget);

      await tester.pump(SplashScreen.phaseDurations[1]);
      await tester.pumpAndSettle();
      expect(find.text('16 стран'), findsOneWidget);
      expect(find.text('150 000\nучастников'), findsOneWidget);
      expect(currentPath(container), AppRoutes.splash);

      await tester.pump(SplashScreen.phaseDurations[2]);
      await tester.pumpAndSettle();
      expect(currentPath(container), AppRoutes.login);
    });

    testWidgets('a valid stored token (GET /auth/me → 200) opens home', (
      tester,
    ) async {
      final env = TestEnvironment(
        token: 'stored',
        backend: FakeBackend({
          _me: const FakeResponse(200, {'user': testUserJson}),
        }),
      );
      final container = await pumpApp(tester, env);

      expect(currentPath(container), AppRoutes.home);
      expect(
        env.backend.requestsTo(_me).single.headers['Authorization'],
        'Bearer stored',
      );
    });

    testWidgets('a rejected token (401) is dropped and Login opens', (
      tester,
    ) async {
      final env = TestEnvironment(
        token: 'expired',
        backend: FakeBackend({_me: FakeResponse.error(401, 'UNAUTHENTICATED')}),
      );
      final container = await pumpApp(tester, env);

      expect(currentPath(container), AppRoutes.login);
      expect(env.tokenStorage.token, isNull);
    });

    testWidgets('offline with a stored token shows a retry, not a spinner', (
      tester,
    ) async {
      final env = TestEnvironment(
        token: 'stored',
        backend: FakeBackend({
          _me: const FakeResponse(200, {'user': testUserJson}),
        }),
      )..backend.offline = true;
      final container = await pumpApp(tester, env);

      expect(currentPath(container), AppRoutes.splash);
      expect(find.byType(ErrorStateWidget), findsOneWidget);
      // The token is kept: the session may still be valid.
      expect(env.tokenStorage.token, 'stored');

      env.backend.offline = false;
      await tapAndSettle(tester, find.text('Повторить'));
      await tester.pump(SplashScreen.totalDuration);
      await tester.pumpAndSettle();

      expect(currentPath(container), AppRoutes.home);
    });
  });

  group('onboarding (131:2735, 131:2755, 131:2695, 131:2715)', () {
    testWidgets('first launch shows onboarding; "Далее" walks the four '
        'slides and ends on Login', (tester) async {
      final container = await pumpApp(
        tester,
        TestEnvironment(onboardingSeen: false),
      );
      expect(currentPath(container), AppRoutes.onboarding);

      for (final slide in OnboardingScreen.slides) {
        expect(find.text(slide.title), findsOneWidget);
        await tapAndSettle(tester, find.byKey(OnboardingScreen.nextKey));
      }

      expect(currentPath(container), AppRoutes.login);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(OnboardingRepository.seenKey), isTrue);
    });

    testWidgets('progress indicator highlights the current slide', (
      tester,
    ) async {
      await pumpApp(tester, TestEnvironment(onboardingSeen: false));

      List<Color?> barColors() => tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .map((c) => (c.decoration as BoxDecoration?)?.color)
          .toList();

      expect(barColors(), [
        Colors.black,
        Colors.white,
        Colors.white,
        Colors.white,
      ]);

      await tapAndSettle(tester, find.byKey(OnboardingScreen.nextKey));

      expect(barColors(), [
        Colors.white,
        Colors.black,
        Colors.white,
        Colors.white,
      ]);
    });

    testWidgets('"Пропустить" marks onboarding as seen and opens Login', (
      tester,
    ) async {
      final container = await pumpApp(
        tester,
        TestEnvironment(onboardingSeen: false),
      );

      await tapAndSettle(tester, find.byKey(OnboardingScreen.skipKey));

      expect(currentPath(container), AppRoutes.login);
      expect(find.byType(LoginScreen), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(OnboardingRepository.seenKey), isTrue);
    });

    testWidgets('is shown only once: the next launch goes to Login', (
      tester,
    ) async {
      final container = await pumpApp(
        tester,
        TestEnvironment(), // onboarding_seen = true in shared_preferences
      );

      expect(currentPath(container), AppRoutes.login);
      expect(find.byType(OnboardingScreen), findsNothing);
    });
  });
}
