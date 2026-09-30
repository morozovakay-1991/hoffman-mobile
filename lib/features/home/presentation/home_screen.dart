import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/home/application/home_providers.dart';
import 'package:hoffman/features/home/domain/home_summary.dart';
import 'package:hoffman/features/home/presentation/home_text.dart';
import 'package:hoffman/features/home/presentation/widgets/home_widgets.dart';

/// Главная — Figma 612:7209 (`Index graduate`), ТЗ 5.3.
///
/// The header greets the user by name; below it, from top to bottom:
/// meditations, tools, topics, the 100-day diary and articles. Each section
/// opens with a promo cover whose `все` badge leads to the full list, then
/// highlights its featured item (chosen in the admin; the cover shows and
/// opens it too) and lists the rest with the `core/widgets` content cards. Everything comes from a single `GET /home`.
///
/// The diary block trusts the backend's `is_available` alone: the progress
/// and "Продолжить" are shown only to users the backend lets in.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const Key menuKey = ValueKey('home-menu');
  static const Key diaryContinueKey = ValueKey('home-diary-continue');
  static const Key diaryVerifyKey = ValueKey('home-diary-verify');
  static const Key diaryLockedKey = ValueKey('home-diary-locked');

  static Key seeAllKey(String route) => ValueKey('home-see-all-$route');

  /// The cover of a section with a featured item, which opens that item.
  static Key coverKey(String route) => ValueKey('home-cover-$route');

  static const String meditationsCover =
      'assets/images/home/meditations_cover.png';
  static const String toolsCover = 'assets/images/home/tools_cover.png';
  static const String topicsCover = 'assets/images/home/themes_cover.png';
  static const String diaryCover = 'assets/images/home/diary_cover.png';
  static const String articlesCover = 'assets/images/home/articles_cover.png';

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final userId = ref.read(signedInUserIdProvider);
    if (userId == null) return;
    final hadData = ref.read(currentHomeSummaryProvider).hasValue;
    final provider = homeSummaryProvider(userId);
    try {
      ref.invalidate(provider);
      await ref.read(provider.future);
    } on Object {
      // Without data the error state replaces the feed on its own; over
      // data the stale feed stays and a snackbar tells what happened.
      if (!hadData || !context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(HomeText.refreshFailed)));
    }
  }

  void _retry(WidgetRef ref) {
    final userId = ref.read(signedInUserIdProvider);
    if (userId != null) ref.invalidate(homeSummaryProvider(userId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(currentHomeSummaryProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final Widget body;
    if (home.value case final summary?) {
      body = SliverPadding(
        padding: EdgeInsets.only(bottom: bottomInset),
        sliver: SliverToBoxAdapter(child: _Feed(summary)),
      );
    } else if (home.hasError) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: ErrorStateWidget(
            message: HomeText.loadError(home.error!),
            onRetry: () => _retry(ref),
          ),
        ),
      );
    } else {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
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
            const SliverToBoxAdapter(child: _Header()),
            body,
          ],
        ),
      ),
    );
  }
}

/// `hoffman` logo with the menu (→ profile) and the greeting (1086:3970).
class _Header extends ConsumerWidget {
  const _Header();

  /// Logo (612:7858): 45px, -4% tracking.
  static const double _logoTracking = -1.8;

  /// Greeting line height (612:7854).
  static const double _greetingLineHeight = 20 / 14;

  /// Gap between the greeting and the first section (192 - 128).
  static const double _bottomGap = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final name = switch (ref.watch(authControllerProvider).value) {
      Authenticated(:final user) => user.name,
      _ => '',
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        MediaQuery.paddingOf(context).top + AppSpacing.sm,
        AppSpacing.md,
        _bottomGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'hoffman',
                    style: textTheme.displayMedium?.copyWith(
                      letterSpacing: _logoTracking,
                    ),
                  ),
                ),
              ),
              _MenuButton(onTap: () => context.push(AppRoutes.profile)),
            ],
          ),
          Text(
            HomeText.greetingFor(name),
            style: textTheme.bodyMedium?.copyWith(height: _greetingLineHeight),
          ),
        ],
      ),
    );
  }
}

