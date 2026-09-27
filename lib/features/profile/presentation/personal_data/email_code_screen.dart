import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// "Введите код" for a new email — Figma 848:1330. Confirms the change with
/// `POST /profile/email/confirm`; "Отправить еще раз" repeats
/// `PATCH /profile/email`, which replaces the pending code.
///
/// Pops with `true` once the email has changed ("Изменить Email" and back
/// pop with nothing), so the email screen can close as well.
class EmailCodeScreen extends ConsumerStatefulWidget {
  const EmailCodeScreen({super.key});

  static const Duration resendCooldown = ResetCodeScreen.resendCooldown;

  static const Key codeFieldKey = ValueKey('profile-email-code');
  static const Key submitKey = ValueKey('profile-email-code-submit');
  static const Key resendKey = ValueKey('profile-email-code-resend');
  static const Key changeEmailKey = ValueKey('profile-email-code-change');

  @override
  ConsumerState<EmailCodeScreen> createState() => _EmailCodeScreenState();
}

class _EmailCodeScreenState extends ConsumerState<EmailCodeScreen> {
  final _code = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 0;
  bool _loading = false;
  bool _resending = false;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = EmailCodeScreen.resendCooldown.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) timer.cancel();
      setState(() => _secondsLeft--);
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final code = _code.text;
    setState(() => _codeError = AuthValidators.code(code));
    if (_codeError != null) return;
    final userId = ref.read(signedInUserIdProvider);
    if (userId == null) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(profileControllerProvider(userId).notifier)
          .confirmEmailChange(code);
      // The email screen clears the pending email once this one has popped.
      if (!mounted) return;
      if (context.canPop()) {
        context.pop(true);
      } else {
        showAuthSnackBar(context, ProfileText.emailChanged);
        context.go(AppRoutes.profilePersonalData);
      }
    } on ApiException catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend(String email) async {
    setState(() => _resending = true);
    try {
      await ref.read(profileRepositoryProvider).requestEmailChange(email);
      _code.clear();
      setState(() => _codeError = null);
      _startCooldown();
    } on ApiException catch (e) {
      if (!mounted) return;
      showAuthSnackBar(
        context,
        e.code == 'EMAIL_TAKEN' ? AuthErrorText.emailTaken : ProfileText.of(e),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _showError(ApiException e) {
    if (e.isRateLimited) {
      setState(
        () => _codeError = AuthErrorText.tooManyAttemptsWait(
          e.retryAfter ?? const Duration(minutes: 1),
        ),
      );
      return;
    }
    switch (e.code) {
      case 'INVALID_CODE' || 'VALIDATION_ERROR':
        setState(() => _codeError = AuthErrorText.invalidCode);
      case 'CODE_EXPIRED':
        setState(() => _codeError = AuthErrorText.codeExpired);
      // Locked until a new code is requested.
      case 'TOO_MANY_ATTEMPTS':
        setState(() => _codeError = AuthErrorText.tooManyAttemptsNewCode);
      case _:
        showAuthSnackBar(context, ProfileText.of(e));
    }
  }

  void _changeEmail() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.profileEmail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(emailChangeControllerProvider);
    if (email == null) {
      // Opened without the email step (e.g. a restored route) — start over.
      // Not while popping: the email screen clears the email on success.
      final leaving = !(ModalRoute.of(context)?.isCurrent ?? true);
      if (!leaving) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(AppRoutes.profileEmail);
        });
      }
      return const Scaffold(backgroundColor: AppColors.background);
    }

    final textTheme = Theme.of(context).textTheme;
    return AuthScaffold(
      top: AuthBackBar(onBack: _changeEmail),
      children: [
        const SizedBox(height: AppSpacing.xl),
        AuthHeading(
          title: 'Введите код',
          subtitle: 'Мы отправили 6-значный код на $email',
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthFieldSlot(
          height: AuthFieldSlot.unlabeledHeight,
          child: AuthTextField(
            key: EmailCodeScreen.codeFieldKey,
            controller: _code,
            hintText: ResetCodeScreen.codeHint,
            errorText: _codeError,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (_) => setState(() => _codeError = null),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthSubmitButton(
          key: EmailCodeScreen.submitKey,
          label: 'Отправить код',
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: _secondsLeft > 0
              ? Text(
                  'Отправить еще раз через $_secondsLeftс',
                  // Figma `Text/Body-13`: Golos Text 13/18, softBlack.
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    height: 18 / 13,
                    color: AppColors.softBlack,
                  ),
                )
              : AuthLink(
                  key: EmailCodeScreen.resendKey,
                  label: 'Отправить еще раз',
                  onTap: _resending ? null : () => _resend(email),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: AuthLink(
            key: EmailCodeScreen.changeEmailKey,
            label: 'Изменить Email',
            onTap: _changeEmail,
            // 848:1346 underlines the link, unlike the reset-password one.
            style: AuthLink.linkStyle(context).copyWith(
              decoration: TextDecoration.underline,
              decorationColor: AppColors.cherryRed,
            ),
          ),
        ),
      ],
    );
  }
}
