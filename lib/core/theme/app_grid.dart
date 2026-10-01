import 'package:hoffman/core/theme/app_spacing.dart';

/// The 8-column layout grid of the Figma screens, `spacing/md` side margins.
///
/// Figma (node 1:957): 38px columns and 8px gutters across 360px of
/// content (8 × 38 + 7 × 8). Every size below scales with the content width
/// (the width between the margins) in that proportion.
abstract final class AppGrid {
  static const int columns = 8;

  /// Side margin of the screen content.
  static const double margin = AppSpacing.md;

  /// Width of one column: 38 / 360 of [contentWidth].
  static double column(double contentWidth) => contentWidth * 19 / 180;

  /// Gap between two columns: 8 / 360 of [contentWidth].
  static double gutter(double contentWidth) => contentWidth * 4 / 180;

  /// Distance from the content start to the start of column [count] + 1,
  /// i.e. [count] columns with their gutters.
  static double boundary(double contentWidth, int count) =>
      contentWidth * 23 / 180 * count;

  /// Width of [count] adjacent columns and the gutters between them.
  static double span(double contentWidth, int count) =>
      contentWidth * (19 * count + 4 * (count - 1)) / 180;
}
