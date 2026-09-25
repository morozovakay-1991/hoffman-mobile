import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/features/auth/application/auth_controller.dart';
import 'package:hoffman/features/auth/domain/auth_exception.dart';
import 'package:hoffman/features/auth/presentation/auth_validators.dart';
import 'package:hoffman/features/auth/presentation/widgets/auth_widgets.dart';

/// Registration, Figma node 139:5311 (`Registration`).
///
/// The mockup only has Email and Пароль. "Имя" is added because the backend
/// requires `name`, and "Повторите пароль" because the flow must show the
/// 139:5284 "Пароли не совпадают" state; both reuse the mockup's field style.
///
/// Error states: 139:5297 (email format), 139:5296 (email taken), 139:5286
/// (password format), 139:5284 (passwords differ), 139:5285 (consents).
/// On success the router moves to `/verification`.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  static const Key nameFieldKey = ValueKey('register-name');
  static const Key emailFieldKey = ValueKey('register-email');
  static const Key passwordFieldKey = ValueKey('register-password');
  static const Key confirmationFieldKey = ValueKey('register-confirmation');
  static const Key submitKey = ValueKey('register-submit');

  /// Figma button width (131:1859).
  static const double submitWidth = 140;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  bool _privacyAccepted = false;
  bool _personalDataAccepted = false;
  bool _loading = false;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmationError;
  String? _consentError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  bool get _hasErrors =>
      _nameError != null ||
      _emailError != null ||
      _passwordError != null ||
      _confirmationError != null ||
      _consentError != null;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _nameError = AuthValidators.name(_name.text);
      _emailError = AuthValidators.email(_email.text);
      _passwordError = AuthValidators.newPassword(_password.text);
      _confirmationError = _passwordError == null
          ? AuthValidators.passwordConfirmation(
              _password.text,
              _confirmation.text,
            )
          : null;
      _consentError = _privacyAccepted && _personalDataAccepted
          ? null
          : AuthErrorText.consentRequired;
    });
    if (_hasErrors) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            passwordConfirmation: _confirmation.text,
          );
      if (mounted) context.go(AppRoutes.verification);
    } on AuthException catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(AuthException e) {
    switch (e.code) {
      case AuthErrorCode.emailTaken:
        setState(() => _emailError = AuthErrorText.emailTaken);
      case AuthErrorCode.validation:
        setState(() {
          if (e.fields.containsKey('name')) {
            _nameError = AuthErrorText.nameRequired;
          }
          if (e.fields.containsKey('email')) {
            _emailError = AuthErrorText.emailInvalid;
          }
          if (e.fields.containsKey('password')) {
            _passwordError = AuthErrorText.passwordFormat;
          }
        });
      case AuthErrorCode.tooManyAttempts:
        showAuthSnackBar(
          context,
          AuthErrorText.tooManyAttemptsWait(
            e.retryAfter ?? const Duration(minutes: 1),
          ),
        );
      case AuthErrorCode.network:
        showAuthSnackBar(context, AuthErrorText.network);
      case _:
        showAuthSnackBar(context, AuthErrorText.unknown);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      children: [
        const HoffmanWordmark(),
        const SizedBox(height: AppSpacing.xl),
        const AuthHeading(title: 'Регистрация', subtitle: 'Создайте аккаунт'),
        const SizedBox(height: 40),
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthFieldSlot(
                child: AuthTextField(
                  key: RegisterScreen.nameFieldKey,
                  label: 'Имя',
                  controller: _name,
                  errorText: _nameError,
                  keyboardType: TextInputType.name,
                  autofillHints: const [AutofillHints.name],
                  onChanged: (_) => setState(() => _nameError = null),
                ),
              ),
              AuthFieldSlot(
                child: AuthTextField(
                  key: RegisterScreen.emailFieldKey,
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
                  key: RegisterScreen.passwordFieldKey,
                  label: 'Пароль',
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
                  key: RegisterScreen.confirmationFieldKey,
                  label: 'Повторите пароль',
                  controller: _confirmation,
                  errorText: _confirmationError,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (_) => setState(() => _confirmationError = null),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthSubmitButton(
          key: RegisterScreen.submitKey,
          label: 'Зарегистрироваться',
          width: RegisterScreen.submitWidth,
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
        Center(
          child: AuthSwitchPrompt(
            question: 'Есть аккаунт?',
            action: 'Войти',
            onTap: () => context.go(AppRoutes.login),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
