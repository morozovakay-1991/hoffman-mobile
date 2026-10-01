import 'package:flutter/material.dart';
import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/meditations/domain/meditation.dart';
import 'package:hoffman/features/meditations/presentation/meditations_text.dart';

/// Whether [error] is the backend's 403 `ACCESS_DENIED`.
bool isAccessDenied(Object? error) =>
    error is ApiException && error.failure is AccessDeniedFailure;

/// Whether [error] is the backend's 404.
bool isNotFound(Object? error) =>
    error is ApiException && error.failure is NotFoundFailure;

/// A meditation the user's access level does not open (403
/// `ACCESS_DENIED`), full screen in place of its content or player —
/// Figma 139:5278 (`Closed section/content`): the [FlowerBackground], the
/// back chevron of [MeditationTopBar] on top, and in the center
/// [LockedOverlayText.graduatesOnlySectionTitle] with the 20px lock under it
/// ([LockedOverlay]). No buttons.
class MeditationLockedView extends StatelessWidget {
  const MeditationLockedView({required this.onBack, super.key});

  static const Key viewKey = ValueKey('meditation-locked');

  /// Figma puts its two-line 112px block (text, gap, lock) 267px below the
  /// back bar in the 682px between it and the tab bar, a little above the
  /// middle; a taller block keeps the same relative position.
  static const Alignment blockAlignment = Alignment(0, 2 * 267 / 570 - 1);

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: viewKey,
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FlowerBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MeditationTopBar(onBack: onBack),
                const Expanded(
                  child: LockedOverlay(
                    title: LockedOverlayText.graduatesOnlySectionTitle,
                    alignment: blockAlignment,
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

/// The share icon ([ShareButton]) with the meditation's title and short
/// description ([MeditationsText.shareText]).
class MeditationShareButton extends StatelessWidget {
  const MeditationShareButton({
    required this.meditation,
    super.key,
    this.color = AppColors.basicBlack,
  });

  final Meditation meditation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ShareButton(
      text: MeditationsText.shareText(meditation),
      subject: meditation.title,
      color: color,
    );
  }
}

/// Back chevron on the left, [trailing] (the share icon) on the right: the
/// 40px Figma row with 16px sides. Both are [TopBarIconButton]s, so their
/// 24×24 glyph boxes sit on the same center line, 16px from the edges.
class MeditationTopBar extends StatelessWidget {
  const MeditationTopBar({
    required this.onBack,
    super.key,
    this.trailing,
    this.color = AppColors.basicBlack,
  });

  static const double height = TopBarIconButton.tapSize;
  static const double iconSize = TopBarIconButton.iconSize;
  static const IconData backIcon = Icons.chevron_left;

  /// Figma's 16px side padding to the glyph, minus the tap square's inset.
  static const double _sidePadding = AppSpacing.md - TopBarIconButton.inset;

  final VoidCallback onBack;
  final Widget? trailing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            TopBarIconButton(
              icon: backIcon,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              color: color,
              onPressed: onBack,
            ),
            const Spacer(),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
