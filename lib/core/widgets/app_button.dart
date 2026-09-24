import 'package:flutter/material.dart';
import 'package:hoffman/core/theme/index.dart';

/// Visual variants of [AppButton].
enum AppButtonVariant {
  /// Black fill — Figma `Buttons` Variant2 / Variant3 / Variant5.
  primary,

  /// White fill with a 0.5px black outline — Figma `Buttons` Default.
  secondary,

  /// No fill and no outline — styled after the `meditation link` component
  /// (Figma node 2:121).
  text,
}

/// App button, Figma node 1:129 (`Buttons`).
///
/// Pass `null` to [onPressed] to disable the button. A disabled primary or
/// secondary button follows `Buttons` Variant4 (node 2:11): grey fill, black
/// label and no icon.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
    this.trailingIcon,
  });

  /// Width of every `Buttons` instance in the mockup.
  static const double minWidth = 130;

  /// Height of the fixed-height `Buttons` variants (Variant2/3/4).
  static const double minHeight = 25;

  /// Corner radius of every `Buttons` variant. Figma uses 3px, which is not
  /// on the `radius` token scale, so it is kept here instead of `AppRadius`.
  static const double radius = 3;
  static const BorderRadius borderRadius = BorderRadius.all(
    Radius.circular(radius),
  );

  static const double _iconSize = 16;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? trailingIcon;

  bool get _enabled => onPressed != null;

  /// Primary and secondary switch to the Variant4 look when disabled.
  bool get _showsDisabledStyle => !_enabled && variant != AppButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    // TODO(figma): no disabled reference for the text variant — it only
    // stops reacting to taps and keeps its look.
    final foreground = _foregroundColor;
    final labelStyle = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: foreground);
    final icon = _showsDisabledStyle ? null : trailingIcon;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: labelStyle),
        if (icon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(icon, size: _iconSize, color: foreground),
        ],
      ],
    );

    final shape = RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: variant == AppButtonVariant.secondary && !_showsDisabledStyle
          ? const BorderSide(width: 0.5)
          : BorderSide.none,
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      child: Material(
        type: variant == AppButtonVariant.text
            ? MaterialType.transparency
            : MaterialType.canvas,
        color: _fillColor,
        shape: shape,
        child: InkWell(
          onTap: onPressed,
          customBorder: shape,
          child: switch (variant) {
            AppButtonVariant.text => content,
            AppButtonVariant.primary ||
            AppButtonVariant.secondary => ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: minWidth,
                minHeight: minHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: content,
              ),
            ),
          },
        ),
      ),
    );
  }

  Color? get _fillColor {
    if (_showsDisabledStyle) return AppColors.grey;
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.basicBlack;
      case AppButtonVariant.secondary:
        return AppColors.background;
      case AppButtonVariant.text:
        return null;
    }
  }

  Color get _foregroundColor {
    if (_showsDisabledStyle) return AppColors.basicBlack;
    switch (variant) {
      case AppButtonVariant.primary:
        // Figma: primary with an arrow (Variant2/3) uses Light blue tint,
        // primary without an icon (Variant5) uses white.
        return trailingIcon != null
            ? AppColors.lightBlueTint
            : AppColors.background;
      case AppButtonVariant.secondary:
      case AppButtonVariant.text:
        return AppColors.basicBlack;
    }
  }
}
