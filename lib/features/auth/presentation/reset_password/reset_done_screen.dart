import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/features/auth/application/reset_password_controller.dart';
import 'package:hoffman/features/auth/presentation/widgets/auth_widgets.dart';

/// Reset password, step 4 of 4 — Figma 139:5309 (`Password changed`).
/// Drops the email and code kept for the previous steps.
class ResetDoneScreen extends ConsumerStatefulWidget {
  const ResetDoneScreen({super.key});

  /// Figma button width (131:1894).
  static const double submitWidth = 180;

  @override
  ConsumerState<ResetDoneScreen> createState() => _ResetDoneScreenState();
}

class _ResetDoneScreenState extends ConsumerState<ResetDoneScreen> {
  @override
  void initState() {
    super.initState();
    // Providers can't be modified while the tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(resetPasswordControllerProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      children: [
        const AuthHeading(
          title: 'Пароль изменен',
          subtitle: 'Теперь вы можете войти в свой аккаунт',
          largeSubtitle: true,
        ),
        const SizedBox(height: 68),
        AuthSubmitButton(
          label: 'Войти',
          width: ResetDoneScreen.submitWidth,
          onPressed: () => context.go(AppRoutes.login),
        ),
      ],
    );
  }
}
