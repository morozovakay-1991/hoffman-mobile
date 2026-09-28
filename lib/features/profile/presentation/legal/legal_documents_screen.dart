import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/profile/application/legal_providers.dart';
import 'package:hoffman/features/profile/presentation/widgets/profile_widgets.dart';

/// "Правовая информация" — Figma 642:3358: every document of
/// `GET /legal-documents`, each opening 642:3400.
class LegalDocumentsScreen extends ConsumerWidget {
  const LegalDocumentsScreen({super.key});

  static const String emptyMessage = 'Документы пока не опубликованы';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(legalDocumentsProvider);

    return ProfileScaffold(
      children: [
        const ProfilePageTitle('Правовая информация'),
        switch (documents) {
          AsyncValue(value: final list?) when list.isEmpty => const Padding(
            padding: EdgeInsets.only(top: 120),
            child: EmptyStateWidget(message: emptyMessage),
          ),
          AsyncValue(value: final list?) => ProfileMenu(
            tiles: [
              for (final document in list)
                ProfileMenuTile(
                  label: document.title,
                  onTap: () => context.push(
                    AppRoutes.profileLegalDocument(document.slug),
                  ),
                ),
            ],
          ),
          AsyncValue(:final error?) => ProfileLoadError(
            error: error,
            onRetry: () => ref.invalidate(legalDocumentsProvider),
          ),
          _ => const ProfileLoading(),
        },
      ],
    );
  }
}
