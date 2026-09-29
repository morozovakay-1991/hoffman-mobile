import 'package:hoffman/core/router/app_routes.dart';

/// Where the graduate verification screens were entered from; decides the
/// routes they lead to.
enum VerificationFlow {
  /// Right after registration (`/verification…`): full screen, outside the
  /// tab shell. Starts on the "Вы выпускник?" question.
  registration(
    form: AppRoutes.verificationForm,
    confirmed: AppRoutes.verificationConfirmed,
    notConfirmed: AppRoutes.verificationNotConfirmed,
    formFallback: AppRoutes.verification,
  ),

  /// A retry from the profile, ТЗ 5.2.4 (`/profile/verification…`, Figma
  /// "Профиль" 131:2453 / 131:2408 / 131:2429): inside the tab shell, with
  /// the bar. Starts on the form — the profile block already asks the
  /// question.
  profile(
    form: AppRoutes.profileVerification,
    confirmed: AppRoutes.profileVerificationConfirmed,
    notConfirmed: AppRoutes.profileVerificationNotConfirmed,
    formFallback: AppRoutes.profile,
  );

  VerificationFlow({
    required this.form,
    required this.confirmed,
    required this.notConfirmed,
    required this.formFallback,
  });

  final String form;
  final String confirmed;
  final String notConfirmed;

  /// Where back on the form leads with nothing to pop (a deep link, or the
  /// form reopened with `go` by "Попробовать снова").
  final String formFallback;
}
