import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/profile/application/profile_controller.dart';
import 'package:hoffman/features/profile/presentation/widgets/profile_widgets.dart';

/// "Личный кабинет" — Figma 651:3334 (graduate status not confirmed) and
/// 651:3729 (confirmed).
///
/// The graduate block reads `currentVerificationProvider`, the same source
/// of truth as graduate-only access; "Начать" opens the existing
/// verification flow. There is no "Подписка" item: subscriptions are
/// managed on the website only.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const Key startVerificationKey = ValueKey(
    'profile-start-verification',
  );
  static const Key graduateConfirmedKey = ValueKey(
    'profile-graduate-confirmed',
  );

  static const String coverAsset = 'assets/images/profile/profile_cover.png';

  /// Height of the cover (651:3349), status bar included.
  static const double coverHeight = 350;

  static const String logoutMessage = 'Выйти из аккаунта?';

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmSheet(
      context,
      message: logoutMessage,
      confirmLabel: 'Выйти',
    );
    if (!confirmed) return;
    // Signing out makes the router guard leave for /login.
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Loads the profile ahead of the sub-screens and keeps it while the
    // profile section is open; nothing here depends on it.
    ref.listen(currentProfileProvider, (_, _) {});

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Cover(),
            const _GraduateBlock(),
            ProfileMenu(
              tiles: [
                ProfileMenuTile(
                  label: 'Личные данные',
                  onTap: () => context.push(AppRoutes.profilePersonalData),
                ),
                ProfileMenuTile(
                  label: 'Уведомления',
                  onTap: () => context.push(AppRoutes.profileNotifications),
                ),
                ProfileMenuTile(
                  label: 'Правовая информация',
                  onTap: () => context.push(AppRoutes.profileLegal),
                ),
                ProfileMenuTile(
                  label: 'Выйти',
                  onTap: () => _logout(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The cover image (651:3349) with the "Личный кабинет" title, 32px below
/// the status bar.
class _Cover extends StatelessWidget {
  const _Cover();

  /// Figma title box (651:3350): 16px from the left, 55px from the right.
  static const EdgeInsets _titleInsets = EdgeInsets.only(
    left: AppSpacing.md,
    right: 55,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ProfileScreen.coverHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(ProfileScreen.coverAsset, fit: BoxFit.cover),
          Positioned(
            top: MediaQuery.paddingOf(context).top + AppSpacing.xl,
            left: _titleInsets.left,
            right: _titleInsets.right,
            child: Text(
              'Личный кабинет',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
        ],
      ),
    );
  }
}

/// The `lightBlueTint` graduate block (651:3561 / 651:3747). Hidden until
/// the status is known, so a confirmed graduate never sees the "Начать"
/// prompt flash — and it stays hidden if the status cannot be loaded.
class _GraduateBlock extends ConsumerWidget {
  const _GraduateBlock();

  /// Figma description width (651:3564).
  static const double _descriptionWidth = 231;

  static const double _checkSize = 24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verification = ref.watch(currentVerificationProvider);
    if (!verification.hasValue) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final confirmed = verification.value?.isConfirmed ?? false;

    return ColoredBox(
      color: AppColors.lightBlueTint,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xl,
        ),
        child: confirmed
            ? Row(
                key: ProfileScreen.graduateConfirmedKey,
                children: [
                  Expanded(
                    child: Text(
                      'Выпускник Процесса Хоффмана',
                      style: textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // TODO(figma): swap for the `done_RoundedFill` SVG once
                  // flutter_svg is added.
                  const Icon(
                    Icons.check,
                    size: _checkSize,
                    color: AppColors.basicBlack,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Выпускник Процесса Хоффмана?',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: _descriptionWidth,
                    child: Text(
                      'Пройдите верификацию и получите доступ к '
                      'расширенным возможностям приложения',
                      style: textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: AuthSubmitButton.height,
                    child: AppButton(
                      key: ProfileScreen.startVerificationKey,
                      label: 'Начать',
                      variant: AppButtonVariant.secondary,
                      trailingIcon: Icons.arrow_forward,
                      onPressed: () =>
                          context.push(AppRoutes.profileVerification),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
