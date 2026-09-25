import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/features/auth/application/reset_password_controller.dart';
import 'package:hoffman/features/auth/data/auth_repository.dart';
import 'package:hoffman/features/auth/domain/auth_exception.dart';
import 'package:hoffman/features/auth/presentation/auth_validators.dart';
import 'package:hoffman/features/auth/presentation/widgets/auth_widgets.dart';

/// Reset password, step 2 of 4 — Figma 139:5304 (`Enter code reset
/// password`). Verifies the 6-digit code; the code can be re-sent once the
/// [resendCooldown] timer runs out.
///
/// Error states: 139:5292 (wrong code), 139:5291 (code expired), 139:5290
/// (too many attempts).
class ResetCodeScreen extends ConsumerStatefulWidget {
  const ResetCodeScreen({super.key});

  static const Duration resendCooldown = Duration(seconds: 59);

  static const Key codeFieldKey = ValueKey('reset-code');
  static const Key submitKey = ValueKey('reset-code-submit');
  static const Key resendKey = ValueKey('reset-code-resend');

  /// Placeholder from the mockup (131:1966).
  static const String codeHint = '___   ___   ___   ___   ___   ___';

  @override
  ConsumerState<ResetCodeScreen> createState() => _ResetCodeScreenState();
}

class _ResetCodeScreenState extends ConsumerState<ResetCodeScreen> {
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
    setState(() => _secondsLeft = ResetCodeScreen.resendCooldown.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) timer.cancel();
      setState(() => _secondsLeft--);
    });
  }

  Future<void> _submit(String email) async {
    FocusScope.of(context).unfocus();
    final code = _code.text;
    setState(() => _codeError = AuthValidators.code(code));
    if (_codeError != null) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyResetCode(email: email, code: code);
      ref.read(resetPasswordControllerProvider.notifier).codeVerified(code);
      if (mounted) await context.push(AppRoutes.forgotPasswordNewPassword);
    } on AuthException catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend(String email) async {
    setState(() => _resending = true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email: email);
      _code.clear();
      setState(() => _codeError = null);
      _startCooldown();
    } on AuthException catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _showError(AuthException e) {
    switch (e.code) {
      case AuthErrorCode.invalidCode || AuthErrorCode.validation:
        setState(() => _codeError = AuthErrorText.invalidCode);
      case AuthErrorCode.codeExpired:
        setState(() => _codeError = AuthErrorText.codeExpired);
      case AuthErrorCode.tooManyAttempts:
        setState(
          () => _codeError = e.retryAfter == null
              ? AuthErrorText.tooManyAttemptsNewCode
              : AuthErrorText.tooManyAttemptsWait(e.retryAfter!),
        );
      case AuthErrorCode.emailNotFound:
        ref
            .read(resetPasswordControllerProvider.notifier)
            .rejectEmail(AuthErrorText.emailNotFound);
        _changeEmail();
      case AuthErrorCode.network:
        showAuthSnackBar(context, AuthErrorText.network);
      case _:
        showAuthSnackBar(context, AuthErrorText.unknown);
    }
  }

  void _changeEmail() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.forgotPassword);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(
      resetPasswordControllerProvider.select((s) => s.email),
    );
    if (email == null) {
      // Opened without step 1 (e.g. a restored route) — start over.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.forgotPassword);
      });
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
        const SizedBox(height: 36),
        AuthFieldSlot(
          height: AuthFieldSlot.unlabeledHeight,
          child: AuthTextField(
            key: ResetCodeScreen.codeFieldKey,
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
            onSubmitted: (_) => _submit(email),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthSubmitButton(
          key: ResetCodeScreen.submitKey,
          label: 'Отправить код',
          loading: _loading,
          onPressed: () => _submit(email),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: _secondsLeft > 0
              ? Text(
                  'Отправить еще раз через $_secondsLeftс',
                  // Figma `Text/Body-13`: Golos Text 13/18.
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    height: 18 / 13,
                  ),
                )
              : AuthLink(
                  key: ResetCodeScreen.resendKey,
                  label: 'Отправить еще раз',
                  onTap: _resending ? null : () => _resend(email),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: AuthLink(label: 'Изменить Email', onTap: _changeEmail),
        ),
      ],
    );
  }
}
