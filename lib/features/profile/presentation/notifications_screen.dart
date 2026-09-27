import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/profile/application/profile_controller.dart';
import 'package:hoffman/features/profile/domain/profile.dart';
import 'package:hoffman/features/profile/presentation/widgets/profile_widgets.dart';

/// "Уведомления" — Figma 642:3433. Each switch saves at once with
/// `PATCH /profile/notifications` and flips back if that fails.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  static Key toggleKey(NotificationCategory category) =>
      ValueKey('notification-${category.name}');

  static const Map<NotificationCategory, String> labels = {
    NotificationCategory.dailyPractices: 'Ежедневные практики',
    NotificationCategory.newArticles: 'Новые статьи',
    NotificationCategory.system: 'Системные',
  };

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  /// Categories with a request in flight; ignored until it settles, so two
  /// quick taps cannot race each other on the backend.
  final Set<NotificationCategory> _saving = {};

  Future<void> _toggle(NotificationCategory category, bool enabled) async {
    final userId = ref.read(signedInUserIdProvider);
    if (userId == null || _saving.contains(category)) return;
    setState(() => _saving.add(category));
    try {
      await ref
          .read(profileControllerProvider(userId).notifier)
          .setNotification(category, enabled: enabled);
    } on ApiException catch (e) {
      if (mounted) {
        showAuthSnackBar(
          context,
          e.isNetwork || e.isRateLimited
              ? ProfileText.of(e)
              : ProfileText.notificationFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _saving.remove(category));
    }
  }

  void _retry() {
    final userId = ref.read(signedInUserIdProvider);
    if (userId != null) ref.invalidate(profileControllerProvider(userId));
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);

    return ProfileScaffold(
      children: [
        const ProfilePageTitle('Уведомления'),
        switch (profile) {
          AsyncValue(:final value?) => ProfileMenu(
            tiles: [
              for (final category in NotificationCategory.values)
                _NotificationTile(
                  key: NotificationsScreen.toggleKey(category),
                  label: NotificationsScreen.labels[category]!,
                  enabled: value.notificationSettings.isEnabled(category),
                  onChanged: (enabled) => _toggle(category, enabled),
                ),
            ],
          ),
          AsyncValue(:final error?) => ProfileLoadError(
            error: error,
            onRetry: _retry,
          ),
          _ => const ProfileLoading(),
        },
      ],
    );
  }
}

/// A row with the Material Symbols `toggle_on` / `toggle_off` glyph
/// (651:4599, 651:4630) at 24px.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.label,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  static const double toggleSize = 24;

  final String label;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        toggled: enabled,
        child: ProfileMenuTile(
          label: label,
          onTap: () => onChanged(!enabled),
          trailing: Icon(
            enabled ? Icons.toggle_on : Icons.toggle_off,
            size: toggleSize,
            color: AppColors.basicBlack,
          ),
        ),
      ),
    );
  }
}
