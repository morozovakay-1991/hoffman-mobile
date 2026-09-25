import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Data carried across the four reset-password steps.
@immutable
class ResetPasswordState {
  const ResetPasswordState({this.email, this.code, this.emailError});

  /// Set once step 1 has sent the code.
  final String? email;

  /// Set once step 2 has verified it.
  final String? code;

  /// An error for step 1 raised by a later step — the backend only reports
  /// an unknown email (139:5293) from `verify-code`, not from `forgot`.
  final String? emailError;
}

class ResetPasswordController extends Notifier<ResetPasswordState> {
  @override
  ResetPasswordState build() => const ResetPasswordState();

  void codeSent(String email) => state = ResetPasswordState(email: email);

  void codeVerified(String code) =>
      state = ResetPasswordState(email: state.email, code: code);

  /// Sends the user back to step 1 with [message] under the email field.
  void rejectEmail(String message) =>
      state = ResetPasswordState(emailError: message);

  void clearEmailError() =>
      state = ResetPasswordState(email: state.email, code: state.code);

  void reset() => state = const ResetPasswordState();
}

final resetPasswordControllerProvider =
    NotifierProvider<ResetPasswordController, ResetPasswordState>(
      ResetPasswordController.new,
    );
