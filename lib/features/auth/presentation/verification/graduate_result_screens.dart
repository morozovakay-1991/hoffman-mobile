import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/config/feature_flags.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/services/external_url_launcher.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/presentation/widgets/auth_widgets.dart';

/// Gap between the heading and the buttons in 139:5307 / 139:5306.
const double _buttonsTop = 68;

/// Button width in 139:5306.
const double _wideButtonWidth = 232;

/// "Статус подтвержден" — Figma 139:5307 (139:5308 is an identical copy).
class GraduateConfirmedScreen extends StatelessWidget {
  const GraduateConfirmedScreen({super.key});

  static const Key homeKey = ValueKey('graduate-confirmed-home');

  /// Figma subtitle width (131:1904).
  static const double subtitleWidth = 296;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      children: [
        const AuthHeading(
          title: 'Статус подтвержден',
          subtitle:
              'Теперь вы имеете доступ к расширенному функционалу приложения',
          largeSubtitle: true,
          subtitleMaxWidth: subtitleWidth,
        ),
        const SizedBox(height: _buttonsTop),
        AuthSubmitButton(
          key: homeKey,
          label: 'На главную',
          onPressed: () => context.go(AppRoutes.home),
        ),
      ],
    );
  }
}

/// "Статус не подтвержден" — Figma 139:5306. Shown while the request waits
/// for manual review (`pending`) or after it was `rejected`.
class GraduateNotConfirmedScreen extends ConsumerWidget {
  const GraduateNotConfirmedScreen({super.key});

  static const Key retryKey = ValueKey('graduate-retry');
  static const Key contactAdminKey = ValueKey('graduate-contact-admin');

  /// Not in the mockup: the administrator link could not be opened.
  static const String linkError = 'Не удалось открыть ссылку. Попробуйте позже';

  Future<void> _contactAdmin(BuildContext context, WidgetRef ref) async {
    final launch = ref.read(externalUrlLauncherProvider);
    final url = await ref.read(adminContactUrlProvider.future);
    final uri = Uri.tryParse(url);
    final opened = uri != null && await launch(uri);
    if (!opened && context.mounted) showAuthSnackBar(context, linkError);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthScaffold(
      children: [
        const AuthHeading(
          title: 'Статус не подтвержден',
          subtitle:
              'Проверьте введенные данные и попробуйте снова или свяжитесь '
              'с администратором',
          largeSubtitle: true,
        ),
        const SizedBox(height: _buttonsTop),
        AuthSubmitButton(
          key: retryKey,
          label: 'Попробовать снова',
          width: _wideButtonWidth,
          onPressed: () => context.go(AppRoutes.verificationForm),
        ),
        const SizedBox(height: AppSpacing.md),
        AuthSubmitButton(
          key: contactAdminKey,
          label: 'Написать администратору',
          width: _wideButtonWidth,
          variant: AppButtonVariant.secondary,
          onPressed: () => _contactAdmin(context, ref),
        ),
      ],
    );
  }
}