/// Three 38×3 bars (1081:2347) opening the profile.
class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onTap});

  static const double _tapTarget = 48;
  static const double _barWidth = 38;
  static const double _barHeight = 3;
  static const double _barGap = 8;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const bar = SizedBox(
      width: _barWidth,
      height: _barHeight,
      child: ColoredBox(color: AppColors.basicBlack),
    );

    return Semantics(
      button: true,
      label: HomeText.profile,
      excludeSemantics: true,
      child: GestureDetector(
        key: HomeScreen.menuKey,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const SizedBox(
          width: _tapTarget,
          height: _tapTarget,
          child: Align(
            alignment: Alignment.centerRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                bar,
                SizedBox(height: _barGap),
                bar,
                SizedBox(height: _barGap),
                bar,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Feed extends StatelessWidget {
  const _Feed(this.summary);

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MeditationsSection(summary.meditations),
        _ToolsSection(summary.tools),
        _TopicsSection(summary.topics),
        _DiarySection(summary.diary),
        _ArticlesSection(summary.articles),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// Padding around a list card after the featured item (612:7256).
const EdgeInsets _cardPadding = EdgeInsets.symmetric(
  horizontal: AppSpacing.md,
  vertical: AppSpacing.xl,
);

/// Horizontal padding of the list cards that draw their own divider.
const EdgeInsets _listCardPadding = EdgeInsets.symmetric(
  horizontal: AppSpacing.md,
);

class _MeditationsSection extends StatelessWidget {
  const _MeditationsSection(this.section);

  final HomeSection<HomeMeditation> section;

  @override
  Widget build(BuildContext context) {
    final featured = section.featured;
    void open(HomeMeditation item) =>
        context.push(AppRoutes.meditation(item.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionCover(
          image: HomeScreen.meditationsCover,
          imageUrl: featured?.coverImageUrl,
          title: HomeText.meditations,
          subtitle: HomeText.meditationsSubtitle,
          coverKey: HomeScreen.coverKey(AppRoutes.meditations),
          seeAllKey: HomeScreen.seeAllKey(AppRoutes.meditations),
          shaded: true,
          tapLabel: featured?.title,
          onTap: featured == null ? null : () => open(featured),
          onSeeAll: () => context.go(AppRoutes.meditations),
        ),
        if (section.isEmpty) const HomeSectionEmpty(),
        if (featured != null)
          HomeFeaturedItem(
            title: featured.title,
            description: featured.shortDescription,
            trailing: HomeMetaLabel(
              icon: Icons.watch_later,
              text: HomeText.duration(featured.durationSeconds),
            ),
            actionLabel: HomeText.start,
            actionIcon: Icons.play_arrow_rounded,
            isLocked: featured.isLocked,
            onTap: () => open(featured),
          ),
        for (final (i, item) in section.items.indexed) ...[
          // No line above the first card when it heads the section.
          if (featured != null || i > 0) const HomeDivider(),
          Padding(
            padding: _cardPadding,
            child: MeditationCard(
              title: item.title,
              cover: HomeCoverImage(
                url: item.coverImageUrl,
                fallback: HomeScreen.meditationsCover,
              ),
              duration: HomeText.duration(item.durationSeconds),
              description: item.shortDescription,
              actionLabel: HomeText.start,
              isLocked: item.isLocked,
              onTap: () => open(item),
            ),
          ),
        ],
      ],
    );
  }
}

class _ToolsSection extends StatelessWidget {
  const _ToolsSection(this.section);

  final HomeSection<HomeTool> section;

  @override
  Widget build(BuildContext context) {
    final featured = section.featured;
    void open(HomeTool item) => context.push(AppRoutes.tool(item.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionCover(
          image: HomeScreen.toolsCover,
          imageUrl: featured?.coverImageUrl,
          title: HomeText.tools,
          subtitle: HomeText.toolsSubtitle,
          coverKey: HomeScreen.coverKey(AppRoutes.tools),
          seeAllKey: HomeScreen.seeAllKey(AppRoutes.tools),
          foreground: AppColors.basicBlack,
          tapLabel: featured?.title,
          onTap: featured == null ? null : () => open(featured),
          onSeeAll: () => context.go(AppRoutes.tools),
        ),
        if (section.isEmpty) const HomeSectionEmpty(),
        if (featured != null)
          HomeFeaturedItem(
            title: featured.title,
            description: featured.shortDescription,
            trailing: featured.stageTag == null
                ? null
                : AppBadge(
                    label: featured.stageTag!,
                    variant: AppBadgeVariant.tinted,
                  ),
            actionLabel: HomeText.read,
            color: AppColors.blueTint,
            actionVariant: AppButtonVariant.secondary,
            onTap: () => open(featured),
          ),
        for (final item in section.items)
          Padding(
            padding: _listCardPadding,
            child: ToolListCard(
              title: item.title,
              description: item.shortDescription,
              tag: item.stageTag,
              actionLabel: HomeText.read,
              onTap: () => open(item),
            ),
          ),
      ],
    );
  }
}

class _TopicsSection extends StatefulWidget {
  const _TopicsSection(this.section);

  /// Panel under the featured topic (612:7552): 10% black, off the token
  /// scale.
  static const Color featuredColor = Color(0x1A000000);

  final HomeSection<HomeTopic> section;

  @override
  State<_TopicsSection> createState() => _TopicsSectionState();
}

class _TopicsSectionState extends State<_TopicsSection> {
  /// The unfolded [ThemeListCard], one at a time.
  int? _expandedId;

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final featured = section.featured;
    void open(HomeTopic item) => context.push(AppRoutes.topic(item.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionCover(
          image: HomeScreen.topicsCover,
          imageUrl: featured?.coverImageUrl,
          title: HomeText.topics,
          subtitle: HomeText.topicsSubtitle,
          coverKey: HomeScreen.coverKey(AppRoutes.topics),
          seeAllKey: HomeScreen.seeAllKey(AppRoutes.topics),
          tapLabel: featured?.title,
          onTap: featured == null ? null : () => open(featured),
          // Topics is not a tab: pushed, so back returns home.
          onSeeAll: () => context.push(AppRoutes.topics),
        ),
        if (section.isEmpty) const HomeSectionEmpty(),
        if (featured != null)
          HomeFeaturedItem(
            title: featured.title,
            subtitle: featured.subtitle,
            description: featured.fullDescription ?? '',
            actionLabel: HomeText.read,
            color: _TopicsSection.featuredColor,
            onTap: () => open(featured),
          ),
        for (final item in section.items)
          Padding(
            padding: _listCardPadding,
            child: ThemeListCard(
              title: item.title,
              subtitle: item.subtitle,
              cover: HomeCoverImage(
                url: item.coverImageUrl,
                fallback: HomeScreen.topicsCover,
              ),
              body: item.fullDescription ?? '',
              actionLabel: HomeText.read,
              isExpanded: _expandedId == item.id,
              onTap: () => setState(
                () => _expandedId = _expandedId == item.id ? null : item.id,
              ),
              onActionTap: () => open(item),
            ),
          ),
      ],
    );
  }
}

class _DiarySection extends ConsumerWidget {
  const _DiarySection(this.progress);

  final DiaryProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDay = progress.currentDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionCover(
          image: HomeScreen.diaryCover,
          title: HomeText.diary,
          subtitle: HomeText.diarySubtitle,
          seeAllKey: HomeScreen.seeAllKey(AppRoutes.diary),
          onSeeAll: () => context.go(AppRoutes.diary),
        ),
        Padding(
          padding: _cardPadding,
          child: progress.isAvailable && currentDay != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DiaryProgressBar(
                      day: currentDay,
                      totalDays: progress.totalDays,
                      value: progress.progress,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // TODO(figma): 612:7393 also shows the day's task, which
                    // GET /home does not return yet.
                    SizedBox(
                      width: AppButton.minWidth,
                      height: HomeFeaturedItem.buttonHeight,
                      child: AppButton(
                        key: HomeScreen.diaryContinueKey,
                        label: HomeText.continueDiary,
                        variant: AppButtonVariant.secondary,
                        trailingIcon: Icons.arrow_forward_rounded,
                        onPressed: () => context.go(AppRoutes.diary),
                      ),
                    ),
                  ],
                )
              : const _DiaryLocked(),
        ),
      ],
    );
  }
}

