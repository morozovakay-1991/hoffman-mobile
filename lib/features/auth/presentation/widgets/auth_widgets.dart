import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';

// Building blocks shared by the Login / Register / Reset password screens
// (Figma 139:5312, 139:5311, 139:5302–139:5309). The mockup is 393×852 with a
// 49px status bar; offsets below are measured from the safe area.

/// White scrollable page with the `spacing/md` side padding.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.children, super.key, this.top});

  /// Pinned above the scrollable content, e.g. [AuthBackBar].
  final Widget? top;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?top,
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The `hoffman` wordmark (`Text/Display`, Golos Text 32).
class HoffmanWordmark extends StatelessWidget {
  const HoffmanWordmark({super.key, this.color = AppColors.basicBlack});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'hoffman',
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: color),
    );
  }
}

/// `H1` block: `Text/H2` title (20/28) and a `Text/Meta` subtitle, 8px
/// apart, 4px vertical padding.
class AuthHeading extends StatelessWidget {
  const AuthHeading({
    required this.title,
    required this.subtitle,
    super.key,
    this.largeSubtitle = false,
    this.subtitleMaxWidth,
    this.subtitleFontSize,
  });

  /// Figma `H1` subtitle width.
  static const double subtitleWidth = 270;

  final String title;
  final String subtitle;

  /// `Text/Label` (14/20) instead of `Text/Meta` — the "Пароль изменен"
  /// screen (139:5309).
  final bool largeSubtitle;

  /// Overrides the subtitle width: [subtitleWidth], or unbounded with
  /// [largeSubtitle].
  final double? subtitleMaxWidth;

  /// Overrides the subtitle size, e.g. 13 for `Text/Tag` (139:5303).
  final double? subtitleFontSize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleLarge?.copyWith(height: 28 / 20)),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  subtitleMaxWidth ??
                  (largeSubtitle ? double.infinity : subtitleWidth),
            ),
            child: Text(
              subtitle,
              style:
                  (largeSubtitle
                          ? textTheme.labelLarge?.copyWith(height: 20 / 14)
                          : textTheme.labelMedium)
                      ?.copyWith(fontSize: subtitleFontSize),
            ),
          ),
        ],
      ),
    );
  }
}

/// 40px top bar with the back chevron (Figma `Icon` Variant5, 131:1643).
class AuthBackBar extends StatelessWidget {
  const AuthBackBar({required this.onBack, super.key});

  static const double height = 40;
  static const double iconSize = 24;

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    // TODO(figma): swap for the exported `Icon` Variant5 SVG once
    // flutter_svg is added.
    return SizedBox(
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          constraints: const BoxConstraints(),
          icon: const Icon(
            Icons.chevron_left,
            size: iconSize,
            color: AppColors.basicBlack,
          ),
          onPressed: onBack,
        ),
      ),
    );
  }
}

/// Reserves a fixed slot for a field so its error message fills the gap
/// below instead of pushing the rest of the form down — as in the error
/// mockups (e.g. 139:5287), where every element keeps its position.
class AuthFieldSlot extends StatelessWidget {
  const AuthFieldSlot({
    required this.child,
    super.key,
    this.height = labeledHeight,
  });

  /// Label (30) + input (34) + the 32px gap to the next element.
  static const double labeledHeight = 96;

  /// Input (34) + the 32px gap, for a field without a label.
  static const double unlabeledHeight = 66;

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: Align(alignment: Alignment.topLeft, child: child),
    );
  }
}

/// `AppTextField` with the auth screens' `lightBlueTint` fill.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.controller,
    super.key,
    this.label,
    this.errorText,
    this.hintText,
    this.helperText,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.onSubmitted,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String? label;
  final String? errorText;
  final String? hintText;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      isRequired: label != null,
      controller: controller,
      errorText: errorText,
      hintText: hintText,
      helperText: helperText,
      onChanged: onChanged,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      fillColor: AppColors.lightBlueTint,
    );
  }
}

/// `AppButton` (primary by default) at the mockup's fixed 28px height.
/// Disabled (grey, Variant4) while [loading].
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.width = AppButton.minWidth,
    this.loading = false,
    this.variant = AppButtonVariant.primary,
  });

  static const double height = 28;

  final String label;
  final VoidCallback onPressed;
  final double width;
  final bool loading;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      // At least the mockup width, wider when the label needs it (Golos Text
      // "Зарегистрироваться" does not fit Figma's 140px box).
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: width),
        child: SizedBox(
          height: height,
          child: AppButton(
            label: label,
            variant: variant,
            onPressed: loading ? null : onPressed,
          ),
        ),
      ),
    );
  }
}

/// `link/Variant7`: Golos Text SemiBold 12, `cherryRed`.
class AuthLink extends StatelessWidget {
  const AuthLink({
    required this.label,
    required this.onTap,
    super.key,
    this.style,
  });

  final String label;
  final VoidCallback? onTap;
  final TextStyle? style;

