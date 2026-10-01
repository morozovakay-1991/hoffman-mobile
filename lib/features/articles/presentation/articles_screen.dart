import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/articles/application/articles_providers.dart';
import 'package:hoffman/features/articles/domain/article.dart';
import 'package:hoffman/features/articles/presentation/articles_text.dart';
import 'package:hoffman/features/home/index.dart';

/// Статьи — the tab's list (ТЗ 5.7), from `GET /articles`, Figma
/// "Articles" 422:5378.
///
/// Laid out like the articles section of the home screen: the section
/// cover with the featured article's image, the featured article
/// highlighted under it ([HomeFeaturedItem]), then an [ArticleListCard] per
/// other article, with the `новое` badge for the ones marked new. Articles
/// are never locked.
class ArticlesScreen extends ConsumerWidget {
  const ArticlesScreen({super.key});

  static const Key coverKey = ValueKey('articles-cover');
  static const Key featuredKey = ValueKey('articles-featured');

  static Key cardKey(int id) => ValueKey('articles-card-$id');

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final hadData = ref.read(articleCatalogProvider).hasValue;
    try {
      ref.invalidate(articleCatalogProvider);
      await ref.read(articleCatalogProvider.future);
    } on Object {
      // Without data the error state replaces the list on its own; over
      // data the stale list stays and a snackbar tells what happened.
      if (!hadData || !context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(ArticlesText.refreshFailed)),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(articleCatalogProvider);
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
            message: ArticlesText.errorText(
              catalog.error!,
              ArticlesText.loadFailed,
            ),
            onRetry: () => ref.invalidate(articleCatalogProvider),
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

  final ArticleCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final featured = catalog.featured;
    void open(Article item) => context.push(AppRoutes.article(item.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionCover(
          underStatusBar: true,
          image: HomeScreen.articlesCover,
          imageUrl: featured?.coverImageUrl,
          title: HomeText.articles,
          subtitle: HomeText.articlesSubtitle,
          coverKey: ArticlesScreen.coverKey,
          tapLabel: featured?.title,
          onTap: featured == null ? null : () => open(featured),
          onSeeAll: null,
        ),
        if (catalog.isEmpty) const HomeSectionEmpty(),
        if (featured != null)
          HomeFeaturedItem(
            key: ArticlesScreen.featuredKey,
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
            onTap: () => open(featured),
          ),
        ContentCardList(
          children: [
            for (final item in catalog.items)
              ArticleListCard(
                key: ArticlesScreen.cardKey(item.id),
                title: item.title,
                cover: HomeCoverImage(
                  url: item.coverImageUrl,
                  fallback: HomeScreen.articlesCover,
                ),
                date: HomeText.monthYear(item.publishedAt),
                description: item.shortDescription,
                actionLabel: HomeText.read,
                badge: HomeText.articleBadge(isNew: item.isNew),
                onTap: () => open(item),
              ),
          ],
        ),
      ],
    );
  }
}
