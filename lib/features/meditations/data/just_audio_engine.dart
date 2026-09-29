import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/features/meditations/domain/meditation_audio_engine.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// [MeditationAudioEngine] over a single just_audio [AudioPlayer]. With
/// just_audio_background initialized in `main`, playback continues while
/// the app is in the background and shows in the system media controls.
class JustAudioEngine implements MeditationAudioEngine {
  JustAudioEngine([AudioPlayer? player]) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Stream<EnginePlayback> get playbackStream => _player.playerStateStream.map(
    (s) => EnginePlayback(
      playing: s.playing,
      completed: s.processingState == ProcessingState.completed,
    ),
  );

  @override
  Stream<Object> get errorStream => _player.errorStream;

  @override
  Duration get position => _player.position;

  @override
  Future<Duration?> load(
    Uri url, {
    required MeditationMediaInfo info,
    Duration initialPosition = Duration.zero,
  }) {
    return _player.setAudioSource(
      AudioSource.uri(
        url,
        tag: MediaItem(
          id: info.id,
          title: info.title,
          artUri: info.artUri,
          duration: info.duration,
        ),
      ),
      initialPosition: initialPosition,
    );
  }

  @override
  Future<void> play() {
    // just_audio's play() completes only when playback pauses or ends; its
    // failures also arrive on [errorStream].
    _player.play().ignore();
    return Future.value();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

/// The app's only audio player — just_audio_background supports a single
/// [AudioPlayer]. Kept for the app's lifetime; each player screen stops it
/// when it closes.
final meditationAudioEngineProvider = Provider<MeditationAudioEngine>((ref) {
  final engine = JustAudioEngine();
  ref.onDispose(engine.dispose);
  return engine;
});
