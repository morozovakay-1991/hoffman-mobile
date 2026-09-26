import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/features/auth/application/verification_controller.dart';
import 'package:hoffman/features/auth/domain/auth_exception.dart';
import 'package:hoffman/features/auth/domain/verification_request.dart';
import 'package:hoffman/features/auth/presentation/auth_validators.dart';
import 'package:hoffman/features/auth/presentation/widgets/auth_widgets.dart';

/// "Данные выпускника" — Figma 139:5303 (`Graduate info regidtratiom`).
///
/// Sends last name, first name and phone to `POST /verification/submit`,
/// then shows "Статус подтвержден" (139:5307) for a `confirmed` result or
/// "Статус не подтвержден" (139:5306) otherwise. The fields start with the
/// data of the user's previous request, so "Попробовать снова" only needs a
/// correction.
class GraduateFormScreen extends ConsumerStatefulWidget {
  const GraduateFormScreen({super.key});

  static const Key lastNameFieldKey = ValueKey('graduate-last-name');
  static const Key firstNameFieldKey = ValueKey('graduate-first-name');
  static const Key phoneFieldKey = ValueKey('graduate-phone');
  static const Key submitKey = ValueKey('graduate-submit');

  /// The phone slot also holds the two-line hint below the input (the
  /// button sits 164px below the phone label in the mockup).
  static const double phoneSlotHeight = 132;

  // Backend `SubmitVerificationRequest` limits.
  static const int nameMaxLength = 255;
  static const int phoneMaxLength = 32;

  @override
  ConsumerState<GraduateFormScreen> createState() => _GraduateFormScreenState();
}

class _GraduateFormScreenState extends ConsumerState<GraduateFormScreen> {
  final _lastName = TextEditingController();
  final _firstName = TextEditingController();
  final _phone = TextEditingController();

  bool _privacyAccepted = false;
  bool _personalDataAccepted = false;
  bool _loading = false;
  bool _edited = false;

  String? _lastNameError;
  String? _firstNameError;
  String? _phoneError;
  String? _consentError;

  @override
  void initState() {
    super.initState();
    // Also keeps the request loaded while the form is open; the first
    // `GET /verification/status` may still be in flight.
    ref.listenManual(
      currentVerificationProvider,
      (_, next) => _prefill(next.value),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _lastName.dispose();
    _firstName.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// Fills the form from the previous request until the user types.
  void _prefill(VerificationRequest? previous) {
    if (previous == null || _edited) return;
    _lastName.text = previous.lastName;
    _firstName.text = previous.firstName;
    _phone.text = previous.phone;
  }

  bool get _hasErrors =>
      _lastNameError != null ||
      _firstNameError != null ||
      _phoneError != null ||
      _consentError != null;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _lastNameError = AuthValidators.lastName(_lastName.text);
      _firstNameError = AuthValidators.name(_firstName.text);
      _phoneError = AuthValidators.phone(_phone.text);
      _consentError = _privacyAccepted && _personalDataAccepted
          ? null
          : AuthErrorText.consentRequired;
    });
    if (_hasErrors) return;
    // Signed out meanwhile: the router is already leaving this screen.
    final userId = ref.read(signedInUserIdProvider);
    if (userId == null) return;

    setState(() => _loading = true);
    try {
      final request = await ref
          .read(verificationControllerProvider(userId).notifier)
          .submit(
            lastName: _lastName.text.trim(),
            firstName: _firstName.text.trim(),
            phone: _phone.text.trim(),
          );
      if (!mounted) return;
      context.go(
        request.isConfirmed
            ? AppRoutes.verificationConfirmed
            : AppRoutes.verificationNotConfirmed,
      );
    } on AuthException catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(AuthException e) {
    switch (e.code) {
      case AuthErrorCode.validation:
        setState(() {
          if (e.fields.containsKey('last_name')) {
            _lastNameError = AuthErrorText.checkField;
          }
          if (e.fields.containsKey('first_name')) {
            _firstNameError = AuthErrorText.checkField;
          }
          if (e.fields.containsKey('phone')) {
            _phoneError = AuthErrorText.checkField;
          }
        });
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

  void _onEdited(VoidCallback clearError) {
    _edited = true;
    setState(clearError);
  }

  @override
  Widget build(BuildContext context) {
    final nameLimit = [
      LengthLimitingTextInputFormatter(GraduateFormScreen.nameMaxLength),
    ];

    return AuthScaffold(
      top: AuthBackBar(
        onBack: () => context.canPop()
            ? context.pop()
            : context.go(AppRoutes.verification),
      ),
      children: [
        const SizedBox(height: AppSpacing.xl),
        const AuthHeading(
          title: 'Данные выпускника',
          subtitle:
              'Пожалуйста, заполните информацию для подтверждения '
              'прохождения Процесса.',
          subtitleFontSize: 13,
        ),
        const SizedBox(height: 40),
        AuthFieldSlot(
          child: AuthTextField(
            key: GraduateFormScreen.lastNameFieldKey,
            label: 'Фамилия',
            controller: _lastName,
            errorText: _lastNameError,
            keyboardType: TextInputType.name,
            autofillHints: const [AutofillHints.familyName],
            inputFormatters: nameLimit,
            onChanged: (_) => _onEdited(() => _lastNameError = null),
          ),
        ),
        AuthFieldSlot(
          child: AuthTextField(
            key: GraduateFormScreen.firstNameFieldKey,
            label: 'Имя',
            controller: _firstName,
            errorText: _firstNameError,
            keyboardType: TextInputType.name,
            autofillHints: const [AutofillHints.givenName],
            inputFormatters: nameLimit,
            onChanged: (_) => _onEdited(() => _firstNameError = null),
          ),
        ),
        AuthFieldSlot(
          height: GraduateFormScreen.phoneSlotHeight,
          child: AuthTextField(
            key: GraduateFormScreen.phoneFieldKey,
            label: 'Номер телефона',
            helperText:
                'Введите номер телефона, который указывали при прохождении '
                'Процесса Хоффмана',
            controller: _phone,
            errorText: _phoneError,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                GraduateFormScreen.phoneMaxLength,
              ),
            ],
            onChanged: (_) => _onEdited(() => _phoneError = null),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthSubmitButton(
          key: GraduateFormScreen.submitKey,
          label: 'Далее',
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
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
