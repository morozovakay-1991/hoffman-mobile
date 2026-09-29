import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:hoffman/features/meditations/application/meditations_providers.dart';
import 'package:hoffman/features/meditations/data/just_audio_engine.dart';
import 'package:hoffman/features/meditations/data/meditations_repository.dart';
import 'package:hoffman/features/meditations/domain/meditation.dart';
import 'package:hoffman/features/meditations/domain/meditation_audio_engine.dart';

@immutable
class MeditationPlayerState {
  const MeditationPlayerState({
    required this.meditation,
    required this.position,
    required this.duration,
    required this.playing,
    required this.completed,
  });

  final Meditation meditation;
  final Duration position;

  /// Of the loaded file; the admin's `duration_seconds` until it is known.
  final Duration duration;

  /// Play was requested and not paused since.
  final bool playing;
  final bool completed;

  /// Whether the button shows "pause" rather than "play".
  bool get isPlaying => playing && !completed;
}

/// Plays one meditation (ТЗ 5.4.3) on the app's [MeditationAudioEngine].
///
/// Loads the meditation and a presigned audio URL from
/// `GET /meditations/{id}/audio`, then starts playing. The URL lives an
/// hour: before a play or a seek past that, and on a playback error, the
/// controller fetches a new one and reloads at the same position, so the
/// user does not notice. A failure it cannot recover from becomes an
/// [AsyncError] for the screen's retry. Closing the screen stops playback.
class MeditationPlayerController extends AsyncNotifier<MeditationPlayerState> {
  MeditationPlayerController(this.meditationId);

  static const Duration skipInterval = Duration(seconds: 10);

  final int meditationId;

  late MeditationAudioEngine _engine;
  Meditation? _meditation;
  MeditationAudio? _audio;

  /// The audio whose playback error was already recovered from by a
  /// reload; a second error on the same URL goes to the screen instead of
  /// reloading in a loop.
  MeditationAudio? _recoveredFrom;

  Duration _position = Duration.zero;
  Duration? _duration;
  EnginePlayback _playback = EnginePlayback.idle;

  /// Whether [state] follows the engine. Off while loading and while an
  /// error is shown.
  bool _live = false;

  @override
  Future<MeditationPlayerState> build() async {
    _engine = ref.watch(meditationAudioEngineProvider);
    _meditation = null;
    _audio = null;
    _recoveredFrom = null;
    _position = Duration.zero;
    _duration = null;
    _playback = EnginePlayback.idle;
    _live = false;

    final subscriptions = [
      _engine.positionStream.listen((p) {
        _position = p;
        _emit();
      }),
      _engine.durationStream.listen((d) {
        _duration = d;
        _emit();
      }),
      _engine.playbackStream.listen((p) {
        _playback = p;
        _emit();
      }),
      _engine.errorStream.listen(_onPlaybackError),
    ];
    ref.onDispose(() {
      for (final s in subscriptions) {
        unawaited(s.cancel());
      }
      unawaited(_engine.stop());
    });

    final meditation = await ref.watch(meditationProvider(meditationId).future);
    _meditation = meditation;
    await _load(at: Duration.zero);
    if (ref.mounted) await _engine.play();
    _live = true;
    return _snapshot(meditation);
  }

  Future<void> play() => _guard(() async {
    if (!await _renewIfExpired(at: _position, resume: true)) {
      if (_playback.completed) await _engine.seek(Duration.zero);
      await _engine.play();
    }
  });

  Future<void> pause() => _guard(_engine.pause);

  Future<void> seekBy(Duration delta) => seekTo(_position + delta);

  Future<void> seekTo(Duration target) => _guard(() async {
    final end = _snapshot(_meditation!).duration;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (end > Duration.zero && target > end ? end : target);
    _position = clamped;
    _emit();
    if (!await _renewIfExpired(at: clamped, resume: _playback.playing)) {
      await _engine.seek(clamped);
    }
  });

  /// After an [AsyncError]: reloads where playback stopped, or from the
  /// start when nothing was loaded yet.
  Future<void> retry() async {
    if (_meditation == null) {
      // GET /meditations/{id} failed; rebuilding refetches it.
      ref.invalidate(meditationProvider(meditationId));
      return;
    }
    _live = false;
    state = const AsyncLoading<MeditationPlayerState>();
    await _guard(() async {
      await _load(at: _position);
      await _engine.play();
      _live = true;
      _emit();
    });
  }

  /// Runs a user action; a failure goes to the screen as [AsyncError].
  Future<void> _guard(Future<void> Function() action) async {
    if (_meditation == null || !ref.mounted) return;
    try {
      await action();
    } on Object catch (error, stackTrace) {
      _fail(error, stackTrace);
    }
  }

  /// Fetches a fresh URL and loads it, paused at [at].
  Future<void> _load({required Duration at}) async {
    final audio = await ref
        .read(meditationsRepositoryProvider)
        .fetchAudio(meditationId);
    if (!ref.mounted) return;
    _audio = audio;
    final meditation = _meditation!;
    await _engine.load(
      audio.url,
      initialPosition: at,
      info: MeditationMediaInfo(
        id: 'meditation-${meditation.id}',
        title: meditation.title,
        artUri: meditation.coverImageUrl,
        duration: meditation.durationSeconds > 0
            ? Duration(seconds: meditation.durationSeconds)
            : null,
      ),
    );
  }

  /// Reloads with a fresh URL at [at] if the current one has expired.
  /// Returns whether it did.
  Future<bool> _renewIfExpired({
    required Duration at,
    required bool resume,
  }) async {
    final audio = _audio;
    final now = ref.read(meditationClockProvider)();
    if (audio != null && !audio.isExpiredAt(now)) return false;
    await _load(at: at);
    if (resume) await _engine.play();
    return true;
  }

  Future<void> _onPlaybackError(Object error) async {
    final audio = _audio;
    if (audio == null || !ref.mounted) return;
    if (identical(_recoveredFrom, audio)) {
      _fail(error, StackTrace.current);
      return;
    }
    // Most likely the storage refused an expired URL while buffering.
    final resume = _playback.playing;
    await _guard(() async {
      await _load(at: _position);
      _recoveredFrom = _audio;
      if (resume) await _engine.play();
    });
  }

  MeditationPlayerState _snapshot(Meditation meditation) {
    final duration = _duration ?? Duration(seconds: meditation.durationSeconds);
    return MeditationPlayerState(
      meditation: meditation,
      position: _position > duration && duration > Duration.zero
          ? duration
          : _position,
      duration: duration,
      playing: _playback.playing,
      completed: _playback.completed,
    );
  }

  void _fail(Object error, StackTrace stackTrace) {
    _live = false;
    if (ref.mounted) state = AsyncError(error, stackTrace);
  }

  /// Publishes the engine's latest values.
  void _emit() {
    final meditation = _meditation;
    if (!_live || meditation == null || !ref.mounted) return;
    state = AsyncData(_snapshot(meditation));
  }
}

final AsyncNotifierProviderFamily<
  MeditationPlayerController,
  MeditationPlayerState,
  int
>
meditationPlayerControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MeditationPlayerController, MeditationPlayerState, int>(
      MeditationPlayerController.new,
      retry: (_, _) => null,
    );
