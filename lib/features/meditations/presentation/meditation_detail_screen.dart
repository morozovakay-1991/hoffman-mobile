import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/services/external_url_launcher.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/home/index.dart';
import 'package:hoffman/features/meditations/application/meditations_providers.dart';
import 'package:hoffman/features/meditations/domain/meditation.dart';
import 'package:hoffman/features/meditations/presentation/meditations_text.dart';
import 'package:hoffman/features/meditations/presentation/widgets/meditation_widgets.dart';
import 'package:hoffman/features/profile/index.dart';

/// A meditation (ТЗ 5.4.2), from `GET /meditations/{id}`: cover, title,
/// duration, short and full description, the share icon and the button to
/// the player.
///
/// The cover runs up under the status bar, with the back chevron and the
/// share icon over it, like [HomeSectionCover.underStatusBar].
///
/// A 403 `ACCESS_DENIED` shows the full-screen [MeditationLockedView]
/// instead — the content and the player are never offered.
// TODO(figma): no meditation mockup yet.
class MeditationDetailScreen extends ConsumerWidget {
  const MeditationDetailScreen({required this.id, super.key});

  /// `null` when the route's `:id` is not a number.
  final int? id;

  static const Key playerButtonKey = ValueKey('meditation-player-button');
  static const Key coverKey = ValueKey('meditation-cover');

  /// Height below the status bar.
  static const double coverHeight = 350;

  static String playerRoute(int id) => '${AppRoutes.meditation(id)}/player';

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.meditations);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = this.id;
    final meditation = id == null ? null : ref.watch(meditationProvider(id));
    if (meditation?.error case final error? when isAccessDenied(error)) {
      return MeditationLockedView(onBack: () => _back(context));
    }

    if (meditation?.value case final value?) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _Content(value, onBack: () => _back(context)),
      );
    }

    final body = switch (meditation) {
      null => const _Centered(
        child: EmptyStateWidget(message: MeditationsText.notFound),
      ),
      AsyncValue(:final error?) when isNotFound(error) => const _Centered(
        child: EmptyStateWidget(message: MeditationsText.notFound),
      ),
      AsyncValue(:final error?) => _Centered(
        child: ErrorStateWidget(
          message: MeditationsText.errorText(
            error,
            MeditationsText.meditationLoadFailed,
          ),
          onRetry: () => ref.invalidate(meditationProvider(id!)),
        ),
      ),
      _ => const _Centered(child: LoadingIndicator()),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MeditationTopBar(onBack: () => _back(context)),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: child,
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content(this.meditation, {required this.onBack});

  final Meditation meditation;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final padding = MediaQuery.paddingOf(context);
    final fullDescription = meditation.fullDescription?.trim() ?? '';

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: padding.bottom + AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            key: MeditationDetailScreen.coverKey,
            height: padding.top + MeditationDetailScreen.coverHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                HomeCoverImage(
                  url: meditation.coverImageUrl,
                  fallback: HomeScreen.meditationsCover,
                ),
                Positioned(
                  top: padding.top,
                  left: 0,
                  right: 0,
                  child: MeditationTopBar(
                    onBack: onBack,
                    trailing: MeditationShareButton(meditation: meditation),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(meditation.title, style: textTheme.titleLarge),
                ),
                const SizedBox(height: AppSpacing.md),
                HomeMetaLabel(
                  icon: Icons.watch_later,
                  text: HomeText.duration(meditation.durationSeconds),
                ),
                if (meditation.shortDescription.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    bindShortWords(meditation.shortDescription),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.softBlack,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppGridButton(
                  key: MeditationDetailScreen.playerButtonKey,
                  label: MeditationsText.listen,
                  trailingIcon: Icons.play_arrow_rounded,
                  onPressed: () => context.push(
                    MeditationDetailScreen.playerRoute(meditation.id),
                  ),
                ),
              ],
            ),
          ),
          if (fullDescription.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              // Rich text from the admin, rendered like the legal documents.
              child: LegalDocumentBody(
                html: fullDescription,
                onLinkTap: (uri) => ref.read(externalUrlLauncherProvider)(uri),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
