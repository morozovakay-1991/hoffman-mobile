import 'package:flutter/material.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/app_button.dart';

/// "Вы уверены?" bottom sheet — Figma 1000:3424 (sign out) and 1000:2891
/// (account deletion): a handle, a centered title and [message], then a
/// primary "Отменить" above the secondary [confirmLabel] button.
///
/// Open it with [showConfirmSheet].
class ConfirmSheet extends StatelessWidget {
  const ConfirmSheet({
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
    super.key,
    this.title = defaultTitle,
    this.cancelLabel = defaultCancelLabel,
  });

  static const String defaultTitle = 'Вы уверены?';
  static const String defaultCancelLabel = 'Отменить';

  static const Key confirmKey = ValueKey('confirm-sheet-confirm');
  static const Key cancelKey = ValueKey('confirm-sheet-cancel');

  /// Figma `rounded-tl/tr-[5px]`, off the `radius` token scale.
  static const double radius = 5;

  /// Figma `Handle` (1000:3416): 36×5, iOS `#D1D1D6`, not a design token.
  static const Size handleSize = Size(36, 5);
  static const Color handleColor = Color(0xFFD1D1D6);

  static const double buttonWidth = 232;
  static const double buttonHeight = 28;

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        bottomInset > AppSpacing.xl ? bottomInset : AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Full width, like the 393px sheet in the mockup; the Material 3
        // sheet would otherwise shrink to the widest child.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: handleSize.width,
              height: handleSize.height,
              decoration: const BoxDecoration(
                color: handleColor,
                borderRadius: AppRadius.mdAll,
              ),
            ),
          ),
          const SizedBox(height: 19),
          // TODO(figma): the title is Helvetica 32/38 in the mockup, which
          // is not in the design tokens; Golos Text keeps it in the family.
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.headlineLarge?.copyWith(height: 38 / 32),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.labelLarge?.copyWith(height: 22.75 / 14),
          ),
          const SizedBox(height: 64),
          _SheetButton(key: cancelKey, label: cancelLabel, onPressed: onCancel),
          const SizedBox(height: AppSpacing.md),
          _SheetButton(
            key: confirmKey,
            label: confirmLabel,
            variant: AppButtonVariant.secondary,
            onPressed: onConfirm,
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback onPressed;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: ConfirmSheet.buttonWidth,
        height: ConfirmSheet.buttonHeight,
        child: AppButton(label: label, variant: variant, onPressed: onPressed),
      ),
    );
  }
}

/// Shows a [ConfirmSheet] and resolves to `true` only when [confirmLabel]
/// was tapped — "Отменить", a tap on the barrier or a swipe down all give
/// `false`.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String message,
  required String confirmLabel,
  String title = ConfirmSheet.defaultTitle,
}) async {
  // TODO(figma): the mockup also blurs the page behind the 20% black
  // barrier (backdrop-blur 25px); showModalBottomSheet has no blur option.
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    // Over the tab bar too, not just the screen it was opened from.
    useRootNavigator: true,
    backgroundColor: AppColors.background,
    barrierColor: AppColors.grey,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(ConfirmSheet.radius),
      ),
    ),
    builder: (context) => ConfirmSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    ),
  );
  return confirmed ?? false;
}
