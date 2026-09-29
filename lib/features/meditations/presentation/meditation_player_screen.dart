import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/home/index.dart';
import 'package:hoffman/features/meditations/application/meditation_player_controller.dart';
import 'package:hoffman/features/meditations/application/meditations_providers.dart';
import 'package:hoffman/features/meditations/domain/meditation.dart';
import 'package:hoffman/features/meditations/presentation/meditations_text.dart';
import 'package:hoffman/features/meditations/presentation/widgets/meditation_widgets.dart';

/// The audio player (ТЗ 5.4.3): the meditation's cover full screen, the
/// share icon in the top right corner, the title, a seekable progress bar
/// with the elapsed and total time, and play/pause with ±10 s skips.
///
/// Playback runs through [MeditationPlayerController] and keeps going in
/// the background; leaving the screen stops it. An audio failure shows a
/// retry, a 403 `ACCESS_DENIED` the [MeditationLockedView].
// TODO(figma): no player mockup yet.
class MeditationPlayerScreen extends ConsumerWidget {
  const MeditationPlayerScreen({required this.id, super.key});

  /// `null` when the route's `:id` is not a number.
  final int? id;

  static const Key playPauseKey = ValueKey('player-play-pause');
  static const Key rewindKey = ValueKey('player-rewind');
  static const Key forwardKey = ValueKey('player-forward');
  static const Key progressKey = ValueKey('player-progress');

  /// Darkens the cover under the white text and controls.
  static const Color scrim = Color(0x80000000);

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      final id = this.id;
      context.go(id == null ? AppRoutes.meditations : AppRoutes.meditation(id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = this.id;
    if (id == null) {
      return _Plain(
        onBack: () => _back(context),
        child: const EmptyStateWidget(message: MeditationsText.notFound),
      );
    }

    final meditation = ref.watch(meditationProvider(id));
    final player = ref.watch(meditationPlayerControllerProvider(id));
    final error = player.error ?? meditation.error;

    if (error != null && !player.isLoading) {
      return _Plain(
        onBack: () => _back(context),
        child: isAccessDenied(error)
            ? const MeditationLockedView()
            : isNotFound(error)
            ? const EmptyStateWidget(message: MeditationsText.notFound)
            : ErrorStateWidget(
                message: MeditationsText.errorText(
                  error,
                  MeditationsText.audioLoadFailed,
                ),
                onRetry: () => ref
                    .read(meditationPlayerControllerProvider(id).notifier)
                    .retry(),
              ),
      );
    }

    final value = meditation.value;
    if (value == null) {
      return _Plain(
        onBack: () => _back(context),
        child: const LoadingIndicator(),
      );
    }

    return _Player(
      meditation: value,
      state: player.value,
      onBack: () => _back(context),
    );
  }
}

/// White screen with the back bar, for the states without a cover.
class _Plain extends StatelessWidget {
  const _Plain({required this.onBack, required this.child});

  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MeditationTopBar(onBack: onBack),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _Player extends ConsumerWidget {
  const _Player({
    required this.meditation,
    required this.state,
    required this.onBack,
  });

  final Meditation meditation;

  /// `null` while the audio is loading.
  final MeditationPlayerState? state;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final state = this.state;
    final controller = ref.read(
      meditationPlayerControllerProvider(meditation.id).notifier,
    );

    return Scaffold(
      backgroundColor: AppColors.basicBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          HomeCoverImage(
            url: meditation.coverImageUrl,
            fallback: HomeScreen.meditationsCover,
          ),
          const ColoredBox(color: MeditationPlayerScreen.scrim),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MeditationTopBar(
                  onBack: onBack,
                  color: AppColors.background,
                  trailing: MeditationShareButton(
                    meditation: meditation,
                    color: AppColors.background,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          meditation.title,
                          style: textTheme.headlineLarge?.copyWith(
                            color: AppColors.background,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (state == null)
                        SizedBox(
                          height: _Controls.height + _Progress.height,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              progressIndicatorTheme:
                                  const ProgressIndicatorThemeData(
                                    color: AppColors.background,
                                  ),
                            ),
                            child: const LoadingIndicator(),
                          ),
                        )
                      else ...[
                        _Progress(
                          position: state.position,
                          duration: state.duration,
                          onSeek: controller.seekTo,
                        ),
                        _Controls(
                          isPlaying: state.isPlaying,
                          onPlay: controller.play,
                          onPause: controller.pause,
                          onRewind: () => controller.seekBy(
                            -MeditationPlayerController.skipInterval,
                          ),
                          onForward: () => controller.seekBy(
                            MeditationPlayerController.skipInterval,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Seekable bar with the elapsed time on the left, the total on the right.
class _Progress extends StatefulWidget {
  const _Progress({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  static const double height = 64;

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  @override
  State<_Progress> createState() => _ProgressState();
}

class _ProgressState extends State<_Progress> {
  /// Where the thumb is while being dragged, 0–1.
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final total = widget.duration.inMilliseconds;
    final played = total <= 0
        ? 0.0
        : (widget.position.inMilliseconds / total).clamp(0.0, 1.0);
    final value = _drag ?? played;
    final shown = _drag == null
        ? widget.position
        : Duration(milliseconds: (total * value).round());
    final timeStyle = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: AppColors.background);

    return SizedBox(
      height: _Progress.height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.background,
              inactiveTrackColor: AppColors.background.withValues(alpha: 0.3),
              thumbColor: AppColors.background,
              overlayColor: AppColors.background.withValues(alpha: 0.1),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              padding: EdgeInsets.zero,
            ),
            child: Slider(
              key: MeditationPlayerScreen.progressKey,
              value: value,
              semanticFormatterCallback: (_) => MeditationsText.time(shown),
              onChanged: total <= 0 ? null : (v) => setState(() => _drag = v),
              onChangeEnd: total <= 0
                  ? null
                  : (v) {
                      setState(() => _drag = null);
                      widget.onSeek(
                        Duration(milliseconds: (total * v).round()),
                      );
                    },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(MeditationsText.time(shown), style: timeStyle),
              Text(MeditationsText.time(widget.duration), style: timeStyle),
            ],
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.isPlaying,
    required this.onPlay,
    required this.onPause,
    required this.onRewind,
    required this.onForward,
  });

  static const double height = 80;
  static const double skipIconSize = 36;
  static const double playIconSize = 64;

  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onRewind;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            key: MeditationPlayerScreen.rewindKey,
            tooltip: MeditationsText.rewind,
            iconSize: skipIconSize,
            color: AppColors.background,
            icon: const Icon(Icons.replay_10_rounded),
            onPressed: onRewind,
          ),
          IconButton(
            key: MeditationPlayerScreen.playPauseKey,
            tooltip: isPlaying ? MeditationsText.pause : MeditationsText.play,
            iconSize: playIconSize,
            color: AppColors.background,
            icon: Icon(
              isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
            ),
            onPressed: isPlaying ? onPause : onPlay,
          ),
          IconButton(
            key: MeditationPlayerScreen.forwardKey,
            tooltip: MeditationsText.forward,
            iconSize: skipIconSize,
            color: AppColors.background,
            icon: const Icon(Icons.forward_10_rounded),
            onPressed: onForward,
          ),
        ],
      ),
    );
  }
}
