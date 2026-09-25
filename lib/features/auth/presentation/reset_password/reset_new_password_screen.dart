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

/// Reset password, step 3 of 4 — Figma 139:5302 (`New password`).
///
/// Error states: 139:5286 wording for the password format, 139:5284
/// (passwords differ).
class ResetNewPasswordScreen extends ConsumerStatefulWidget {
  const ResetNewPasswordScreen({super.key});

  static const Key passwordFieldKey = ValueKey('reset-new-password');
  static const Key confirmationFieldKey = ValueKey('reset-confirmation');
  static const Key submitKey = ValueKey('reset-new-password-submit');

  @override
  ConsumerState<ResetNewPasswordScreen> createState() =>
      _ResetNewPasswordScreenState();
}

class _ResetNewPasswordScreenState
    extends ConsumerState<ResetNewPasswordScreen> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _loading = false;
  String? _passwordError;
  String? _confirmationError;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit(String email, String code) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _passwordError = AuthValidators.newPassword(_password.text);
      _confirmationError = _passwordError == null
          ? AuthValidators.passwordConfirmation(
              _password.text,
              _confirmation.text,
            )
          : null;
    });
    if (_passwordError != null || _confirmationError != null) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(
            email: email,
            code: code,
            password: _password.text,
            passwordConfirmation: _confirmation.text,
          );
      // The flow state is cleared by ResetDoneScreen: clearing it here would
      // make the steps still on the stack bounce back to step 1.
      if (mounted) context.go(AppRoutes.forgotPasswordDone);
    } on AuthException catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(AuthException e) {
    switch (e.code) {
      case AuthErrorCode.validation when e.fields.containsKey('password'):
        setState(() => _passwordError = AuthErrorText.passwordFormat);
      // The verified code went stale meanwhile: back to step 2 for a new one.
      case AuthErrorCode.codeExpired:
        showAuthSnackBar(context, AuthErrorText.codeExpired);
        context.pop();
      case AuthErrorCode.invalidCode || AuthErrorCode.tooManyAttempts:
        showAuthSnackBar(context, AuthErrorText.tooManyAttemptsNewCode);
        context.pop();
      case AuthErrorCode.network:
        showAuthSnackBar(context, AuthErrorText.network);
      case _:
        showAuthSnackBar(context, AuthErrorText.unknown);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(resetPasswordControllerProvider);
    final email = flow.email;
    final code = flow.code;
    if (email == null || code == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.forgotPassword);
      });
      return const Scaffold(backgroundColor: AppColors.background);
    }

    return AuthScaffold(
      top: AuthBackBar(onBack: () => context.pop()),
      children: [
        const SizedBox(height: AppSpacing.xl),
        const AuthHeading(
          title: 'Новый пароль',
          subtitle: 'Придумайте новый надежный пароль для вашего аккаунта.',
        ),
        const SizedBox(height: 36),
        AuthFieldSlot(
          child: AuthTextField(
            key: ResetNewPasswordScreen.passwordFieldKey,
            label: 'Новый пароль',
            hintText: AuthErrorText.passwordFormat,
            controller: _password,
            errorText: _passwordError,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) => setState(() => _passwordError = null),
          ),
        ),
        AuthFieldSlot(
          child: AuthTextField(
            key: ResetNewPasswordScreen.confirmationFieldKey,
            label: 'Повторите пароль',
            controller: _confirmation,
            errorText: _confirmationError,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) => setState(() => _confirmationError = null),
            onSubmitted: (_) => _submit(email, code),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthSubmitButton(
          key: ResetNewPasswordScreen.submitKey,
          label: 'Сохранить',
          loading: _loading,
          onPressed: () => _submit(email, code),
        ),
      ],
    );
  }
}
