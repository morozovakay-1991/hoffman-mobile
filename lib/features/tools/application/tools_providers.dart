import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/tools/data/tools_repository.dart';
import 'package:hoffman/features/tools/domain/tool.dart';

/// `GET /tools`, keyed by user id like the meditations, so the catalog is
/// fetched afresh for each account.
final FutureProviderFamily<ToolCatalog, int> toolCatalogProvider =
    FutureProvider.autoDispose.family<ToolCatalog, int>(
      (ref, userId) => ref.watch(toolsRepositoryProvider).fetchCatalog(),
      // The screen shows its own retry instead.
      retry: (_, _) => null,
    );

final Provider<AsyncValue<ToolCatalog>> currentToolCatalogProvider =
    Provider.autoDispose<AsyncValue<ToolCatalog>>((ref) {
      final userId = ref.watch(signedInUserIdProvider);
      if (userId == null) return const AsyncLoading();
      return ref.watch(toolCatalogProvider(userId));
    });

/// `GET /tools/{id}`.
final FutureProviderFamily<Tool, int> toolProvider = FutureProvider.autoDispose
    .family<Tool, int>(
      (ref, id) => ref.watch(toolsRepositoryProvider).fetch(id),
      retry: (_, _) => null,
    );
