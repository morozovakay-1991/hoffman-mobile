import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/services/external_url_launcher.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/articles/application/articles_providers.dart';
import 'package:hoffman/features/articles/domain/article.dart';
import 'package:hoffman/features/articles/presentation/articles_text.dart';
import 'package:hoffman/features/home/index.dart';
import 'package:hoffman/features/meditations/index.dart';
import 'package:hoffman/features/profile/index.dart';

/// An article (ТЗ 5.7), from `GET /articles/{id}`, Figma "Article"
/// 414:2903: the cover with the back chevron and the share icon over it
/// (the share sheet gets the title and the short description — there is
/// no public web page of an article), a tinted panel with
/// the title, the short description and the publication date, then the
/// full description (HTML from the admin, via flutter_html).
class ArticleDetailScreen extends ConsumerWidget {
  const ArticleDetailScreen({required this.id, super.key});

  /// `null` when the route's `:id` is not a number.
  final int? id;

  static const Key contentKey = ValueKey('article-content');
  static const Key shareKey = ValueKey('article-share');
  static const double coverHeight = 350;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.articles);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = this.id;
    final article = id == null ? null : ref.watch(articleProvider(id));

    if (article?.value case final value?) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _Content(value, onBack: () => _back(context)),
      );
    }

    final body = switch (article) {
      null => const EmptyStateWidget(message: ArticlesText.notFound),
      AsyncValue(:final error?) when isNotFound(error) =>
        const EmptyStateWidget(message: ArticlesText.notFound),
      AsyncValue(:final error?) => ErrorStateWidget(
        message: ArticlesText.errorText(error, ArticlesText.articleLoadFailed),
        onRetry: () => ref.invalidate(articleProvider(id!)),
      ),
      _ => const LoadingIndicator(),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MeditationTopBar(onBack: () => _back(context)),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom,
                ),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content(this.article, {required this.onBack});

  final Article article;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final padding = MediaQuery.paddingOf(context);
    final fullDescription = article.fullDescription?.trim() ?? '';
    final publishedAt = article.publishedAt;

    return SingleChildScrollView(
      key: ArticleDetailScreen.contentKey,
      padding: EdgeInsets.only(bottom: padding.bottom + AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: ArticleDetailScreen.coverHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                HomeCoverImage(
                  url: article.coverImageUrl,
                  fallback: HomeScreen.articlesCover,
                ),
                Positioned(
                  top: padding.top,
                  left: 0,
                  right: 0,
                  child: MeditationTopBar(
                    onBack: onBack,
                    color: AppColors.background,
                    trailing: ShareButton(
                      key: ArticleDetailScreen.shareKey,
                      text: shareTextOf(
                        article.title,
                        article.shortDescription,
                      ),
                      subject: article.title,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ColoredBox(
            color: AppColors.lightBlueTint,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(article.title, style: textTheme.titleLarge),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          bindShortWords(article.shortDescription),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.softBlack,
                          ),
                        ),
                      ),
                      if (publishedAt != null) ...[
                        const SizedBox(width: AppSpacing.md),
                        HomeMetaLabel(
                          icon: Icons.calendar_month,
                          text: HomeText.monthYear(publishedAt),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
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
