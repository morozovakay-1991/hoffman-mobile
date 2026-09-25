import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hoffman/core/theme/app_colors.dart';

/// Typography tokens mirrored from `docs/mockups/design-tokens.json`
/// (`typography`). headlineLarge, titleLarge, bodySmall and labelMedium come
/// from Figma; the rest are Material defaults (see `source` in the JSON).
abstract final class AppTypography {
  static const double _height = 1.15;

  static TextTheme buildTextTheme({required Color color}) {
    final base = TextTheme(
      displayLarge: _style(57, FontWeight.w400, color),
      displayMedium: _style(45, FontWeight.w400, color),
      displaySmall: _style(36, FontWeight.w400, color),
      headlineLarge: _style(32, FontWeight.w400, color),
      headlineMedium: _style(28, FontWeight.w400, color),
      headlineSmall: _style(24, FontWeight.w400, color),
      titleLarge: _style(20, FontWeight.w400, color),
      titleMedium: _style(16, FontWeight.w500, color),
      titleSmall: _style(14, FontWeight.w500, color),
      bodyLarge: _style(16, FontWeight.w400, color),
      bodyMedium: _style(14, FontWeight.w400, color),
      bodySmall: _style(12, FontWeight.w400, color),
      labelLarge: _style(14, FontWeight.w500, color),
      labelMedium: _style(12, FontWeight.w500, color),
      labelSmall: _style(11, FontWeight.w500, color),
    );

    return GoogleFonts.golosTextTextTheme(base);
  }

  /// [style] in Golos Text at [weight], using that weight's real font file.
  /// `copyWith(fontWeight: ...)` on a theme style would only synthesize the
  /// weight, since google_fonts pins one file per style (e.g. the Figma
  /// `Text/Link` SemiBold 600).
  static TextStyle withWeight(TextStyle? style, FontWeight weight) {
    return GoogleFonts.golosText(textStyle: style, fontWeight: weight);
  }

  static TextStyle _style(double fontSize, FontWeight weight, Color color) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: weight,
      height: _height,
      // Figma text styles have 0 tracking. Must be explicit: MaterialApp
      // merges the M3 `englishLike` geometry (0.1–0.5 letterSpacing) into
      // any style that leaves it null.
      letterSpacing: 0,
      color: color,
    );
  }
}

/// Default light-theme text theme, built on [AppColors.basicBlack].
final TextTheme appLightTextTheme = AppTypography.buildTextTheme(
  color: AppColors.basicBlack,
);
