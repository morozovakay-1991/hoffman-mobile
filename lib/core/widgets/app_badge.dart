import 'package:flutter/material.dart';
import 'package:hoffman/core/theme/index.dart';

/// Visual style of [AppBadge].
enum AppBadgeVariant {
  /// White fill, black 0.5px outline and a trailing arrow — Figma `badges`
  /// Default / Variant2 / Variant3 (nodes 2:30, 2:33, 2:37).
  outlined,

  /// `lightBlueTint` fill, no outline, no arrow — Figma `badges` Variant4
  /// (node 2:93).
  tinted,
}

/// Badge / tag, Figma component `badges` (node 2:32).
///
/// The Figma variants differ only by label (`темы`, `все`, `инструменты`,
/// `выражение`), so the label is a parameter and [variant] picks the style.
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    super.key,
    this.variant = AppBadgeVariant.outlined,
    this.onTap,
  });

  static const double borderWidth = 0.5;

  // TODO(figma): replace with the exported `section arrow` SVG (node 2:24,
  // 6×10.7px) once SVG assets are added to the project.
  static const double arrowSize = 16;

  final String label;
  final AppBadgeVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isOutlined = variant == AppBadgeVariant.outlined;

    final badge = DecoratedBox(
      decoration: BoxDecoration(
        color: isOutlined ? AppColors.background : AppColors.lightBlueTint,
        borderRadius: AppRadius.mdAll,
        border: isOutlined ? Border.all(width: borderWidth) : null,
      ),
      child: Padding(
        // Figma: spacing/xxs top, 5px bottom, spacing/sm sides.
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xxs,
          AppSpacing.sm,
          5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            if (isOutlined) ...[
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                size: arrowSize,
                color: AppColors.basicBlack,
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return badge;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: badge,
    );
  }
}
