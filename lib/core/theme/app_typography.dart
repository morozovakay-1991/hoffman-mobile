import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hoffman/core/theme/app_colors.dart';

// TODO(figma): replace with the real type scale once Figma MCP access is
// restored — sizes, weights and line heights below are placeholders and the
// font family is Inter rather than the mockup's real typeface.
/// Typography tokens mirrored from `docs/mockups/design-tokens.json`
/// (`typography`).
abstract final class AppTypography {
  static TextTheme buildTextTheme({required Color color}) {
    final base = TextTheme(
      displayLarge: _style(40, FontWeight.w700, 1.2, color),
      displayMedium: _style(34, FontWeight.w700, 1.2, color),
      displaySmall: _style(28, FontWeight.w700, 1.25, color),
      headlineLarge: _style(26, FontWeight.w700, 1.25, color),
      headlineMedium: _style(24, FontWeight.w600, 1.3, color),
      headlineSmall: _style(22, FontWeight.w600, 1.3, color),
      titleLarge: _style(20, FontWeight.w600, 1.3, color),
      titleMedium: _style(18, FontWeight.w600, 1.35, color),
      titleSmall: _style(16, FontWeight.w600, 1.4, color),
      bodyLarge: _style(16, FontWeight.w400, 1.5, color),
      bodyMedium: _style(14, FontWeight.w400, 1.5, color),
      bodySmall: _style(12, FontWeight.w400, 1.5, color),
      labelLarge: _style(14, FontWeight.w500, 1.3, color),
      labelMedium: _style(12, FontWeight.w500, 1.3, color),
      labelSmall: _style(11, FontWeight.w500, 1.3, color),
    );

    return GoogleFonts.interTextTheme(base);
  }

  static TextStyle _style(
    double fontSize,
    FontWeight weight,
    double height,
    Color color,
  ) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: weight,
      height: height,
      color: color,
    );
  }
}

/// Default light-theme text theme, built on [AppColors.black].
final TextTheme appLightTextTheme = AppTypography.buildTextTheme(
  color: AppColors.black,
);
