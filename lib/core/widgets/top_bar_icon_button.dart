import 'package:flutter/material.dart';
import 'package:hoffman/core/theme/index.dart';

/// An icon of the detail screens' top bar (back, share): the glyph in a
/// 24×24 box, as the Figma icons `short arrow back` (2:211) and `sharing`
/// (2:236), centered in a [tapSize] square that keeps the tap target
/// larger than the glyph.
class TopBarIconButton extends StatelessWidget {
  const TopBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
    this.color = AppColors.basicBlack,
  });

  static const double iconSize = 24;

  /// The full height of the 40px bar.
  static const double tapSize = 40;

  /// Space between the tap square's edge and the 24px glyph box.
  static const double inset = (tapSize - iconSize) / 2;

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onPressed,
          radius: tapSize / 2,
          child: SizedBox.square(
            dimension: tapSize,
            child: Center(
              child: SizedBox.square(
                dimension: iconSize,
                child: Icon(icon, size: iconSize, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
