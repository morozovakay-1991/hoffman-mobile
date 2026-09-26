import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/presentation/widgets/auth_widgets.dart';

/// "Вы выпускник Процесса Хоффмана?" — Figma 139:5310 (`Registration. Are
/// you graduate?`). Where registration lands (`/verification`).
///
/// "Да" opens the graduate data form; "Нет" goes straight to the home
/// screen. There is deliberately no "skip" option.
class GraduateQuestionScreen extends StatelessWidget {
  const GraduateQuestionScreen({super.key});

  static const Key yesKey = ValueKey('graduate-yes');
  static const Key noKey = ValueKey('graduate-no');

  /// Figma `H1` width (131:1874) less its 16px side padding.
  static const double titleWidth = 253;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      children: [
        const HoffmanWordmark(),
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: titleWidth,
              child: Text(
                'Вы выпускник Процесса Хоффмана?',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(height: 28 / 20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 72),
        AuthSubmitButton(
          key: yesKey,
          label: 'Да',
          onPressed: () => context.push(AppRoutes.verificationForm),
        ),
        const SizedBox(height: AppSpacing.md),
        AuthSubmitButton(
          key: noKey,
          label: 'Нет',
          variant: AppButtonVariant.secondary,
          onPressed: () => context.go(AppRoutes.home),
        ),
      ],
    );
  }
}
