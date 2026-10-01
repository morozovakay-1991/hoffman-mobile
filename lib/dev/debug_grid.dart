import 'package:flutter/material.dart';
import 'package:hoffman/core/theme/index.dart';

// Debug-only overlay of the Figma layout grid (nodes 1:939 / 1:957): eight
// 38px columns with 8px gutters between the 16px screen margins, scaled to
// the real screen width with the [AppGrid] formulas. A small button in the
// corner shows and hides it over every screen of the app.

/// `MaterialApp.builder` that puts [DebugGridHost] above the navigator, or
/// `null` (no builder at all) unless [enabled].
///
/// Pass `kDebugMode && ...` so release builds compile the whole tool out.
TransitionBuilder? debugGridBuilder({required bool enabled}) {
  if (!enabled) return null;
  return (context, child) => DebugGridHost(child: child ?? const SizedBox());
}

/// Wraps the app ([child], the navigator) with the [GridOverlay] toggle.
///
/// Sits above every route, so the grid stays on while navigating.
class DebugGridHost extends StatefulWidget {
  const DebugGridHost({required this.child, super.key});

  static const Key toggleKey = ValueKey('debug-grid-toggle');

  /// Above the tab bar.
  static const double toggleBottom = 96;

  final Widget child;

  @override
  State<DebugGridHost> createState() => _DebugGridHostState();
}

class _DebugGridHostState extends State<DebugGridHost> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return Stack(
      children: [
        widget.child,
        if (_visible)
          const Positioned.fill(child: IgnorePointer(child: GridOverlay())),
        Positioned(
          right: padding.right + AppGrid.margin,
          bottom: padding.bottom + DebugGridHost.toggleBottom,
          child: Semantics(
            button: true,
            label: _visible ? 'Скрыть сетку' : 'Показать сетку',
            excludeSemantics: true,
            child: FloatingActionButton.small(
              key: DebugGridHost.toggleKey,
              // Above the navigator: no Hero or Tooltip, which need it.
              heroTag: null,
              backgroundColor: AppColors.basicBlack.withValues(alpha: 0.6),
              foregroundColor: AppColors.background,
              onPressed: () => setState(() => _visible = !_visible),
              child: Icon(_visible ? Icons.grid_off : Icons.grid_on),
            ),
          ),
        ),
      ],
    );
  }
}

/// The grid columns as translucent stripes over the whole screen height.
class GridOverlay extends StatelessWidget {
  const GridOverlay({super.key});

  /// Figma's default layout grid fill: red at 15%.
  static const Color color = Color(0x26FF0000);

  /// The [AppGrid.columns] column rects on a [size] screen whose content
  /// sits inside the horizontal safe area [padding].
  static List<Rect> columnRects(Size size, EdgeInsets padding) {
    final start = padding.left + AppGrid.margin;
    final content =
        size.width - padding.left - padding.right - 2 * AppGrid.margin;

    return [
      for (var i = 0; i < AppGrid.columns; i++)
        Rect.fromLTWH(
          start + AppGrid.boundary(content, i),
          0,
          AppGrid.column(content),
          size.height,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(MediaQuery.paddingOf(context)),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter(this.padding);

  final EdgeInsets padding;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = GridOverlay.color;
    for (final rect in GridOverlay.columnRects(size, padding)) {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) =>
      oldDelegate.padding != padding;
}