/// The diary block for a user the backend keeps out: graduate status not
/// confirmed → verification; confirmed → access has to be restored. Waits
/// for the status before offering verification, so a confirmed graduate
/// never sees that prompt flash.
// TODO(figma): no locked diary block in the mockups; styled after
// LockedOverlay.
class _DiaryLocked extends ConsumerWidget {
  const _DiaryLocked();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final verification = ref.watch(currentVerificationProvider);
    final needsVerification =
        verification.hasValue && !(verification.value?.isConfirmed ?? false);

    return Column(
      key: HomeScreen.diaryLockedKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                needsVerification
                    ? LockedOverlayText.graduateOnlyTitle
                    : LockedOverlayText.restrictedTitle,
                style: textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const LockedMark(),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (needsVerification)
          SizedBox(
            height: HomeFeaturedItem.buttonHeight,
            child: AppButton(
              key: HomeScreen.diaryVerifyKey,
              label: LockedOverlayText.verify,
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: () => context.push(AppRoutes.verification),
            ),
          )
        else
          Text(
            LockedOverlayText.restoreAccessDescription,
            style: textTheme.bodySmall?.copyWith(color: AppColors.softBlack),
          ),
      ],
    );
  }
}

class _ArticlesSection extends StatelessWidget {
  const _ArticlesSection(this.section);

