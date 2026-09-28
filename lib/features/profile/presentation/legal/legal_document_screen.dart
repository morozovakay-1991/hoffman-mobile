import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/services/external_url_launcher.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/profile/application/legal_providers.dart';
import 'package:hoffman/features/profile/presentation/widgets/profile_widgets.dart';

/// A legal document — Figma 642:3400: its title and the HTML body from
/// `GET /legal-documents/{slug}`, rendered with flutter_html.
class LegalDocumentScreen extends ConsumerWidget {
  const LegalDocumentScreen({required this.slug, super.key});

  final String slug;

  /// Gap between the title and the text (642:3407).
  static const double bodyTop = 36;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(legalDocumentProvider(slug));

    return ProfileScaffold(
      onBack: () => ProfileScaffold.popOrGo(context, AppRoutes.profileLegal),
      children: [
        switch (document) {
          AsyncValue(:final value?) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DocumentTitle(value.title),
              const SizedBox(height: bodyTop),
              ProfileScaffold.padded(
                LegalDocumentBody(
                  html: value.body,
                  onLinkTap: (uri) =>
                      ref.read(externalUrlLauncherProvider)(uri),
                ),
              ),
            ],
          ),
          AsyncValue(error: final ApiException error?)
              when error.failure is NotFoundFailure =>
            const Padding(
              padding: EdgeInsets.only(top: 120),
              child: EmptyStateWidget(message: ProfileText.documentNotFound),
            ),
          AsyncValue(:final error?) => ProfileLoadError(
            error: error,
            onRetry: () => ref.invalidate(legalDocumentProvider(slug)),
          ),
          _ => const ProfileLoading(),
        },
      ],
    );
  }
}

/// `H1` (642:3408): `Text/h2` at a 32px line, dark, 32px below the back bar.
class _DocumentTitle extends StatelessWidget {
  const _DocumentTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xl + AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(height: 32 / 20),
      ),
    );
  }
}

/// A legal document's HTML body in `Text/Body-13` (Golos Text 13/18), as
/// in 642:3411; lists keep flutter_html's bullets and numbers (642:3412).
class LegalDocumentBody extends StatelessWidget {
  const LegalDocumentBody({required this.html, super.key, this.onLinkTap});

  final String html;

  /// Opens an `<a href>`; relative links are ignored.
  final ValueChanged<Uri>? onLinkTap;

  /// Replaces flutter_html's 1em above and below `p`, `ul` and `ol` (set
  /// as both top/bottom and blockStart/blockEnd).
  static final Margins _blockMargins = Margins(
    top: Margin.zero(),
    blockStart: Margin.zero(),
    bottom: Margin(20),
    blockEnd: Margin(20),
  );

  static const double fontSize = 13;
  static const double lineHeight = 18 / 13;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodySmall;
    return Html(
      data: html,
      onLinkTap: (url, _, _) {
        final uri = url == null ? null : Uri.tryParse(url);
        if (uri != null && uri.hasScheme) onLinkTap?.call(uri);
      },
      style: {
        'body': Style(
          margin: Margins.zero,
          fontFamily: base?.fontFamily,
          fontSize: FontSize(fontSize),
          lineHeight: const LineHeight(lineHeight),
          color: AppColors.basicBlack,
        ),
        // Figma: 20px between blocks, list text 28px in (a 24px marker
        // column and a 4px gap).
        'p': Style(margin: _blockMargins),
        'ul': Style(
          margin: _blockMargins,
          padding: HtmlPaddings.only(inlineStart: 28),
        ),
        'ol': Style(
          margin: _blockMargins,
          padding: HtmlPaddings.only(inlineStart: 28),
        ),
        'a': Style(color: AppColors.cherryRed),
      },
    );
  }
}
