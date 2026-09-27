import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/profile/application/email_change_controller.dart';
import 'package:hoffman/features/profile/application/profile_controller.dart';
import 'package:hoffman/features/profile/data/profile_repository.dart';
import 'package:hoffman/features/profile/presentation/widgets/profile_widgets.dart';

/// "Email" — Figma 642:3504. `PATCH /profile/email` sends a one-time code to
/// the new address, then the code screen (848:1330) confirms the change;
/// the email is not changed until then.
class EditEmailScreen extends ConsumerStatefulWidget {
  const EditEmailScreen({super.key});

  static const Key emailFieldKey = ValueKey('profile-email');
  static const Key submitKey = ValueKey('profile-email-submit');

  /// Placeholder until the current email is known (651:4311).
  static const String emailHint = 'example@gmail.com';

  @override
  ConsumerState<EditEmailScreen> createState() => _EditEmailScreenState();
}

class _EditEmailScreenState extends ConsumerState<EditEmailScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  String? _emailError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    final current = ref.read(currentProfileProvider).value?.email;
    setState(() {
      _emailError =
          AuthValidators.email(email) ??
          (current != null && current.toLowerCase() == email.toLowerCase()
              ? ProfileText.sameEmail
              : null);
    });
    if (_emailError != null) return;

    setState(() => _loading = true);
    try {
      await ref.read(profileRepositoryProvider).requestEmailChange(email);
      ref.read(emailChangeControllerProvider.notifier).codeSent(email);
      if (!mounted) return;
      final changed = await context.push<bool>(AppRoutes.profileEmailCode);
      if (changed != true || !mounted) return;
      ref.read(emailChangeControllerProvider.notifier).reset();
      showAuthSnackBar(context, ProfileText.emailChanged);
      ProfileScaffold.popOrGo(context, AppRoutes.profilePersonalData);
    } on ApiException catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(ApiException e) {
    switch (e.code) {
      case 'EMAIL_TAKEN':
        setState(() => _emailError = AuthErrorText.emailTaken);
      case 'VALIDATION_ERROR' when e.fields.containsKey('new_email'):
        setState(() => _emailError = AuthErrorText.emailInvalid);
      case _:
        showAuthSnackBar(context, ProfileText.of(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = ref.watch(currentProfileProvider).value?.email;

    return ProfileScaffold(
      onBack: () =>
          ProfileScaffold.popOrGo(context, AppRoutes.profilePersonalData),
      children: [
        const ProfileFormTitle('Email'),
        ProfileScaffold.padded(
          AuthFieldSlot(
            child: AuthTextField(
              key: EditEmailScreen.emailFieldKey,
              label: 'Email',
              hintText: currentEmail ?? EditEmailScreen.emailHint,
              controller: _email,
              errorText: _emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onChanged: (_) => setState(() => _emailError = null),
              onSubmitted: (_) => _submit(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ProfileScaffold.padded(
          AuthSubmitButton(
            key: EditEmailScreen.submitKey,
            label: 'Сохранить',
            loading: _loading,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
