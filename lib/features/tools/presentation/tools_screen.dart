import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/home/index.dart';
import 'package:hoffman/features/tools/application/tools_providers.dart';
import 'package:hoffman/features/tools/domain/tool.dart';
import 'package:hoffman/features/tools/presentation/tools_text.dart';

/// Инструменты — the tab's list (ТЗ 5.5), from `GET /tools`, Figma
/// "Tools v1" 2:869.
///
/// The section cover with the `темы` badge leading to the topics (the tab
/// holds both), the featured tool on the blue panel, then a
/// [ToolListCard] per other tool (no cover, as in the mockup).
///
/// The tools are open to every user whatever the subscription (a product
/// decision, departing from ТЗ 4.1): no card carries a lock.
class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  static const Key coverKey = ValueKey('tools-cover');
  static const Key featuredKey = ValueKey('tools-featured');
  static const Key topicsLinkKey = ValueKey('tools-topics-link');

  static Key cardKey(int id) => ValueKey('tools-card-$id');

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final userId = ref.read(signedInUserIdProvider);
    if (userId == null) return;
    final hadData = ref.read(currentToolCatalogProvider).hasValue;
    final provider = toolCatalogProvider(userId);
    try {
      ref.invalidate(provider);
      await ref.read(provider.future);
    } on Object {
      // Without data the error state replaces the list on its own; over
      // data the stale list stays and a snackbar tells what happened.
      if (!hadData || !context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(ToolsText.refreshFailed)));
    }
  }

  void _retry(WidgetRef ref) {
    final userId = ref.read(signedInUserIdProvider);
    if (userId != null) ref.invalidate(toolCatalogProvider(userId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(currentToolCatalogProvider);
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
            message: ToolsText.errorText(catalog.error!, ToolsText.loadFailed),
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
        edgeOffset: padding.top,
        onRefresh: () => _refresh(context, ref),
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
  const _Catalog(this.catalog);

  final ToolCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final featured = catalog.featured;
    void open(Tool item) => context.push(AppRoutes.tool(item.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionCover(
          underStatusBar: true,
          imageUrl: featured?.coverImageUrl,
          title: HomeText.tools,
          subtitle: HomeText.toolsSubtitle,
          coverKey: ToolsScreen.coverKey,
          seeAllKey: ToolsScreen.topicsLinkKey,
          seeAllLabel: ToolsText.topicsLink,
          foreground: AppColors.basicBlack,
          tapLabel: featured?.title,
          onTap: featured == null ? null : () => open(featured),
          // Pushed, so back returns to the tools.
          onSeeAll: () => context.push(AppRoutes.topics),
        ),
        if (catalog.isEmpty) const HomeSectionEmpty(),
        if (featured != null)
          HomeFeaturedItem(
            key: ToolsScreen.featuredKey,
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
        ContentCardList(
          children: [
            for (final item in catalog.items)
              ToolListCard(
                key: ToolsScreen.cardKey(item.id),
                title: item.title,
                description: item.shortDescription,
                tag: item.stageTag,
                actionLabel: HomeText.read,
                onTap: () => open(item),
              ),
          ],
        ),
      ],
    );
  }
}
