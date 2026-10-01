import 'package:flutter/material.dart';

/// The flower photo at 20% opacity, cropped exactly like the Figma `CROP`
/// image fill (a rotated crop) of the splash (131:2674) and the locked
/// section (139:5278) — the same image and crop in both. Draw it over
/// `AppColors.background`.
class FlowerBackground extends StatelessWidget {
  const FlowerBackground({super.key});

  static const String asset = 'assets/images/splash/splash_background.png';
  static const double opacity = 0.2;

  /// Figma `imageTransform`: maps frame-normalized coordinates (u, v) to
  /// image-normalized ones — `image = A · (u, v) + t`.
  static const double _a = 0.45181095600128174;
  static const double _b = 0.3245818316936493;
  static const double _tx = 0.0041295001283288;
  static const double _c = -0.10557114332914352;
  static const double _d = 0.6906721591949463;
  static const double _ty = 0.20737136900424957;

  /// The inverse mapping in pixels: the image, stretched over a w×h box, is
  /// placed so that each frame pixel shows the image point Figma shows.
  static Matrix4 _transform(double w, double h) {
    const det = _a * _d - _b * _c;
    const ia = _d / det;
    const ib = -_b / det;
    const ic = -_c / det;
    const id = _a / det;
    // p = S · A⁻¹ · (S⁻¹ · q − t), with S = diag(w, h).
    return Matrix4(
      ia,
      ic * h / w,
      0,
      0, //
      ib * w / h,
      id,
      0,
      0,
      0,
      0,
      1,
      0,
      -(ia * _tx + ib * _ty) * w,
      -(ic * _tx + id * _ty) * h,
      0,
      1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Opacity(
          opacity: opacity,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxWidth: w,
              maxHeight: h,
              child: Transform(
                transform: _transform(w, h),
                child: Image.asset(
                  asset,
                  width: w,
                  height: h,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
