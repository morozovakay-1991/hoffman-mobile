import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';

// Building blocks shared by the profile screens (Figma page "final", section
// "Профиль"). Offsets are measured from the safe area of the 393×852 mockup,
// as in auth_widgets.dart.

/// Texts the mockups have no slot for: the outcome of an action and the
/// error states of section 11.7 of the spec.
abstract final class ProfileText {
  static const String nameSaved = 'Имя сохранено';
  static const String emailChanged = 'Email изменен';
  static const String passwordChanged = 'Пароль изменен';
  static const String sameEmail = 'Это ваш текущий email';
  static const String invalidOldPassword = 'Неверный пароль';
  static const String deletionRequested =
      'Запрос отправлен. Данные будут удалены в течение 30 дней';
  static const String deletionAlreadyRequested =
      'Запрос на удаление данных уже отправлен';
  static const String loadFailed = 'Не удалось загрузить данные';
  static const String notificationFailed =
      'Не удалось сохранить настройку. Попробуйте снова';
  static const String documentNotFound = 'Документ не найден';

  /// The message for a failure no screen handles specifically: no
  /// connection, the rate limiter, or anything else.
  static String of(ApiException e) {
    if (e.isRateLimited) {
      return AuthErrorText.tooManyAttemptsWait(
        e.retryAfter ?? const Duration(minutes: 1),
      );
    }
    if (e.isNetwork) return AuthErrorText.network;
    if (e.code == 'ACCOUNT_BLOCKED') return AuthErrorText.accountBlocked;
    return AuthErrorText.unknown;
  }

  /// Full-screen load failure text for [error] from a provider.
  static String loadError(Object error) =>
      error is ApiException && error.isNetwork
      ? AuthErrorText.network
      : loadFailed;
}

/// White page with the back bar (`Icon` Variant5) pinned above scrollable
/// [children]. Unlike `AuthScaffold` the children are not padded, so menu
/// dividers can run edge to edge; wrap text in [ProfileScaffold.padded].
class ProfileScaffold extends StatelessWidget {
  const ProfileScaffold({required this.children, super.key, this.onBack});

  /// Defaults to popping, or to [AppRoutes.profile] with nothing to pop (a
  /// deep link).
  final VoidCallback? onBack;
  final List<Widget> children;

  static Widget padded(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthBackBar(onBack: onBack ?? () => popOrGo(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Back navigation for a pushed profile screen.
  static void popOrGo(
    BuildContext context, [
    String fallback = AppRoutes.profile,
  ]) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallback);
    }
  }
}

/// A 32px `H1` title ("Личные данные", "Уведомления", "Правовая
/// информация"): `Text/Display` with a 32px line, 4px vertical padding,
/// 32px below the back bar.
class ProfilePageTitle extends StatelessWidget {
  const ProfilePageTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xl + AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(height: 1),
      ),
    );
  }
}

/// The `Text/h2` (Golos Text 20/28) title of a form screen ("Имя
/// пользователя", "Email", "Пароль"), 32px below the back bar and 32px above
/// the first field.
class ProfileFormTitle extends StatelessWidget {
  const ProfileFormTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      child: Text(title, style: ProfileMenuTile.labelStyle(context)),
    );
  }
}

/// A menu row (e.g. 651:3571): a `Text/h2` label and a 16px trailing icon,
/// 32px above and below. Tappable across the full width.
class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    required this.label,
    super.key,
    this.onTap,
    this.trailing = const Icon(
      Icons.arrow_forward,
      size: arrowSize,
      color: AppColors.basicBlack,
    ),
  });

  static const double arrowSize = 16;

  final String label;
  final VoidCallback? onTap;

  /// Defaults to the `arrow_forward_RoundedFill` arrow.
  // TODO(figma): swap for the exported `arrow_forward` SVG once flutter_svg
  // is added.
  final Widget trailing;

  static TextStyle? labelStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge?.copyWith(height: 28 / 20);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xl,
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: labelStyle(context))),
              const SizedBox(width: AppSpacing.md),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Stacks [tiles] with the full-width 0.5px black divider (`Line 31`)
/// between them.
class ProfileMenu extends StatelessWidget {
  const ProfileMenu({required this.tiles, super.key});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, tile) in tiles.indexed) ...[
          if (i > 0)
            const Divider(
              height: 0.5,
              thickness: 0.5,
              color: AppColors.basicBlack,
            ),
          tile,
        ],
      ],
    );
  }
}

/// A full-page load failure with a retry, below the back bar.
class ProfileLoadError extends StatelessWidget {
  const ProfileLoadError({
    required this.error,
    required this.onRetry,
    super.key,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: ErrorStateWidget(
        message: ProfileText.loadError(error),
        onRetry: onRetry,
      ),
    );
  }
}

/// A page-level spinner below the back bar.
class ProfileLoading extends StatelessWidget {
  const ProfileLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 160),
      child: LoadingIndicator(),
    );
  }
}
