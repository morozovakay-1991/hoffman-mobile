import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/core/services/text_sharer.dart';
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
/// `ACCESS_DENIED`), in place of its content or player. Built like the
/// locked diary block of the home screen: status-only wording, no mention
/// of purchases — subscriptions are managed on the website only.
// TODO(figma): no locked meditation screen in the mockups.
class MeditationLockedView extends StatelessWidget {
  const MeditationLockedView({super.key});

  static const Key viewKey = ValueKey('meditation-locked');

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      key: viewKey,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    LockedOverlayText.restrictedTitle,
                    style: textTheme.titleLarge,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const LockedMark(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            LockedOverlayText.restoreAccessDescription,
            style: textTheme.bodySmall?.copyWith(color: AppColors.softBlack),
          ),
        ],
      ),
    );
  }
}

/// The share icon: opens the system share sheet with the meditation's
/// title and short description ([MeditationsText.shareText]).
class MeditationShareButton extends ConsumerWidget {
  const MeditationShareButton({
    required this.meditation,
    super.key,
    this.color = AppColors.basicBlack,
  });

  static const double iconSize = 24;

  final Meditation meditation;
  final Color color;

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null || !box.hasSize
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    try {
      await ref.read(textSharerProvider)(
        MeditationsText.shareText(meditation),
        subject: meditation.title,
        origin: origin,
      );
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(MeditationsText.shareFailed)),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: MeditationsText.share,
      icon: Icon(Icons.ios_share, size: iconSize, color: color),
      onPressed: () => _share(context, ref),
    );
  }
}

/// Back chevron on the left, [trailing] (the share icon) on the right.
class MeditationTopBar extends StatelessWidget {
  const MeditationTopBar({
    required this.onBack,
    super.key,
    this.trailing,
    this.color = AppColors.basicBlack,
  });

  static const double height = 48;
  static const double iconSize = 24;

  final VoidCallback onBack;
  final Widget? trailing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: Icon(Icons.chevron_left, size: iconSize, color: color),
            onPressed: onBack,
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
