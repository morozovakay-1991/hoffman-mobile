import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/services/external_url_launcher.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/home/index.dart';
import 'package:hoffman/features/meditations/index.dart';
import 'package:hoffman/features/profile/index.dart';
import 'package:hoffman/features/tools/application/tools_providers.dart';
import 'package:hoffman/features/tools/domain/tool.dart';
import 'package:hoffman/features/tools/presentation/tools_text.dart';

/// A tool (ТЗ 5.5), from `GET /tools/{id}`, Figma "Tool" 2:1548: the cover
/// with the back chevron and the share icon over it, the blue panel with
/// the title, the short description and the stage badge, then the full
/// description (HTML from the admin, via flutter_html).
///
/// Open to every user: the screen always requests and shows the tool.
class ToolDetailScreen extends ConsumerWidget {
  const ToolDetailScreen({required this.id, super.key});

  /// `null` when the route's `:id` is not a number.
  final int? id;

  static const Key contentKey = ValueKey('tool-content');
  static const Key shareKey = ValueKey('tool-share');
  static const double coverHeight = 350;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.tools);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = this.id;
    final tool = id == null ? null : ref.watch(toolProvider(id));

    if (tool?.value case final value?) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _Content(value, onBack: () => _back(context)),
      );
    }

    final body = switch (tool) {
      null => const EmptyStateWidget(message: ToolsText.notFound),
      AsyncValue(:final error?) when isNotFound(error) =>
        const EmptyStateWidget(message: ToolsText.notFound),
      AsyncValue(:final error?) => ErrorStateWidget(
        message: ToolsText.errorText(error, ToolsText.toolLoadFailed),
        onRetry: () => ref.invalidate(toolProvider(id!)),
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
  const _Content(this.tool, {required this.onBack});

  final Tool tool;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final padding = MediaQuery.paddingOf(context);
    final fullDescription = tool.fullDescription?.trim() ?? '';
    final stageTag = tool.stageTag;

    return SingleChildScrollView(
      key: ToolDetailScreen.contentKey,
      padding: EdgeInsets.only(bottom: padding.bottom + AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: ToolDetailScreen.coverHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                HomeCoverImage(
                  url: tool.coverImageUrl,
                  fallback: HomeScreen.toolsCover,
                ),
                Positioned(
                  top: padding.top,
                  left: 0,
                  right: 0,
                  child: MeditationTopBar(
                    onBack: onBack,
                    trailing: ShareButton(
                      key: ToolDetailScreen.shareKey,
                      text: shareTextOf(tool.title, tool.shortDescription),
                      subject: tool.title,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ColoredBox(
            color: AppColors.blueTint,
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
                    child: Text(tool.title, style: textTheme.headlineLarge),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          tool.shortDescription,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.softBlack,
                          ),
                        ),
                      ),
                      if (stageTag != null) ...[
                        const SizedBox(width: AppSpacing.md),
                        AppBadge(
                          label: stageTag,
                          variant: AppBadgeVariant.tinted,
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
