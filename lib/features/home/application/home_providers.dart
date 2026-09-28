import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/home/data/home_repository.dart';
import 'package:hoffman/features/home/domain/home_summary.dart';

/// Home feed of the user with the given id, loaded with `GET /home`.
///
/// Keyed by user id, like the profile controller: the feed depends on
/// the user's access level and diary progress, and a provider rebuilt on
/// sign-in would briefly show the previous account's feed.
final FutureProviderFamily<HomeSummary, int> homeSummaryProvider =
    FutureProvider.autoDispose.family<HomeSummary, int>(
      (ref, userId) => ref.watch(homeRepositoryProvider).fetch(),
      // The screen shows its own retry instead.
      retry: (_, _) => null,
    );

/// The signed-in user's home feed; `AsyncLoading` while signed out (the
/// router is leaving home then).
final Provider<AsyncValue<HomeSummary>> currentHomeSummaryProvider =
    Provider.autoDispose<AsyncValue<HomeSummary>>((ref) {
      final userId = ref.watch(signedInUserIdProvider);
      if (userId == null) return const AsyncLoading();
      return ref.watch(homeSummaryProvider(userId));
    });
