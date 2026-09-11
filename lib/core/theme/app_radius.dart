import 'package:flutter/material.dart';

// TODO(figma): replace with the real corner-radius scale once Figma MCP
// access is restored.
/// Radius tokens mirrored from `docs/mockups/design-tokens.json` (`radius`).
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
}
