import 'package:flutter/foundation.dart';

/// What the system media controls (notification, lock screen) show while a
/// meditation plays.
@immutable
class MeditationMediaInfo {
  const MeditationMediaInfo({
    required this.id,
    required this.title,
    this.artUri,
    this.duration,
  });

  final String id;
  final String title;
  final Uri? artUri;
  final Duration? duration;
}

/// Where playback stands.
@immutable
class EnginePlayback {
  const EnginePlayback({required this.playing, required this.completed});

  static const EnginePlayback idle = EnginePlayback(
    playing: false,
    completed: false,
  );

  /// Play was requested and not paused since (the audio may still be
  /// buffering).
  final bool playing;

  /// Reached the end of the file.
  final bool completed;
}

/// The single app-wide audio player behind the meditation player screen.
/// Implemented over just_audio + just_audio_background (background playback
/// and system media controls); faked in tests.
abstract interface class MeditationAudioEngine {
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<EnginePlayback> get playbackStream;

  /// Playback failures after [load], e.g. the storage refusing an expired
  /// URL while buffering.
  Stream<Object> get errorStream;

  Duration get position;

  /// Replaces the current audio with [url], paused at [initialPosition].
  /// Throws if the audio cannot be loaded. Resolves to its duration, when
  /// known.
  Future<Duration?> load(
    Uri url, {
    required MeditationMediaInfo info,
    Duration initialPosition = Duration.zero,
  });

  /// Starts playing; resolves once playback has started, not when it ends.
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);

  /// Stops playback and releases the loaded audio; the engine can [load]
  /// again afterwards.
  Future<void> stop();

  Future<void> dispose();
}