  static TextStyle linkStyle(BuildContext context) => AppTypography.withWeight(
    Theme.of(context).textTheme.labelMedium,
    FontWeight.w600,
  ).copyWith(color: AppColors.cherryRed);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Text(label, style: style ?? linkStyle(context)),
      ),
    );
  }
}

/// "Нет аккаунта? Зарегистрируйтесь" / "Есть аккаунт? Войти"
/// (`checkbox/Variant4`): plain text, 4px gap, `cherryRed` Medium link.
class AuthSwitchPrompt extends StatelessWidget {
  const AuthSwitchPrompt({
    required this.question,
    required this.action,
    required this.onTap,
    super.key,
  });

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(question, style: textTheme.bodySmall)),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: AuthLink(
            label: action,
            onTap: onTap,
            style: textTheme.labelMedium?.copyWith(color: AppColors.cherryRed),
          ),
        ),
      ],
    );
  }
}

/// The "Войти с" Apple / Google block. Rendered invisible but still taking
/// its space, so the layout matches the mockup: social sign-in is a separate
/// future task.
class HiddenSocialSignIn extends StatelessWidget {
  const HiddenSocialSignIn({super.key});

  static const double _width = 125;

  @override
  Widget build(BuildContext context) {
    // TODO(auth): social sign-in (google_sign_in / sign_in_with_apple) —
    // separate task. Replace the boxes with the Figma `path4` (Apple, 30×36)
    // and `logo googleg 48dp` (30×30) assets and make the block visible.
    // Keeps the size only: not tappable, not announced by screen readers.
    return Visibility(
      visible: false,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      child: SizedBox(
        width: _width,
        child: Column(
          children: [
            Text('Войти с', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(width: 30, height: 36),
                SizedBox(width: 30, height: 30),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The two required consent checkboxes (privacy policy, personal data).
/// With [errorText] set both boxes turn `fireRed` (Figma `checkbox` Variant3)
/// and the 139:5285 message appears below.
class ConsentCheckboxes extends StatelessWidget {
  const ConsentCheckboxes({
    required this.privacyAccepted,
    required this.personalDataAccepted,
    required this.onPrivacyChanged,
    required this.onPersonalDataChanged,
    required this.errorText,
    super.key,
  });

  static const double iconSize = 24;

  final bool privacyAccepted;
  final bool personalDataAccepted;
  final ValueChanged<bool> onPrivacyChanged;
  final ValueChanged<bool> onPersonalDataChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final bodySmall = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConsentRow(
          key: const ValueKey('consent-privacy'),
          checked: privacyAccepted,
          hasError: errorText != null,
          onChanged: onPrivacyChanged,
          prefix: 'Я ознакомлен с ',
          link: 'политикой конфиденциальности',
        ),
        const SizedBox(height: 12),
        _ConsentRow(
          key: const ValueKey('consent-personal-data'),
          checked: personalDataAccepted,
          hasError: errorText != null,
          onChanged: onPersonalDataChanged,
          prefix: 'Я согласен на обработку моих ',
          link: 'персональных данных',
        ),
        const SizedBox(height: AppSpacing.sm),
        // The message line is always laid out so showing it does not shift
        // the content below (139:5285 keeps every position).
        Visibility.maintain(
          visible: errorText != null,
          child: Text(
            errorText ?? '',
            style: bodySmall?.copyWith(color: AppColors.fireRed),
          ),
        ),
      ],
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.checked,
    required this.hasError,
    required this.onChanged,
    required this.prefix,
    required this.link,
    super.key,
  });

  final bool checked;
  final bool hasError;
  final ValueChanged<bool> onChanged;
  final String prefix;
  final String link;

  @override
  Widget build(BuildContext context) {
    final bodySmall = Theme.of(context).textTheme.bodySmall;
    // TODO(figma): swap for the `check_box_RoundedFill` / `checkbox` SVGs
    // once flutter_svg is added.
    final icon = Icon(
      checked ? Icons.check_box : Icons.check_box_outline_blank,
      size: ConsentCheckboxes.iconSize,
      color: hasError && !checked ? AppColors.fireRed : AppColors.basicBlack,
    );

    return Semantics(
      checked: checked,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!checked),
        child: Row(
          children: [
            icon,
            // Figma: 17px (first row) / 15px (second row) — unified.
            const SizedBox(width: 15),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: bodySmall,
                  children: [
                    TextSpan(text: prefix),
                    TextSpan(
                      text: link,
                      style:
                          AppTypography.withWeight(
                            bodySmall,
                            FontWeight.w600,
                          ).copyWith(
                            color: AppColors.cherryRed,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.cherryRed,
                          ),
                    ),
                    // TODO(legal): make the link open the policy document
                    // (GET /api/v1/legal) once the legal screen exists.
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a transient message for failures the mockup has no inline slot
/// for (no connection, blocked account, server error).
void showAuthSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
