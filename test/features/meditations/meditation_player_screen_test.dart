import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/meditations/index.dart';

import '../../helpers/app_harness.dart';
import 'meditations_harness.dart';

final String _player = '${AppRoutes.meditation(1)}/player';
final Uri _firstUrl = Uri.parse('https://s3.example.com/1.mp3?sig=a');
const String _secondUrl = 'https://s3.example.com/1.mp3?sig=b';

IconData? _playPauseIcon(WidgetTester tester) =>
    (tester
                .widget<IconButton>(
                  find.byKey(MeditationPlayerScreen.playPauseKey),
                )
                .icon
            as Icon)
        .icon;

void main() {
  group('ТЗ 5.4.3 — аудиоплеер', () {
    testWidgets('loads the presigned URL from /audio (never audio_path) and '
        'starts playing over the full-screen cover', (tester) async {
      final harness = MeditationsHarness();
      await harness.open(tester, _player);

      expect(harness.backend.requestsTo(getAudio(1)), hasLength(1));
      final load = harness.engine.loads.single;
      expect(load.url, _firstUrl);
      expect(load.at, Duration.zero);
      expect(load.info.title, 'Утренняя медитация');
      expect(load.info.duration, const Duration(minutes: 25));
      expect(harness.engine.playing, isTrue);

      expect(find.text('Утренняя медитация'), findsOneWidget);
      expect(find.byType(MeditationShareButton), findsOneWidget);
      expect(find.text('0:00'), findsOneWidget);
      expect(find.text('25:00'), findsOneWidget);
      expect(_playPauseIcon(tester), Icons.pause_circle_filled_rounded);
    });

    testWidgets('the progress follows playback', (tester) async {
      final harness = MeditationsHarness();
      await harness.open(tester, _player);

      harness.engine.advance(const Duration(minutes: 1, seconds: 5));
      await tester.pumpAndSettle();

      expect(find.text('1:05'), findsOneWidget);
      final slider = tester.widget<Slider>(
        find.byKey(MeditationPlayerScreen.progressKey),
      );
      expect(slider.value, closeTo(65 / 1500, 1e-9));
    });

    testWidgets('play/pause toggles playback', (tester) async {
      final harness = MeditationsHarness();
      await harness.open(tester, _player);
      final button = find.byKey(MeditationPlayerScreen.playPauseKey);

      await tapAndSettle(tester, button);
      expect(harness.engine.pauseCalls, 1);
      expect(harness.engine.playing, isFalse);
      expect(_playPauseIcon(tester), Icons.play_circle_filled_rounded);

      await tapAndSettle(tester, button);
      expect(harness.engine.playCalls, 2);
      expect(harness.engine.playing, isTrue);
      expect(_playPauseIcon(tester), Icons.pause_circle_filled_rounded);
    });

    testWidgets('±10 s skips, clamped to the start and the end', (
      tester,
    ) async {
      final harness = MeditationsHarness();
      await harness.open(tester, _player);
      final engine = harness.engine;

      await tapAndSettle(tester, find.byKey(MeditationPlayerScreen.forwardKey));
      expect(engine.seeks.last, const Duration(seconds: 10));
      expect(find.text('0:10'), findsOneWidget);

      engine.advance(const Duration(seconds: 25));
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.byKey(MeditationPlayerScreen.rewindKey));
      expect(engine.seeks.last, const Duration(seconds: 25));

      await tapAndSettle(tester, find.byKey(MeditationPlayerScreen.rewindKey));
      await tapAndSettle(tester, find.byKey(MeditationPlayerScreen.rewindKey));
      await tapAndSettle(tester, find.byKey(MeditationPlayerScreen.rewindKey));
      expect(engine.seeks.last, Duration.zero);

      engine.advance(const Duration(minutes: 24, seconds: 55));
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.byKey(MeditationPlayerScreen.forwardKey));
      expect(engine.seeks.last, const Duration(minutes: 25));
      // Seeking reloads nothing while the URL is fresh.
      expect(engine.loads, hasLength(1));
    });

    testWidgets('dragging the progress bar seeks', (tester) async {
      final harness = MeditationsHarness();
      await harness.open(tester, _player);

      await tester.tap(find.byKey(MeditationPlayerScreen.progressKey));
      await tester.pumpAndSettle();

      // The middle of the bar: half of 25 minutes.
      expect(
        harness.engine.seeks.last.inSeconds,
        closeTo(const Duration(minutes: 12, seconds: 30).inSeconds, 2),
      );
    });

    testWidgets('an expired URL is renewed on the next seek and playback '
        'goes on from the same place', (tester) async {
      final harness = MeditationsHarness();
      await harness.open(tester, _player);
      final engine = harness.engine..advance(const Duration(minutes: 3));
      await tester.pumpAndSettle();

      harness.backend.routes[getAudio(1)] = audioResponse(
        _secondUrl,
        expiresAt: testNow.add(const Duration(hours: 2)),
      );
      harness.now = testNow.add(const Duration(minutes: 61));
      await tapAndSettle(tester, find.byKey(MeditationPlayerScreen.forwardKey));

      expect(harness.backend.requestsTo(getAudio(1)), hasLength(2));
      expect(engine.loads, hasLength(2));
      expect(engine.loads.last.url, Uri.parse(_secondUrl));
      expect(engine.loads.last.at, const Duration(minutes: 3, seconds: 10));
      expect(engine.playing, isTrue);
      expect(find.byType(ErrorStateWidget), findsNothing);
    });

    testWidgets('an expired URL is renewed before resuming from pause', (
      tester,
    ) async {
      final harness = MeditationsHarness();
      await harness.open(tester, _player);
      final button = find.byKey(MeditationPlayerScreen.playPauseKey);
      await tapAndSettle(tester, button);

      harness.backend.routes[getAudio(1)] = audioResponse(_secondUrl);
      harness.now = testNow.add(const Duration(hours: 1));
      await tapAndSettle(tester, button);

      expect(harness.engine.loads.last.url, Uri.parse(_secondUrl));
      expect(harness.engine.playing, isTrue);
    });

    testWidgets('a playback error reloads a fresh URL once, without the '
        'user noticing; a second one shows a retry', (tester) async {
      final harness = MeditationsHarness();
      await harness.open(tester, _player);
      final engine = harness.engine..advance(const Duration(minutes: 2));
      await tester.pumpAndSettle();

      harness.backend.routes[getAudio(1)] = audioResponse(_secondUrl);
      engine.fail();
      await tester.pumpAndSettle();

      expect(engine.loads, hasLength(2));
      expect(engine.loads.last.url, Uri.parse(_secondUrl));
      expect(engine.loads.last.at, const Duration(minutes: 2));
      expect(engine.playing, isTrue);
      expect(find.byType(ErrorStateWidget), findsNothing);

      engine.fail();
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.text(MeditationsText.audioLoadFailed), findsOneWidget);

      await tapAndSettle(tester, find.byType(AppButton));

      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(engine.loads, hasLength(3));
      expect(engine.loads.last.at, const Duration(minutes: 2));
      expect(engine.playing, isTrue);
    });

    testWidgets('audio that fails to load shows a retry, not silence', (
      tester,
    ) async {
      final harness = MeditationsHarness({
        getAudio(1): FakeResponse.error(500, 'SERVER_ERROR'),
      });
      await harness.open(tester, _player);

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.text(MeditationsText.audioLoadFailed), findsOneWidget);
      expect(harness.engine.loads, isEmpty);

      harness.backend.routes[getAudio(1)] = audioResponse(_secondUrl);
      await tapAndSettle(tester, find.byType(AppButton));

      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(harness.engine.loads.single.url, Uri.parse(_secondUrl));
      expect(harness.engine.playing, isTrue);
    });

    testWidgets('a file the player cannot open shows a retry', (tester) async {
      final harness = MeditationsHarness();
      harness.engine.loadError = Exception('Source error');
      await harness.open(tester, _player);

      expect(find.text(MeditationsText.audioLoadFailed), findsOneWidget);

      harness.engine.loadError = null;
      await tapAndSettle(tester, find.byType(AppButton));

      expect(harness.engine.loads, hasLength(1));
      expect(find.byType(ErrorStateWidget), findsNothing);
    });

    testWidgets('offline: the network text and a retry', (tester) async {
      final harness = MeditationsHarness({
        getAudio(1): FakeResponse.error(500, 'SERVER_ERROR'),
      });
      await harness.open(tester, AppRoutes.meditation(1));
      harness.backend.offline = true;

      await tapAndSettle(
        tester,
        find.byKey(MeditationDetailScreen.playerButtonKey),
      );

      expect(find.text(AuthErrorText.network), findsOneWidget);
      expect(find.byType(ErrorStateWidget), findsOneWidget);
    });

    testWidgets('opened directly while offline: the retry refetches the '
        'meditation too', (tester) async {
      final harness = MeditationsHarness();
      final container = await pumpApp(tester, harness.env);
      harness.backend.offline = true;
      unawaited(container.read(appRouterProvider).push(_player));
      await tester.pumpAndSettle();

      expect(find.text(AuthErrorText.network), findsOneWidget);

      harness.backend.offline = false;
      await tapAndSettle(tester, find.byType(AppButton));

      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.text('Утренняя медитация'), findsOneWidget);
      expect(harness.engine.loads, hasLength(1));
      expect(harness.engine.playing, isTrue);
    });

    testWidgets('403 ACCESS_DENIED shows the lock, not the player', (
      tester,
    ) async {
      final harness = MeditationsHarness({
        getMeditation(3): accessDenied,
        getAudio(3): accessDenied,
      });
      await harness.open(tester, '${AppRoutes.meditation(3)}/player');

      expect(tester.takeException(), isNull);
      expect(find.byKey(MeditationLockedView.viewKey), findsOneWidget);
      expect(
        find.text(LockedOverlayText.graduatesOnlySectionTitle),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.byType(FlowerBackground), findsOneWidget);
      expect(find.byIcon(MeditationTopBar.backIcon), findsOneWidget);
      expect(find.byKey(MeditationPlayerScreen.playPauseKey), findsNothing);
      expect(harness.engine.loads, isEmpty);
    });

    testWidgets('share in the top right corner sends the title and the '
        'short description', (tester) async {
      final harness = MeditationsHarness();
      await harness.open(tester, _player);

      final share = tester.getCenter(find.byType(MeditationShareButton));
      final screen = tester.getSize(find.byType(MeditationPlayerScreen));
      expect(share.dx, greaterThan(screen.width * 0.8));
      expect(share.dy, lessThan(screen.height * 0.2));

      await tapAndSettle(tester, find.byType(MeditationShareButton));

      expect(
        harness.shared.single.text,
        'Утренняя медитация\n\nОписание: Утренняя медитация',
      );
    });

    testWidgets('closing the player stops playback and releases the '
        'audio', (tester) async {
      final harness = MeditationsHarness();
      final container = await harness.open(tester, AppRoutes.meditation(1));
      await tapAndSettle(
        tester,
        find.byKey(MeditationDetailScreen.playerButtonKey),
      );
      expect(harness.engine.playing, isTrue);

      container.read(appRouterProvider).pop();
      await tester.pumpAndSettle();

      expect(currentPath(container), AppRoutes.meditation(1));
      expect(harness.engine.stopCalls, 1);
      expect(harness.engine.playing, isFalse);

      // Later engine events reach no disposed controller.
      harness.engine.advance(const Duration(seconds: 1));
      harness.engine.fail();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(harness.engine.loads, hasLength(1));
    });
  });
}
