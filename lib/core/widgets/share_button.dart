import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/core/services/text_sharer.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/top_bar_icon_button.dart';

/// The share icon of the content screens, Figma `sharing` (2:236) in a
/// [TopBarIconButton]: opens the system share sheet with
/// [text] ([subject] for the apps that take one, e.g. mail). A failure
/// shows a snackbar.
class ShareButton extends ConsumerWidget {
  const ShareButton({
    required this.text,
    super.key,
    this.subject,
    this.color = AppColors.basicBlack,
  });

  static const String label = 'Поделиться';
  static const String failed = 'Не удалось поделиться';
  static const double iconSize = TopBarIconButton.iconSize;
  static const IconData icon = Icons.share;

  final String text;
  final String? subject;
  final Color color;

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null || !box.hasSize
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    try {
      await ref.read(textSharerProvider)(
        text,
        subject: subject,
        origin: origin,
      );
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(failed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TopBarIconButton(
      icon: icon,
      tooltip: label,
      color: color,
      onPressed: () => _share(context, ref),
    );
  }
}

/// What the share sheet sends for a content item without a public web
/// page: the [title] and, when there is one, the [description].
String shareTextOf(String title, String description) {
  final trimmed = description.trim();
  return trimmed.isEmpty ? title : '$title\n\n$trimmed';
}