  final HomeSection<HomeArticle> section;

  @override
  Widget build(BuildContext context) {
    final featured = section.featured;
    void open(HomeArticle item) => context.push(AppRoutes.article(item.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionCover(
          image: HomeScreen.articlesCover,
          imageUrl: featured?.coverImageUrl,
          title: HomeText.articles,
          subtitle: HomeText.articlesSubtitle,
          coverKey: HomeScreen.coverKey(AppRoutes.articles),
          seeAllKey: HomeScreen.seeAllKey(AppRoutes.articles),
          tapLabel: featured?.title,
          onTap: featured == null ? null : () => open(featured),
          onSeeAll: () => context.go(AppRoutes.articles),
        ),
        if (section.isEmpty) const HomeSectionEmpty(),
        if (featured != null)
          HomeFeaturedItem(
            title: featured.title,
            description: featured.shortDescription,
            trailing: featured.publishedAt == null
                ? null
                : HomeMetaLabel(
                    icon: Icons.calendar_month,
                    text: HomeText.monthYear(featured.publishedAt),
                  ),
            actionLabel: HomeText.read,
            color: AppColors.lightBlueTint,
            isLocked: featured.isLocked,
            onTap: () => open(featured),
          ),
        for (final item in section.items)
          Padding(
            padding: _listCardPadding,
            child: ArticleListCard(
              title: item.title,
              cover: HomeCoverImage(
                url: item.coverImageUrl,
                fallback: HomeScreen.articlesCover,
              ),
              date: HomeText.monthYear(item.publishedAt),
              description: item.shortDescription,
              actionLabel: HomeText.read,
              badge: HomeText.articleBadge(isNew: item.isNew),
              isLocked: item.isLocked,
              onTap: () => open(item),
            ),
          ),
      ],
    );
  }
}
