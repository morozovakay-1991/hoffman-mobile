import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/profile/data/profile_repository.dart';
import 'package:hoffman/features/profile/domain/legal_document.dart';
import 'package:hoffman/features/profile/presentation/widgets/profile_widgets.dart';

/// "Удаление аккаунта" — Figma 755:3939.
///
/// - "Запросить удаление данных": `POST /profile/deletion-request`; the
///   backend deletes the data after its 30-day grace period and the user
///   stays signed in meanwhile.
/// - "Удалить аккаунт": the 1000:2891 sheet, then `DELETE /profile`; on
///   success "Ваш аккаунт удален" (753:3884) replaces the stack and the
///   session ends (the backend has already revoked the token).
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  static const Key requestDeletionKey = ValueKey('profile-request-deletion');
  static const Key deleteAccountKey = ValueKey('profile-delete-account');
  static const Key privacyPolicyKey = ValueKey('profile-privacy-policy');

  static const String confirmMessage = 'Данные будут удалены безвозвратно';

  static const double buttonWidth = 232;

  /// Figma subtitle width (755:3948).
  static const double subtitleWidth = 270;

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool _requesting = false;
  bool _deleting = false;

  bool get _busy => _requesting || _deleting;

  Future<void> _requestDeletion() async {
    if (_busy) return;
    setState(() => _requesting = true);
    try {
      await ref.read(profileRepositoryProvider).requestDeletion();
      if (mounted) showAuthSnackBar(context, ProfileText.deletionRequested);
    } on ApiException catch (e) {
      if (!mounted) return;
      showAuthSnackBar(
        context,
        e.code == 'DELETION_ALREADY_REQUESTED'
            ? ProfileText.deletionAlreadyRequested
            : ProfileText.of(e),
      );
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Future<void> _deleteAccount() async {
    if (_busy) return;
    final confirmed = await showConfirmSheet(
      context,
      message: DeleteAccountScreen.confirmMessage,
      confirmLabel: 'Удалить аккаунт',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    // Captured while mounted: this screen may be gone by the time the
    // request completes (e.g. a deep link), and `ref`/`context` are unusable
    // then, but the account is deleted all the same.
    final auth = ref.read(authControllerProvider.notifier);
    final router = GoRouter.of(context);
    try {
      await ref.read(profileRepositoryProvider).deleteAccount();
    } on ApiException catch (e) {
      if (mounted) {
        showAuthSnackBar(context, ProfileText.of(e));
        setState(() => _deleting = false);
      }
      return;
    }
    // The result screen goes first: it stays reachable once signed out,
    // while this one would be redirected to /login.
    router.go(AppRoutes.accountDeleted);
    await auth.accountDeleted();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // No leaving while DELETE /profile is in flight: its outcome decides
    // where the user lands (back bar, system back and the iOS swipe).
    return PopScope(
      canPop: !_deleting,
      child: ProfileScaffold(
        onBack: () {
          if (_deleting) return;
          ProfileScaffold.popOrGo(context, AppRoutes.profilePersonalData);
        },
        children: [
          ProfileScaffold.padded(
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xl + AppSpacing.xs,
                bottom: AppSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Удаление аккаунта',
                    style: textTheme.titleLarge?.copyWith(height: 32 / 20),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: DeleteAccountScreen.subtitleWidth,
                    ),
                    child: Text(
                      'Мы удалим ваш аккаунт и связанные данные. Некоторые '
                      'данные могут храниться дольше по закону. Процесс может '
                      'занять до 30 дней.',
                      // Figma: Golos Text Medium 13/18.
                      style: textTheme.labelMedium?.copyWith(
                        fontSize: 13,
                        height: 18 / 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 60),
          ProfileScaffold.padded(
            AuthSubmitButton(
              key: DeleteAccountScreen.requestDeletionKey,
              label: 'Запросить удаление данных',
              width: DeleteAccountScreen.buttonWidth,
              loading: _busy,
              onPressed: _requestDeletion,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ProfileScaffold.padded(
            AuthSubmitButton(
              key: DeleteAccountScreen.deleteAccountKey,
              label: 'Удалить аккаунт',
              width: DeleteAccountScreen.buttonWidth,
              variant: AppButtonVariant.secondary,
              loading: _busy,
              onPressed: _deleteAccount,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ProfileScaffold.padded(
            Align(
              alignment: Alignment.centerLeft,
              child: AuthLink(
                key: DeleteAccountScreen.privacyPolicyKey,
                label: 'Политика конфиденциальности',
                onTap: () => context.push(
                  AppRoutes.profileLegalDocument(
                    LegalDocumentSummary.privacySlug,
                  ),
                ),
                style: AuthLink.linkStyle(context).copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.cherryRed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
