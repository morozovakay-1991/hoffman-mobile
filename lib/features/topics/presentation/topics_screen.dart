import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/home/index.dart';
import 'package:hoffman/features/topics/application/topics_providers.dart';
import 'package:hoffman/features/topics/domain/topic.dart';
import 'package:hoffman/features/topics/presentation/topics_text.dart';

/// Темы (ТЗ 5.6), from `GET /topics`, Figma "Themes v1" 2:761. Part of the
/// `Инструменты` tab, which holds both lists.
///
/// The section cover with the `инструменты` badge back to the tools, the
/// featured topic on the grey panel, then an accordion of
/// [ThemeListCard]s: a tap unfolds a topic (one at a time) to its cover
/// thumbnail and short description, whose `Читать` opens the topic.
///
/// The topics are open to every user whatever the subscription (a product
/// decision, departing from ТЗ 4.1): no card carries a lock.
class TopicsScreen extends ConsumerStatefulWidget {
  const TopicsScreen({super.key});

  static const Key coverKey = ValueKey('topics-cover');
  static const Key featuredKey = ValueKey('topics-featured');
  static const Key toolsLinkKey = ValueKey('topics-tools-link');

  static Key cardKey(int id) => ValueKey('topics-card-$id');

  /// Panel under the featured topic ("Themes v1", as on home 612:7552):
  /// 10% black, off the token scale.
  static const Color featuredColor = Color(0x1A000000);

  @override
  ConsumerState<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends ConsumerState<TopicsScreen> {
  /// The unfolded [ThemeListCard], one at a time.
  int? _expandedId;

  Future<void> _refresh() async {
    final userId = ref.read(signedInUserIdProvider);
    if (userId == null) return;
    final hadData = ref.read(currentTopicCatalogProvider).hasValue;
    final provider = topicCatalogProvider(userId);
    try {
      ref.invalidate(provider);
      await ref.read(provider.future);
    } on Object {
      // Without data the error state replaces the list on its own; over
      // data the stale list stays and a snackbar tells what happened.
      if (!hadData || !mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(TopicsText.refreshFailed)));
    }
  }

  void _retry() {
    final userId = ref.read(signedInUserIdProvider);
    if (userId != null) ref.invalidate(topicCatalogProvider(userId));
  }

  void _toggle(int id) =>
      setState(() => _expandedId = _expandedId == id ? null : id);

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(currentTopicCatalogProvider);
    final padding = MediaQuery.paddingOf(context);

    final Widget body;
    if (catalog.value case final value?) {
      body = SliverPadding(
        padding: EdgeInsets.only(bottom: padding.bottom),
        sliver: SliverToBoxAdapter(
          child: _Catalog(value, expandedId: _expandedId, onToggle: _toggle),
        ),
      );
    } else if (catalog.hasError) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: padding.bottom),
          child: ErrorStateWidget(
            message: TopicsText.errorText(
              catalog.error!,
              TopicsText.loadFailed,
            ),
            onRetry: _retry,
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
        edgeOffset: padding.top,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // With data the section cover runs up under the status bar;
            // the loading and error states stay below it.
            if (!catalog.hasValue)
              SliverToBoxAdapter(child: SizedBox(height: padding.top)),
            body,
          ],
        ),
      ),
    );
  }
}

class _Catalog extends StatelessWidget {
  const _Catalog(
    this.catalog, {
    required this.expandedId,
    required this.onToggle,
  });

  final TopicCatalog catalog;
  final int? expandedId;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final featured = catalog.featured;
    void open(Topic item) => context.push(AppRoutes.topic(item.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionCover(
          underStatusBar: true,
          imageUrl: featured?.coverImageUrl,
          title: HomeText.topics,
          subtitle: HomeText.topicsSubtitle,
          coverKey: TopicsScreen.coverKey,
          seeAllKey: TopicsScreen.toolsLinkKey,
          seeAllLabel: TopicsText.toolsLink,
          tapLabel: featured?.title,
          onTap: featured == null ? null : () => open(featured),
          // The tab's own list: switched to, not stacked on the topics.
          onSeeAll: () => context.go(AppRoutes.tools),
        ),
        if (catalog.isEmpty) const HomeSectionEmpty(),
        if (featured != null)
          HomeFeaturedItem(
            key: TopicsScreen.featuredKey,
            title: featured.title,
            subtitle: featured.subtitle,
            description: featured.summary,
            actionLabel: HomeText.read,
            color: TopicsScreen.featuredColor,
            onTap: () => open(featured),
          ),
        ContentCardList(
          children: [
            for (final item in catalog.items)
              ThemeListCard(
                key: TopicsScreen.cardKey(item.id),
                title: item.title,
                subtitle: item.subtitle,
                cover: HomeCoverImage(
                  url: item.coverImageUrl,
                  fallback: HomeScreen.topicsCover,
                ),
                body: item.summary,
                actionLabel: HomeText.read,
                isExpanded: expandedId == item.id,
                onTap: () => onToggle(item.id),
                onActionTap: () => open(item),
              ),
          ],
        ),
      ],
    );
  }
}
