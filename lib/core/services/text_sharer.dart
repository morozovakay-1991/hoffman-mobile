import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the system share sheet with [text]. [origin] is the global rect of
/// the share button: iPad anchors its popover there and needs it.
typedef TextSharer = Future<void> Function(
  String text, {
  String? subject,
  Rect? origin,
});

/// [TextSharer] backed by share_plus. Overridden in tests.
final textSharerProvider = Provider<TextSharer>(
  (ref) =>
      (text, {subject, origin}) => SharePlus.instance.share(
        ShareParams(text: text, subject: subject, sharePositionOrigin: origin),
      ),
);
