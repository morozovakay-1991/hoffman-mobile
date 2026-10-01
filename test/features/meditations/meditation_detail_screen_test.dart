import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/meditations/index.dart';

import '../../helpers/app_harness.dart';
import 'meditations_harness.dart';

void main() {
  group('ТЗ 5.4.2 — детальный экран медитации', () {
    testWidgets('shows the cover, title, duration, both descriptions and '
        'the share icon', (tester) async {
      final harness = MeditationsHarness();
      await harness.open(tester, AppRoutes.meditation(1));

      expect(harness.backend.requestsTo(getMeditation(1)), hasLength(1));
      expect(find.text('Утренняя медитация'), findsOneWidget);
      expect(find.text('25 минут'), findsOneWidget);
      expect(find.text('Описание: Утренняя медитация'), findsOneWidget);
      expect(
        find.textContaining('Полное описание практики', findRichText: true),
        findsOneWidget,
      );
      expect(find.byType(MeditationShareButton), findsOneWidget);
      expect(
        find.byKey(MeditationDetailScreen.playerButtonKey),
        findsOneWidget,
      );
      // Nothing is played before the player opens.
      expect(harness.backend.requestsTo(getAudio(1)), isEmpty);
    });

    testWidgets('the player button pushes /meditations/:id/player', (
      tester,
    ) async {
      final harness = MeditationsHarness();
      final container = await harness.open(tester, AppRoutes.meditation(1));
      expectGridButton(
        tester,
        find.byKey(MeditationDetailScreen.playerButtonKey),
      );

      await tapAndSettle(
        tester,
        find.byKey(MeditationDetailScreen.playerButtonKey),
      );

      expect(currentPath(container), '${AppRoutes.meditation(1)}/player');
      expect(find.byType(MeditationPlayerScreen), findsOneWidget);

      container.read(appRouterProvider).pop();
      await tester.pumpAndSettle();
      expect(currentPath(container), AppRoutes.meditation(1));
    });

    testWidgets('share sends the title and the short description', (
      tester,
    ) async {
      final harness = MeditationsHarness();
      await harness.open(tester, AppRoutes.meditation(1));

      await tapAndSettle(tester, find.byType(MeditationShareButton));

      expect(harness.shared, hasLength(1));
      expect(
        harness.shared.single.text,
        'Утренняя медитация\n\nОписание: Утренняя медитация',
      );
      expect(harness.shared.single.subject, 'Утренняя медитация');
      expect(harness.shared.single.origin, isNotNull);
    });

    testWidgets('403 ACCESS_DENIED shows the lock instead of the content '
        'and never offers the player', (tester) async {
      final harness = MeditationsHarness({getMeditation(3): accessDenied});
      await harness.open(tester, AppRoutes.meditation(3));

      expect(tester.takeException(), isNull);
      expect(find.byKey(MeditationLockedView.viewKey), findsOneWidget);
      expect(find.text(LockedOverlayText.restrictedTitle), findsOneWidget);
      expect(find.byType(LockedMark), findsOneWidget);
      expect(find.byKey(MeditationDetailScreen.playerButtonKey), findsNothing);
      expect(find.byType(MeditationShareButton), findsNothing);
      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(harness.backend.requestsTo(getAudio(3)), isEmpty);
    });

    testWidgets('a locked card of the list leads to the lock screen', (
      tester,
    ) async {
      final harness = MeditationsHarness({getMeditation(3): accessDenied});
      await harness.open(tester, AppRoutes.meditations);

      await tapAndSettle(tester, find.byKey(MeditationsScreen.cardKey(3)));

      expect(find.byKey(MeditationLockedView.viewKey), findsOneWidget);
    });

    testWidgets('offline: a retry, then the content', (tester) async {
      final harness = MeditationsHarness();
      final container = await pumpApp(tester, harness.env);
      harness.backend.offline = true;
      unawaited(
        container.read(appRouterProvider).push(AppRoutes.meditation(1)),
      );
      await tester.pumpAndSettle();

      expect(find.text(AuthErrorText.network), findsOneWidget);

      harness.backend.offline = false;
      await tapAndSettle(tester, find.byType(AppButton));

      expect(find.text('Утренняя медитация'), findsOneWidget);
    });

    testWidgets('a non-numeric id says it is not found without a request', (
      tester,
    ) async {
      final harness = MeditationsHarness();
      await harness.open(tester, '/meditations/abc');

      expect(find.text(MeditationsText.notFound), findsOneWidget);
      expect(
        harness.backend.requests.where(
          (r) => r.path.startsWith('/api/v1/meditations'),
        ),
        isEmpty,
      );
    });

    testWidgets('an unknown meditation says it is not found', (tester) async {
      final harness = MeditationsHarness();
      await harness.open(tester, AppRoutes.meditation(99));

      expect(find.text(MeditationsText.notFound), findsOneWidget);
      expect(find.byType(ErrorStateWidget), findsNothing);
    });
  });
}
