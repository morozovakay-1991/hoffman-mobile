import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/services/text_sharer.dart';
import 'package:hoffman/features/meditations/index.dart';

import '../../helpers/app_harness.dart';
import '../home/home_harness.dart';

export '../home/home_harness.dart' show meditationJson;

const getMeditations = 'GET /api/v1/meditations';
String getMeditation(int id) => 'GET /api/v1/meditations/$id';
String getAudio(int id) => 'GET /api/v1/meditations/$id/audio';

/// Fixed "now" of the tests; [audioResponse] URLs expire an hour later.
final DateTime testNow = DateTime.utc(2026, 9, 29, 12);

/// `GET /meditations`.
FakeResponse catalogResponse(
  Map<String, Object?>? featured, [
  List<Map<String, Object?>> items = const [],
]) => FakeResponse(200, {
  'data': {'featured': featured, 'items': items},
});

/// `GET /meditations/{id}` of an open meditation.
FakeResponse detailResponse(Map<String, Object?> meditation) =>
    FakeResponse(200, {
      'data': {
        ...meditation,
        'full_description': '<p>Полное описание практики</p>',
        'topic_ids': [3, 5],
      },
    });

final FakeResponse accessDenied = FakeResponse.error(403, 'ACCESS_DENIED');

/// `GET /meditations/{id}/audio`: [url] valid until an hour past [testNow]
/// unless [expiresAt] says otherwise.
FakeResponse audioResponse(String url, {DateTime? expiresAt}) =>
    FakeResponse(200, {
      'data': {
        'url': url,
        'expires_at': (expiresAt ?? testNow.add(const Duration(hours: 1)))
            .toIso8601String(),
      },
    });

/// One [FakeAudioEngine.load] call.
typedef EngineLoad = ({Uri url, Duration at, MeditationMediaInfo info});

/// In-memory [MeditationAudioEngine]: records every call and plays the
/// "file" only as far as the test moves it with [advance].
class FakeAudioEngine implements MeditationAudioEngine {
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration?>.broadcast();
  final _playback = StreamController<EnginePlayback>.broadcast();
  final _errors = StreamController<Object>.broadcast();

  /// Length of the loaded file.
  Duration fileDuration = const Duration(minutes: 25);

  /// Thrown by the next [load] calls while set.
  Exception? loadError;

  final List<EngineLoad> loads = [];
  final List<Duration> seeks = [];
  int playCalls = 0;
  int pauseCalls = 0;
  int stopCalls = 0;
  bool playing = false;
  Duration _current = Duration.zero;

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Stream<Duration?> get durationStream => _duration.stream;

  @override
  Stream<EnginePlayback> get playbackStream => _playback.stream;

  @override
  Stream<Object> get errorStream => _errors.stream;

  @override
  Duration get position => _current;

  @override
  Future<Duration?> load(
    Uri url, {
    required MeditationMediaInfo info,
    Duration initialPosition = Duration.zero,
  }) async {
    final error = loadError;
    if (error != null) throw error;
    loads.add((url: url, at: initialPosition, info: info));
    playing = false;
    _setPosition(initialPosition);
    _duration.add(fileDuration);
    _emitPlayback();
    return fileDuration;
  }

  @override
  Future<void> play() async {
    playCalls++;
    playing = true;
    _emitPlayback();
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    playing = false;
    _emitPlayback();
  }

  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
    _setPosition(position);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    playing = false;
    _emitPlayback();
  }

  @override
  Future<void> dispose() async {}

  /// Playback moved on by [by].
  void advance(Duration by) => _setPosition(_current + by);

  /// A playback failure, e.g. the storage refusing the URL.
  void fail([Object error = 'Response code: 403']) => _errors.add(error);

  void _setPosition(Duration position) {
    _current = position;
    _position.add(position);
  }

  void _emitPlayback() =>
      _playback.add(EnginePlayback(playing: playing, completed: false));
}

/// A signed-in user with the meditation fakes: [engine] instead of
/// just_audio, [shared] collecting what the share sheet got, and a clock
/// at [now].
class MeditationsHarness {
  MeditationsHarness([Map<String, FakeResponse> routes = const {}]) {
    env = TestEnvironment(
      token: 'token',
      backend: FakeBackend({
        me: const FakeResponse(200, {'user': testUserJson}),
        verificationStatus: verification(null),
        getHome: homeResponse(),
        getMeditations: catalogResponse(
          meditationJson(1, 'Утренняя медитация'),
          [
            meditationJson(2, 'Visioning – образ будущего'),
            meditationJson(3, 'Закрытая практика', isLocked: true),
          ],
        ),
        getMeditation(1): detailResponse(
          meditationJson(1, 'Утренняя медитация'),
        ),
        getAudio(1): audioResponse('https://s3.example.com/1.mp3?sig=a'),
        ...routes,
      }),
      extraOverrides: [
        meditationAudioEngineProvider.overrideWithValue(engine),
        textSharerProvider.overrideWithValue((text, {subject, origin}) async {
          shared.add((text: text, subject: subject, origin: origin));
        }),
        meditationClockProvider.overrideWithValue(() => now),
      ],
    );
  }

  late final TestEnvironment env;
  final FakeAudioEngine engine = FakeAudioEngine();
  final List<({String text, String? subject, Rect? origin})> shared = [];
  DateTime now = testNow;

  FakeBackend get backend => env.backend;

  /// Launches the app (on home) and opens [location]: switches to it when
  /// it is a tab, pushes it otherwise.
  Future<ProviderContainer> open(WidgetTester tester, String location) async {
    final container = await pumpApp(tester, env);
    final router = container.read(appRouterProvider);
    if (AppTab.of(location) != null) {
      router.go(location);
    } else {
      unawaited(router.push(location));
    }
    await tester.pumpAndSettle();
    return container;
  }
}
