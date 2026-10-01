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
  static const double verticalPadding = 3.5;

  /// The `section arrow` box (Figma 2:35): 6×10.7px, [arrowGap] after the
  /// label, the same [AppSpacing.sm] padding after it as before the label.
  static const Size arrowSize = Size(6, 10.7);
  static const double arrowGap = AppSpacing.sm;

  // TODO(figma): replace with the exported `section arrow` SVG once SVG
  // assets are added to the project. Until then the Material chevron at
  // this size has a glyph of the arrow's size, cropped to it.
  static const double _chevronSize = 23;

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
        // Figma: spacing/xxs top and 5px bottom, spacing/sm sides. The same
        // 7px split evenly, so the content sits in the vertical center.
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: verticalPadding,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
              // Line spacing split evenly above and below the glyphs, so the
              // text centers on the arrow and in the badge.
              textHeightBehavior: const TextHeightBehavior(
                leadingDistribution: TextLeadingDistribution.even,
              ),
            ),
            if (isOutlined) ...[
              const SizedBox(width: arrowGap),
              // The icon's own empty margins would widen the gap before the
              // arrow and the padding after it.
              SizedBox.fromSize(
                size: arrowSize,
                child: const OverflowBox(
                  maxWidth: _chevronSize,
                  maxHeight: _chevronSize,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: _chevronSize,
                    color: AppColors.basicBlack,
                  ),
                ),
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
