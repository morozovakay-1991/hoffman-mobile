import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/profile/data/profile_repository.dart';
import 'package:hoffman/features/profile/domain/profile.dart';

/// Profile of the user [userId], loaded with `GET /profile`.
///
/// The update methods never put the provider into loading: the screens
/// track their own progress and catch the thrown [ApiException]. A change of
/// name or email is also pushed to [AuthController], so the session's user
/// stays current.
class ProfileController extends AsyncNotifier<Profile> {
  ProfileController(this.userId);

  final int userId;

  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  Future<Profile> build() => ref.watch(profileRepositoryProvider).fetch();

  Future<Profile> updateName(String name) async {
    return _replace(await _repository.updateName(name));
  }

  Future<Profile> confirmEmailChange(String code) async {
    return _replace(await _repository.confirmEmailChange(code));
  }

  /// Flips [category] right away and rolls it back if the backend refuses.
  Future<void> setNotification(
    NotificationCategory category, {
    required bool enabled,
  }) async {
    final before = state.value;
    if (before == null) return;
    state = AsyncData(
      before.copyWith(
        notificationSettings: before.notificationSettings.copyWithCategory(
          category,
          enabled: enabled,
        ),
      ),
    );
    try {
      final settings = await _repository.updateNotification(
        category,
        enabled: enabled,
      );
      final current = state.value;
      if (current != null && ref.mounted) {
        state = AsyncData(current.copyWith(notificationSettings: settings));
      }
    } on ApiException {
      final current = state.value;
      if (current != null && ref.mounted) {
        state = AsyncData(
          current.copyWith(
            notificationSettings: current.notificationSettings.copyWithCategory(
              category,
              enabled: before.notificationSettings.isEnabled(category),
            ),
          ),
        );
      }
      rethrow;
    }
  }

  Profile _replace(Profile profile) {
    // PATCH /profile does not load the notification settings.
    final merged = profile.copyWith(
      notificationSettings: state.value?.notificationSettings,
    );
    if (ref.mounted) state = AsyncData(merged);
    ref
        .read(authControllerProvider.notifier)
        .userUpdated(
          AuthUser(id: merged.id, name: merged.name, email: merged.email),
        );
    return merged;
  }
}

/// Keyed by user id, like `verificationControllerProvider`: a rebuilt
/// provider keeps its previous value while reloading, which would briefly
/// show one account's profile to the next account on the same device.
final AsyncNotifierProviderFamily<ProfileController, Profile, int>
profileControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ProfileController, Profile, int>(
      ProfileController.new,
      // Screens show their own retry instead.
      retry: (_, _) => null,
    );

/// The signed-in user's profile; `AsyncLoading` while signed out (the
/// router is leaving the profile screens then).
final Provider<AsyncValue<Profile>> currentProfileProvider =
    Provider.autoDispose<AsyncValue<Profile>>((ref) {
      final userId = ref.watch(signedInUserIdProvider);
      if (userId == null) return const AsyncLoading();
      return ref.watch(profileControllerProvider(userId));
    });
