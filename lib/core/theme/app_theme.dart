import 'package:flutter/material.dart';
import 'package:hoffman/core/theme/app_colors.dart';
import 'package:hoffman/core/theme/app_radius.dart';
import 'package:hoffman/core/theme/app_typography.dart';

/// App-wide [ThemeData], built from the tokens mirrored in
/// `docs/mockups/design-tokens.json`.
abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.basicBlack,
      onPrimary: AppColors.lightBlueTint,
      secondary: AppColors.blueTint,
      onSurfaceVariant: AppColors.softBlack,
      outline: AppColors.grey,
      error: AppColors.fireRed,
    );

    final textTheme = AppTypography.buildTextTheme(color: AppColors.basicBlack);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.basicBlack,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.basicBlack,
      ),
    );
  }
}
