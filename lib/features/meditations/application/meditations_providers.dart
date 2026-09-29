import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/meditations/data/meditations_repository.dart';
import 'package:hoffman/features/meditations/domain/meditation.dart';

/// `GET /meditations`, keyed by user id like the home feed: `is_locked`
/// depends on the account, so one account's catalog never shows for the
/// next one while reloading.
final FutureProviderFamily<MeditationCatalog, int> meditationCatalogProvider =
    FutureProvider.autoDispose.family<MeditationCatalog, int>(
      (ref, userId) => ref.watch(meditationsRepositoryProvider).fetchCatalog(),
      // The screen shows its own retry instead.
      retry: (_, _) => null,
    );

final Provider<AsyncValue<MeditationCatalog>> currentMeditationCatalogProvider =
    Provider.autoDispose<AsyncValue<MeditationCatalog>>((ref) {
      final userId = ref.watch(signedInUserIdProvider);
      if (userId == null) return const AsyncLoading();
      return ref.watch(meditationCatalogProvider(userId));
    });

/// `GET /meditations/{id}`. Fails with an `ApiException` carrying
/// `AccessDeniedFailure` when the user's access level does not open it.
final FutureProviderFamily<Meditation, int> meditationProvider = FutureProvider
    .autoDispose
    .family<Meditation, int>(
      (ref, id) => ref.watch(meditationsRepositoryProvider).fetch(id),
      retry: (_, _) => null,
    );

/// Current time, for the presigned audio URL expiry. Overridden in tests.
final meditationClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);
