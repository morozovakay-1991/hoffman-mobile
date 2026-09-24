import 'package:flutter/material.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/app_button.dart';

/// Full-screen error state: a message with a primary retry [AppButton]
/// below it.
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    required this.message,
    required this.onRetry,
    super.key,
    this.retryLabel = 'Повторить',
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: retryLabel, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

/// Full-screen empty state: a centered `titleLarge` message with an icon (or
/// a custom [illustration]) below it, following the locked-day screen in
/// Figma node 131:3602 (`Diary`). Also used for that locked state, e.g.
/// `EmptyStateWidget(message: '…', icon: Icons.lock)`.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    required this.message,
    super.key,
    this.icon = Icons.inbox_outlined,
    this.illustration,
  });

  static const double iconSize = 20;

  final String message;

  /// Ignored when [illustration] is set.
  final IconData icon;
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            illustration ??
                Icon(icon, size: iconSize, color: AppColors.basicBlack),
          ],
        ),
      ),
    );
  }
}
