import 'package:flutter/material.dart';

/// Radius tokens mirrored from `docs/mockups/design-tokens.json` (`radius`).
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 16;
  static const double full = 999;

  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));
}
