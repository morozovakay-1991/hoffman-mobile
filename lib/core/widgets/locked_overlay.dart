import 'package:flutter/material.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/app_button.dart';

/// A button of [LockedOverlay].
@immutable
class LockedOverlayAction {
  const LockedOverlayAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// Texts of the [LockedOverlay] presets.
///
/// Status-only wording: they say what is locked and how to sign in or
/// restore access, never anything about purchases (App Store review
/// guideline 3.1.1). Keep new presets to the same vocabulary — a test checks
/// these strings for purchase-related words.
abstract final class LockedOverlayText {
  static const String restrictedTitle = 'Доступ ограничен';
  static const String signInDescription =
      'Войдите в аккаунт, чтобы открыть этот раздел';
  static const String restoreAccessDescription =
      'Восстановите доступ, чтобы открыть этот раздел';
  static const String signIn = 'Войти';
  static const String createAccount = 'Создать аккаунт';
  static const String restoreAccess = 'Восстановить доступ';

  static const String graduateOnlyTitle =
      'Доступно после подтверждения статуса выпускника';
  static const String verify = 'Пройти верификацию';

  /// Figma 131:3602 (`Diary`).
  static const String lockedDayTitle =
      'Этот день заблокирован. Попробуйте завтра';

  /// Every preset string, for the wording check.
  static const List<String> all = [
    restrictedTitle,
    signInDescription,
    restoreAccessDescription,
    signIn,
    createAccount,
    restoreAccess,
    graduateOnlyTitle,
    verify,
    lockedDayTitle,
  ];
}

/// Placeholder for a section the user has no access to: a centered title,
/// an optional description, the lock icon and up to two buttons. Styled
/// after the locked diary day (Figma 131:3602).
///
/// The widget only lays things out; texts and callbacks come from the
/// caller, or from a preset constructor ([LockedOverlay.signedOut],
/// [LockedOverlay.inactiveAccount], [LockedOverlay.graduateOnly],
/// [LockedOverlay.lockedDay]).
///
/// With a [child], the overlay covers it with a white scrim; the child is
/// still drawn but can't be tapped or reached by screen readers.
class LockedOverlay extends StatelessWidget {
  const LockedOverlay({
    required this.title,
    super.key,
    this.description,
    this.primaryAction,
    this.secondaryAction,
    this.child,
  });

  /// Signed out, or signed in without an active account status:
  /// "Войти" / "Создать аккаунт". Pass `null` [onCreateAccount] to hide the
  /// second button (e.g. while `registration_enabled` is off).
  LockedOverlay.signedOut({
    required VoidCallback onSignIn,
    required VoidCallback? onCreateAccount,
    Key? key,
    Widget? child,
  }) : this(
         key: key,
         title: LockedOverlayText.restrictedTitle,
         description: LockedOverlayText.signInDescription,
         primaryAction: LockedOverlayAction(
           label: LockedOverlayText.signIn,
           onPressed: onSignIn,
         ),
         secondaryAction: onCreateAccount == null
             ? null
             : LockedOverlayAction(
                 label: LockedOverlayText.createAccount,
                 onPressed: onCreateAccount,
               ),
         child: child,
       );

  /// Has an account, but its status is not active: "Восстановить доступ",
  /// which should lead to the support / sign-in-again screen.
  LockedOverlay.inactiveAccount({
    required VoidCallback onRestoreAccess,
    Key? key,
    Widget? child,
  }) : this(
         key: key,
         title: LockedOverlayText.restrictedTitle,
         description: LockedOverlayText.restoreAccessDescription,
         primaryAction: LockedOverlayAction(
           label: LockedOverlayText.restoreAccess,
           onPressed: onRestoreAccess,
         ),
         child: child,
       );

  /// Graduate-only sections (the Diary) for users whose graduate status is
  /// not confirmed: "Пройти верификацию".
  LockedOverlay.graduateOnly({
    required VoidCallback onVerify,
    Key? key,
    Widget? child,
  }) : this(
         key: key,
         title: LockedOverlayText.graduateOnlyTitle,
         primaryAction: LockedOverlayAction(
           label: LockedOverlayText.verify,
           onPressed: onVerify,
         ),
         child: child,
       );

  /// A Diary day that opens tomorrow (Figma 131:3602). No buttons.
  const LockedOverlay.lockedDay({Key? key, Widget? child})
    : this(key: key, title: LockedOverlayText.lockedDayTitle, child: child);

  /// Title width in 131:3602.
  static const double titleMaxWidth = 218;
  static const double descriptionMaxWidth = 296;
  static const double iconSize = 20;

  /// Button size of the stacked buttons in the auth mockups (e.g. 139:5306).
  static const double buttonWidth = 232;
  static const double buttonHeight = 28;

  /// Opacity of the white scrim over [child].
  static const double scrimOpacity = 0.9;

  final String title;
  final String? description;
  final LockedOverlayAction? primaryAction;
  final LockedOverlayAction? secondaryAction;

  /// The locked content, drawn under the overlay.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final panel = _buildPanel(context);
    final child = this.child;
    if (child == null) return panel;

    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(child: IgnorePointer(child: child)),
        ColoredBox(
          color: AppColors.background.withValues(alpha: scrimOpacity),
          child: panel,
        ),
      ],
    );
  }

  Widget _buildPanel(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final description = this.description;
    final actions = [?primaryAction, ?secondaryAction];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: titleMaxWidth),
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(height: 38 / 20),
                ),
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: descriptionMaxWidth,
                ),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge?.copyWith(height: 20 / 14),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            const Icon(Icons.lock, size: iconSize, color: AppColors.basicBlack),
            for (final (i, action) in actions.indexed) ...[
              SizedBox(height: i == 0 ? AppSpacing.xl : AppSpacing.md),
              SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: AppButton(
                  label: action.label,
                  variant: identical(action, primaryAction)
                      ? AppButtonVariant.primary
                      : AppButtonVariant.secondary,
                  onPressed: action.onPressed,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
