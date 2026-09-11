import 'package:flutter/material.dart';
import 'package:hoffman/core/theme/app_colors.dart';
import 'package:hoffman/core/theme/app_radius.dart';
import 'package:hoffman/core/theme/app_typography.dart';

// TODO(figma): rebuild from the real design tokens once Figma MCP access is
// restored; this theme currently uses placeholder monochrome/Inter values.
/// App-wide [ThemeData], built from the tokens mirrored in
/// `docs/mockups/design-tokens.json`.
abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.black,
      secondary: AppColors.grey700,
      onSecondary: AppColors.white,
      surfaceContainerHighest: AppColors.grey100,
      outline: AppColors.grey300,
      error: Color(0xFFB3261E),
    );

    final textTheme = AppTypography.buildTextTheme(color: AppColors.black);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.white,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey100,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide.none,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.grey700),
      ),
    );
  }
}
