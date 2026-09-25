import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/config/feature_flags.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/features/auth/application/auth_controller.dart';
import 'package:hoffman/features/auth/domain/auth_exception.dart';
import 'package:hoffman/features/auth/presentation/auth_validators.dart';
import 'package:hoffman/features/auth/presentation/widgets/auth_widgets.dart';

/// Login, Figma node 139:5312 (`Autorisation`).
///
/// Error states: 139:5287 (required fields), 139:5297 (email format),
/// 139:5298 (wrong password), 139:5285 (consents not accepted). The sign-up
/// prompt is hidden when the `registration_enabled` flag is off.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const Key emailFieldKey = ValueKey('login-email');
  static const Key passwordFieldKey = ValueKey('login-password');
  static const Key submitKey = ValueKey('login-submit');

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _privacyAccepted = false;
  bool _personalDataAccepted = false;
  bool _loading = false;

  String? _emailError;
  String? _passwordError;
  String? _consentError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _emailError = AuthValidators.email(_email.text);
      _passwordError = AuthValidators.requiredPassword(_password.text);
      _consentError = _privacyAccepted && _personalDataAccepted
          ? null
          : AuthErrorText.consentRequired;
    });
    if (_emailError != null ||
        _passwordError != null ||
        _consentError != null) {
      return;
    }

    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(email: _email.text.trim(), password: _password.text);
      if (mounted) context.go(AppRoutes.home);
    } on AuthException catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(AuthException e) {
    switch (e.code) {
      case AuthErrorCode.invalidCredentials:
        setState(() => _passwordError = AuthErrorText.invalidCredentials);
      case AuthErrorCode.validation when e.fields.containsKey('email'):
        setState(() => _emailError = AuthErrorText.emailInvalid);
      case AuthErrorCode.tooManyAttempts:
        showAuthSnackBar(
          context,
          AuthErrorText.tooManyAttemptsWait(
            e.retryAfter ?? const Duration(minutes: 1),
          ),
        );
      case AuthErrorCode.accountBlocked:
        showAuthSnackBar(context, AuthErrorText.accountBlocked);
      case AuthErrorCode.network:
        showAuthSnackBar(context, AuthErrorText.network);
      case _:
        showAuthSnackBar(context, AuthErrorText.unknown);
    }
  }

  @override
  Widget build(BuildContext context) {
    final registrationEnabled =
        ref.watch(registrationEnabledProvider).value ?? true;

    return AuthScaffold(
      children: [
        const HoffmanWordmark(),
        const SizedBox(height: AppSpacing.xl),
        const AuthHeading(
          title: 'Авторизация',
          subtitle: 'Пожалуйста, войдите в свой аккаунт',
        ),
        const SizedBox(height: 40),
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthFieldSlot(
                child: AuthTextField(
                  key: LoginScreen.emailFieldKey,
                  label: 'Email',
                  hintText: 'example@gmail.com',
                  controller: _email,
                  errorText: _emailError,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  onChanged: (_) => setState(() => _emailError = null),
                ),
              ),
              AuthFieldSlot(
                child: AuthTextField(
                  key: LoginScreen.passwordFieldKey,
                  label: 'Пароль',
                  controller: _password,
                  errorText: _passwordError,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onChanged: (_) => setState(() => _passwordError = null),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: AuthLink(
            label: 'Забыли пароль?',
            onTap: () => context.push(AppRoutes.forgotPassword),
          ),
        ),
        const SizedBox(height: 64),
        AuthSubmitButton(
          key: LoginScreen.submitKey,
          label: 'Войти',
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
        const SizedBox(height: 42),
        const Center(child: HiddenSocialSignIn()),
        const SizedBox(height: AppSpacing.lg),
        if (registrationEnabled)
          Center(
            child: AuthSwitchPrompt(
              question: 'Нет аккаунта?',
              action: 'Зарегистрируйтесь',
              onTap: () => context.go(AppRoutes.register),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
