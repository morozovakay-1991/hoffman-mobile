import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/profile/data/profile_repository.dart';
import 'package:hoffman/features/profile/presentation/widgets/profile_widgets.dart';

/// "Пароль" — Figma 642:3533. `PATCH /profile/password` with the old and
/// the new password; the repeat is checked on the device only.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  static const Key oldPasswordFieldKey = ValueKey('profile-old-password');
  static const Key passwordFieldKey = ValueKey('profile-new-password');
  static const Key confirmationFieldKey = ValueKey('profile-confirmation');
  static const Key submitKey = ValueKey('profile-password-submit');

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _oldPassword = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _loading = false;
  String? _oldPasswordError;
  String? _passwordError;
  String? _confirmationError;

  @override
  void dispose() {
    _oldPassword.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _oldPasswordError = AuthValidators.requiredPassword(_oldPassword.text);
      _passwordError = AuthValidators.newPassword(_password.text);
      _confirmationError = _passwordError == null
          ? AuthValidators.passwordConfirmation(
              _password.text,
              _confirmation.text,
            )
          : null;
    });
    if (_oldPasswordError != null ||
        _passwordError != null ||
        _confirmationError != null) {
      return;
    }

    setState(() => _loading = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updatePassword(
            oldPassword: _oldPassword.text,
            password: _password.text,
          );
      if (!mounted) return;
      showAuthSnackBar(context, ProfileText.passwordChanged);
      ProfileScaffold.popOrGo(context, AppRoutes.profilePersonalData);
    } on ApiException catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(ApiException e) {
    switch (e.code) {
      case 'INVALID_OLD_PASSWORD':
        setState(() => _oldPasswordError = ProfileText.invalidOldPassword);
      case 'VALIDATION_ERROR' when e.fields.containsKey('password'):
        setState(() => _passwordError = AuthErrorText.passwordFormat);
      case 'VALIDATION_ERROR' when e.fields.containsKey('old_password'):
        setState(() => _oldPasswordError = AuthErrorText.passwordRequired);
      case _:
        showAuthSnackBar(context, ProfileText.of(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileScaffold(
      onBack: () =>
          ProfileScaffold.popOrGo(context, AppRoutes.profilePersonalData),
      children: [
        const ProfileFormTitle('Пароль'),
        ProfileScaffold.padded(
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthFieldSlot(
                  child: AuthTextField(
                    key: ChangePasswordScreen.oldPasswordFieldKey,
                    label: 'Старый пароль',
                    controller: _oldPassword,
                    errorText: _oldPasswordError,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    onChanged: (_) => setState(() => _oldPasswordError = null),
                  ),
                ),
                AuthFieldSlot(
                  child: AuthTextField(
                    key: ChangePasswordScreen.passwordFieldKey,
                    label: 'Новый пароль',
                    controller: _password,
                    errorText: _passwordError,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    onChanged: (_) => setState(() => _passwordError = null),
                  ),
                ),
                AuthFieldSlot(
                  child: AuthTextField(
                    key: ChangePasswordScreen.confirmationFieldKey,
                    label: 'Повторите новый пароль',
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
        ),
        const SizedBox(height: AppSpacing.xl),
        ProfileScaffold.padded(
          AuthSubmitButton(
            key: ChangePasswordScreen.submitKey,
            label: 'Сохранить',
            loading: _loading,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
