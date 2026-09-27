import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/profile/application/profile_controller.dart';
import 'package:hoffman/features/profile/presentation/widgets/profile_widgets.dart';

/// "Имя пользователя" — Figma 642:3475. Saves with `PATCH /profile` and
/// returns to "Личные данные".
///
/// The field starts with the current name once the profile has loaded; the
/// form works without it (e.g. offline the save reports the failure).
class EditNameScreen extends ConsumerStatefulWidget {
  const EditNameScreen({super.key});

  static const Key nameFieldKey = ValueKey('profile-name');
  static const Key submitKey = ValueKey('profile-name-submit');

  /// Backend `UpdateProfileRequest` limit.
  static const int nameMaxLength = 255;

  @override
  ConsumerState<EditNameScreen> createState() => _EditNameScreenState();
}

class _EditNameScreenState extends ConsumerState<EditNameScreen> {
  final _name = TextEditingController();
  bool _edited = false;
  bool _loading = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    ref.listenManual(currentProfileProvider, (_, next) {
      final profile = next.value;
      if (profile != null && !_edited) _name.text = profile.name;
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _nameError = AuthValidators.name(_name.text));
    if (_nameError != null) return;
    // Signed out meanwhile: the router is already leaving this screen.
    final userId = ref.read(signedInUserIdProvider);
    if (userId == null) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(profileControllerProvider(userId).notifier)
          .updateName(_name.text.trim());
      if (!mounted) return;
      showAuthSnackBar(context, ProfileText.nameSaved);
      ProfileScaffold.popOrGo(context, AppRoutes.profilePersonalData);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'VALIDATION_ERROR' && e.fields.containsKey('name')) {
        setState(() => _nameError = AuthErrorText.checkField);
      } else {
        showAuthSnackBar(context, ProfileText.of(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileScaffold(
      onBack: () =>
          ProfileScaffold.popOrGo(context, AppRoutes.profilePersonalData),
      children: [
        const ProfileFormTitle('Имя пользователя'),
        ProfileScaffold.padded(
          AuthFieldSlot(
            child: AuthTextField(
              key: EditNameScreen.nameFieldKey,
              label: 'Имя',
              controller: _name,
              errorText: _nameError,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.name],
              inputFormatters: [
                LengthLimitingTextInputFormatter(EditNameScreen.nameMaxLength),
              ],
              onChanged: (_) => setState(() {
                _edited = true;
                _nameError = null;
              }),
              onSubmitted: (_) => _submit(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ProfileScaffold.padded(
          AuthSubmitButton(
            key: EditNameScreen.submitKey,
            label: 'Сохранить',
            loading: _loading,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
