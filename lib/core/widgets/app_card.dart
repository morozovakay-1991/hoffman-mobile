import 'package:flutter/material.dart';
import 'package:hoffman/core/theme/index.dart';

/// Base card wrapper built from design tokens: white background,
/// `radius/md` corners, `spacing/md` padding and a 0.5px `grey` outline.
/// With [onTap] set, taps show the standard Material ink ripple.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.borderColor = AppColors.grey,
    this.onTap,
  });

  static const double borderWidth = 0.5;

  final Widget child;

  /// Outline color; `null` removes the outline.
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: AppRadius.mdAll,
      side: borderColor == null
          ? BorderSide.none
          : BorderSide(color: borderColor!, width: borderWidth),
    );
    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: child,
    );

    return Material(
      color: AppColors.background,
      shape: shape,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, customBorder: shape, child: content),
    );
  }
}
