import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/services/external_url_launcher.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/home/index.dart';
import 'package:hoffman/features/meditations/index.dart';
import 'package:hoffman/features/profile/index.dart';
import 'package:hoffman/features/tools/index.dart';
import 'package:hoffman/features/topics/application/topics_providers.dart';
import 'package:hoffman/features/topics/domain/topic.dart';
import 'package:hoffman/features/topics/presentation/topics_text.dart';

/// A topic (ТЗ 5.6), from `GET /topics/{id}`, Figma "Theme" 2:1469: the
/// cover with the back chevron and the share icon over it, the title, the
/// subtitle, the full description (HTML from the admin, via flutter_html),
/// the "Возможная работа" list, then the tools and the meditations linked
/// to the topic, each opening its own screen.
///
/// Open to every user: the screen always requests and shows the topic.
class TopicDetailScreen extends ConsumerWidget {
  const TopicDetailScreen({required this.id, super.key});

  /// `null` when the route's `:id` is not a number.
  final int? id;

  static const Key contentKey = ValueKey('topic-content');
  static const Key shareKey = ValueKey('topic-share');
  static const Key possibleWorkKey = ValueKey('topic-possible-work');
  static const Key relatedToolsKey = ValueKey('topic-related-tools');
  static const Key relatedMeditationsKey = ValueKey(
    'topic-related-meditations',
  );
  static const double coverHeight = 350;

  static Key toolCardKey(int id) => ValueKey('topic-tool-$id');
  static Key meditationCardKey(int id) => ValueKey('topic-meditation-$id');

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.topics);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = this.id;
    final topic = id == null ? null : ref.watch(topicProvider(id));

    if (topic?.value case final value?) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _Content(value, onBack: () => _back(context)),
      );
    }

    final body = switch (topic) {
      null => const EmptyStateWidget(message: TopicsText.notFound),
      AsyncValue(:final error?) when isNotFound(error) =>
        const EmptyStateWidget(message: TopicsText.notFound),
      AsyncValue(:final error?) => ErrorStateWidget(
        message: TopicsText.errorText(error, TopicsText.topicLoadFailed),
        onRetry: () => ref.invalidate(topicProvider(id!)),
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
  const _Content(this.topic, {required this.onBack});

  final Topic topic;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final padding = MediaQuery.paddingOf(context);
    final fullDescription = topic.fullDescription?.trim() ?? '';
    final possibleWork = topic.possibleWork;
    void openLink(Uri uri) => ref.read(externalUrlLauncherProvider)(uri);

    return SingleChildScrollView(
      key: TopicDetailScreen.contentKey,
      padding: EdgeInsets.only(bottom: padding.bottom + AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: TopicDetailScreen.coverHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                HomeCoverImage(
                  url: topic.coverImageUrl,
                  fallback: HomeScreen.topicsCover,
                ),
                Positioned(
                  top: padding.top,
                  left: 0,
                  right: 0,
                  child: MeditationTopBar(
                    onBack: onBack,
                    color: AppColors.background,
                    trailing: ShareButton(
                      key: TopicDetailScreen.shareKey,
                      text: shareTextOf(topic.title, topic.subtitle),
                      subject: topic.title,
                      color: AppColors.background,
                    ),
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
                  child: Text(topic.title, style: textTheme.headlineLarge),
                ),
                // TODO(figma): "Theme" 2:1469 has no subtitle; styled like
                // the one of the featured topic on the list.
                if (topic.subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    bindShortWords(topic.subtitle),
                    style: textTheme.bodyMedium,
                  ),
                ],
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
                onLinkTap: openLink,
              ),
            ),
          ],
          if (possibleWork != null)
            Padding(
              key: TopicDetailScreen.possibleWorkKey,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.md,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Heading(TopicsText.possibleWork),
                  const SizedBox(height: AppSpacing.lg),
                  LegalDocumentBody(html: possibleWork, onLinkTap: openLink),
                ],
              ),
            ),
          _Related(topic),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}

/// The tools and the meditations of the topic, as on their tabs.
class _Related extends ConsumerWidget {
  const _Related(this.topic);

  final Topic topic;

  void _retry(WidgetRef ref) {
    final userId = ref.read(signedInUserIdProvider);
    if (userId == null) return;
    ref
      ..invalidate(toolCatalogProvider(userId))
      ..invalidate(meditationCatalogProvider(userId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (topic.toolIds.isEmpty && topic.meditationIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final related = ref.watch(topicRelatedProvider(topic.id));
    if (related.value case final value?) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (value.tools.isNotEmpty)
            _RelatedTools(value.tools, key: TopicDetailScreen.relatedToolsKey),
          if (value.meditations.isNotEmpty)
            _RelatedMeditations(
              value.meditations,
              key: TopicDetailScreen.relatedMeditationsKey,
            ),
        ],
      );
    }
    if (related.hasError) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl),
        child: ErrorStateWidget(
          message: TopicsText.errorText(
            related.error!,
            TopicsText.relatedLoadFailed,
          ),
          onRetry: () => _retry(ref),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.only(top: AppSpacing.xl),
      child: LoadingIndicator(),
    );
  }
}

class _RelatedTools extends StatelessWidget {
  const _RelatedTools(this.tools, {super.key});

  final List<Tool> tools;

  @override
  Widget build(BuildContext context) {
    return _RelatedBlock(
      heading: TopicsText.relatedTools,
      children: [
        for (final tool in tools)
          ToolListCard(
            key: TopicDetailScreen.toolCardKey(tool.id),
            title: tool.title,
            description: tool.shortDescription,
            tag: tool.stageTag,
            actionLabel: HomeText.read,
            onTap: () => context.push(AppRoutes.tool(tool.id)),
          ),
      ],
    );
  }
}

class _RelatedMeditations extends StatelessWidget {
  const _RelatedMeditations(this.meditations, {super.key});

  final List<Meditation> meditations;

  @override
  Widget build(BuildContext context) {
    return _RelatedBlock(
      heading: TopicsText.relatedMeditations,
      children: [
        for (final meditation in meditations)
          MeditationCard(
            key: TopicDetailScreen.meditationCardKey(meditation.id),
            title: meditation.title,
            cover: HomeCoverImage(
              url: meditation.coverImageUrl,
              fallback: HomeScreen.meditationsCover,
            ),
            duration: HomeText.duration(meditation.durationSeconds),
            description: meditation.shortDescription,
            actionLabel: MeditationsText.start,
            isLocked: meditation.isLocked,
            onTap: () => context.push(AppRoutes.meditation(meditation.id)),
          ),
      ],
    );
  }
}

/// A [_Heading] over a [ContentCardList] of related content: dividers only
/// between the cards, edge to edge. The next block (or the end of the
/// screen) brings its own space below.
class _RelatedBlock extends StatelessWidget {
  const _RelatedBlock({required this.heading, required this.children});

  final String heading;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppGrid.margin),
            child: _Heading(heading),
          ),
          ContentCardList(top: AppSpacing.lg, bottom: 0, children: children),
        ],
      ),
    );
  }
}
