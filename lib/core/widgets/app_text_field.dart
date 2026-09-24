import 'package:flutter/material.dart';
import 'package:hoffman/core/theme/index.dart';

/// Single-line text input, Figma node 132:5070 (`Fields`).
///
/// A label (with an optional `*`) above a `blueTint` box. States:
/// - idle (`usial field`, 132:5079): no outline;
/// - focused (`active field`, 132:5071): 0.5px black outline;
/// - [errorText] set (Variant2, 132:5101): 0.5px `fireRed` outline and the
///   message below in `fireRed`;
/// - disabled (Variant7, 132:5191): `grey` fill, no outline.
///
/// [helperText] (`Field`, 132:5085) is a black note below the box; it is
/// replaced by [errorText] when both are set.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    super.key,
    this.controller,
    this.helperText,
    this.errorText,
    this.isRequired = false,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
  });

  /// Corner radius of the input box. Figma uses 3px, which is not on the
  /// `radius` token scale.
  static const double radius = 3;
  static const BorderRadius borderRadius = BorderRadius.all(
    Radius.circular(radius),
  );

  static const double borderWidth = 0.5;

  /// Inner padding of the input box (Figma `p-[10px]`, off the spacing scale).
  static const double _contentPadding = 10;

  final String label;
  final TextEditingController? controller;
  final String? helperText;
  final String? errorText;

  /// Shows `*` after the label.
  final bool isRequired;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;

  bool get _hasError => errorText != null;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final note = errorText ?? helperText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(child: Text(label, style: textTheme.labelMedium)),
            if (isRequired) ...[
              const SizedBox(width: AppSpacing.xs),
              // TODO(figma): the asterisk uses the `Text/T1` style (Golos
              // Text Regular 17 / 1.4), which is not in the design tokens.
              Text(
                '*',
                style: textTheme.labelMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          style: textTheme.bodySmall,
          cursorColor: AppColors.basicBlack,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: enabled ? AppColors.blueTint : AppColors.grey,
            hoverColor: Colors.transparent,
            contentPadding: const EdgeInsets.all(_contentPadding),
            border: _border(null),
            enabledBorder: _border(_hasError ? AppColors.fireRed : null),
            focusedBorder: _border(
              _hasError ? AppColors.fireRed : AppColors.basicBlack,
            ),
            disabledBorder: _border(null),
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            note,
            style: textTheme.bodySmall?.copyWith(
              color: _hasError ? AppColors.fireRed : AppColors.basicBlack,
            ),
          ),
        ],
      ],
    );
  }

  static InputBorder _border(Color? color) {
    return OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: color == null
          ? BorderSide.none
          : BorderSide(color: color, width: borderWidth),
    );
  }
}
