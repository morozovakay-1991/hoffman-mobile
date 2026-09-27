import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/config/feature_flags.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';

/// "Ваш аккаунт удален" — Figma 753:3884. Shown after `DELETE /profile`,
/// once the session has ended. "Зарегистрироваться" is hidden while the
/// `registration_enabled` flag is off, as on the Login screen.
class AccountDeletedScreen extends ConsumerWidget {
  const AccountDeletedScreen({super.key});

  static const Key loginKey = ValueKey('account-deleted-login');
  static const Key registerKey = ValueKey('account-deleted-register');

  /// Button width in 753:3891.
  static const double buttonWidth = 177;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrationEnabled =
        ref.watch(registrationEnabledProvider).value ?? true;

    return AuthScaffold(
      children: [
        // The title sits 5px below the status bar (753:3887).
        const SizedBox(height: AppSpacing.xs),
        const AuthHeading(
          title: 'Ваш аккаунт удален',
          subtitle:
              'Все ваши данные были успешно удалены из системы. Будем рады '
              'видеть вас снова!',
          largeSubtitle: true,
        ),
        const SizedBox(height: 64),
        AuthSubmitButton(
          key: loginKey,
          label: 'Войти',
          width: buttonWidth,
          onPressed: () => context.go(AppRoutes.login),
        ),
        if (registrationEnabled) ...[
          const SizedBox(height: AppSpacing.md),
          AuthSubmitButton(
            key: registerKey,
            label: 'Зарегистрироваться',
            width: buttonWidth,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.go(AppRoutes.register),
          ),
        ],
      ],
    );
  }
}
