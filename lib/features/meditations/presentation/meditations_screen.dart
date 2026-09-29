import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/home/index.dart';
import 'package:hoffman/features/meditations/application/meditations_providers.dart';
import 'package:hoffman/features/meditations/domain/meditation.dart';
import 'package:hoffman/features/meditations/presentation/meditations_text.dart';

/// Медитации — the tab's list (ТЗ 5.4.1), from `GET /meditations`.
///
/// Laid out like the meditations section of the home screen: the section
/// cover with the featured meditation's image, the featured meditation
/// highlighted under it ([HomeFeaturedItem]), then a [MeditationCard] per
/// other meditation. Locked meditations carry a [LockedMark] and still open
/// their detail screen, which explains the lock.
// TODO(figma): no separate list mockup; follows the home section 612:7219.
class MeditationsScreen extends ConsumerWidget {
  const MeditationsScreen({super.key});

  static const Key coverKey = ValueKey('meditations-cover');
  static const Key featuredKey = ValueKey('meditations-featured');

  static Key cardKey(int id) => ValueKey('meditations-card-$id');

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final userId = ref.read(signedInUserIdProvider);
    if (userId == null) return;
    final hadData = ref.read(currentMeditationCatalogProvider).hasValue;
    final provider = meditationCatalogProvider(userId);
    try {
      ref.invalidate(provider);
      await ref.read(provider.future);
    } on Object {
      // Without data the error state replaces the list on its own; over
      // data the stale list stays and a snackbar tells what happened.
      if (!hadData || !context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(MeditationsText.refreshFailed)),
        );
    }
  }

  void _retry(WidgetRef ref) {
    final userId = ref.read(signedInUserIdProvider);
    if (userId != null) ref.invalidate(meditationCatalogProvider(userId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(currentMeditationCatalogProvider);
    final padding = MediaQuery.paddingOf(context);

    final Widget body;
    if (catalog.value case final value?) {
      body = SliverPadding(
        padding: EdgeInsets.only(bottom: padding.bottom),
        sliver: SliverToBoxAdapter(child: _Catalog(value)),
      );
    } else if (catalog.hasError) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: padding.bottom),
          child: ErrorStateWidget(
            message: MeditationsText.errorText(
              catalog.error!,
              MeditationsText.loadFailed,
            ),
            onRetry: () => _retry(ref),
          ),
        ),
      );
    } else {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: padding.bottom),
          child: const LoadingIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => _refresh(context, ref),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // The status bar stays on white, as on the home screen.
            SliverToBoxAdapter(child: SizedBox(height: padding.top)),
            body,
          ],
        ),
      ),
    );
  }
}

/// Padding around a card after the featured meditation (612:7256).
const EdgeInsets _cardPadding = EdgeInsets.symmetric(
  horizontal: AppSpacing.md,
  vertical: AppSpacing.xl,
);

class _Catalog extends StatelessWidget {
  const _Catalog(this.catalog);

  final MeditationCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final featured = catalog.featured;
    void open(Meditation item) => context.push(AppRoutes.meditation(item.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionCover(
          image: HomeScreen.meditationsCover,
          imageUrl: featured?.coverImageUrl,
          title: HomeText.meditations,
          subtitle: HomeText.meditationsSubtitle,
          coverKey: MeditationsScreen.coverKey,
          shaded: true,
          tapLabel: featured?.title,
          onTap: featured == null ? null : () => open(featured),
          onSeeAll: null,
        ),
        if (catalog.isEmpty) const HomeSectionEmpty(),
        if (featured != null)
          HomeFeaturedItem(
            key: MeditationsScreen.featuredKey,
            title: featured.title,
            description: featured.shortDescription,
            trailing: HomeMetaLabel(
              icon: Icons.watch_later,
              text: HomeText.duration(featured.durationSeconds),
            ),
            actionLabel: MeditationsText.start,
            actionIcon: Icons.play_arrow_rounded,
            isLocked: featured.isLocked,
            onTap: () => open(featured),
          ),
        for (final (i, item) in catalog.items.indexed) ...[
          // No line above the first card when it heads the list.
          if (featured != null || i > 0) const HomeDivider(),
          Padding(
            padding: _cardPadding,
            child: MeditationCard(
              key: MeditationsScreen.cardKey(item.id),
              title: item.title,
              cover: HomeCoverImage(
                url: item.coverImageUrl,
                fallback: HomeScreen.meditationsCover,
              ),
              duration: HomeText.duration(item.durationSeconds),
              description: item.shortDescription,
              actionLabel: MeditationsText.start,
              isLocked: item.isLocked,
              onTap: () => open(item),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
