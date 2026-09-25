import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/features/auth/application/reset_password_controller.dart';
import 'package:hoffman/features/auth/data/auth_repository.dart';
import 'package:hoffman/features/auth/domain/auth_exception.dart';
import 'package:hoffman/features/auth/presentation/auth_validators.dart';
import 'package:hoffman/features/auth/presentation/widgets/auth_widgets.dart';

/// Reset password, step 1 of 4 — Figma 139:5305 (`Autorisation reset
/// password`). Sends the 6-digit code to the entered email.
///
/// Error states: 139:5295 (email required), 139:5294 (email format),
/// 139:5293 (email not registered — reported by step 2's `verify-code`).
class ResetEmailScreen extends ConsumerStatefulWidget {
  const ResetEmailScreen({super.key});

  static const Key emailFieldKey = ValueKey('reset-email');
  static const Key submitKey = ValueKey('reset-email-submit');

  @override
  ConsumerState<ResetEmailScreen> createState() => _ResetEmailScreenState();
}

class _ResetEmailScreenState extends ConsumerState<ResetEmailScreen> {
  late final TextEditingController _email = TextEditingController(
    text: ref.read(resetPasswordControllerProvider).email,
  );

  bool _privacyAccepted = false;
  bool _personalDataAccepted = false;
  bool _loading = false;
  String? _emailError;
  String? _consentError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    ref.read(resetPasswordControllerProvider.notifier).clearEmailError();
    setState(() {
      _emailError = AuthValidators.email(_email.text);
      _consentError = _privacyAccepted && _personalDataAccepted
          ? null
          : AuthErrorText.consentRequired;
    });
    if (_emailError != null || _consentError != null) return;

    final email = _email.text.trim();
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email: email);
      ref.read(resetPasswordControllerProvider.notifier).codeSent(email);
      if (mounted) await context.push(AppRoutes.forgotPasswordCode);
    } on AuthException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case AuthErrorCode.validation:
          setState(() => _emailError = AuthErrorText.emailInvalid);
        case AuthErrorCode.network:
          showAuthSnackBar(context, AuthErrorText.network);
        case _:
          showAuthSnackBar(context, AuthErrorText.unknown);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingError = ref.watch(
      resetPasswordControllerProvider.select((s) => s.emailError),
    );

    return AuthScaffold(
      top: AuthBackBar(
        onBack: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.login),
      ),
      children: [
        const SizedBox(height: AppSpacing.xl),
        const AuthHeading(
          title: 'Сбросить пароль',
          subtitle: 'Мы отправим инструкцию для сброса пароля на ваш email',
        ),
        const SizedBox(height: 40),
        AuthFieldSlot(
          child: AuthTextField(
            key: ResetEmailScreen.emailFieldKey,
            label: 'Email',
            hintText: 'example@gmail.com',
            controller: _email,
            errorText: _emailError ?? pendingError,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) {
              ref
                  .read(resetPasswordControllerProvider.notifier)
                  .clearEmailError();
              setState(() => _emailError = null);
            },
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthSubmitButton(
          key: ResetEmailScreen.submitKey,
          label: 'Отправить код',
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.md),
        ConsentCheckboxes(
          privacyAccepted: _privacyAccepted,
          personalDataAccepted: _personalDataAccepted,
          errorText: _consentError,
          onPrivacyChanged: (v) => setState(() {
            _privacyAccepted = v;
            _consentError = null;
          }),
          onPersonalDataChanged: (v) => setState(() {
            _personalDataAccepted = v;
            _consentError = null;
          }),
        ),
      ],
    );
  }
}
