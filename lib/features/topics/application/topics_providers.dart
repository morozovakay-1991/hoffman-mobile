import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/meditations/index.dart';
import 'package:hoffman/features/tools/index.dart';
import 'package:hoffman/features/topics/data/topics_repository.dart';
import 'package:hoffman/features/topics/domain/topic.dart';

/// `GET /topics`, keyed by user id like the tools.
final FutureProviderFamily<TopicCatalog, int> topicCatalogProvider =
    FutureProvider.autoDispose.family<TopicCatalog, int>(
      (ref, userId) => ref.watch(topicsRepositoryProvider).fetchCatalog(),
      // The screen shows its own retry instead.
      retry: (_, _) => null,
    );

final Provider<AsyncValue<TopicCatalog>> currentTopicCatalogProvider =
    Provider.autoDispose<AsyncValue<TopicCatalog>>((ref) {
      final userId = ref.watch(signedInUserIdProvider);
      if (userId == null) return const AsyncLoading();
      return ref.watch(topicCatalogProvider(userId));
    });

/// `GET /topics/{id}`.
final FutureProviderFamily<Topic, int> topicProvider = FutureProvider
    .autoDispose
    .family<Topic, int>(
      (ref, id) => ref.watch(topicsRepositoryProvider).fetch(id),
      retry: (_, _) => null,
    );

/// The tools and the meditations of a topic, in the order of its ids.
typedef TopicRelated = ({List<Tool> tools, List<Meditation> meditations});

/// The content linked to the topic `topicId`. The topic only carries ids,
/// so they are resolved against `GET /tools` and `GET /meditations` — the
/// same catalogs as the tabs (the meditations with their `is_locked`
/// flags). Ids missing
/// from a catalog (e.g. unpublished since) are skipped.
final ProviderFamily<AsyncValue<TopicRelated>, int> topicRelatedProvider =
    Provider.autoDispose.family<AsyncValue<TopicRelated>, int>((ref, topicId) {
      final topic = ref.watch(topicProvider(topicId)).value;
      if (topic == null) return const AsyncLoading();

      final tools = topic.toolIds.isEmpty
          ? const AsyncData(<Tool>[])
          : ref
                .watch(currentToolCatalogProvider)
                .whenData((c) => _pick(topic.toolIds, c.all, (t) => t.id));
      final meditations = topic.meditationIds.isEmpty
          ? const AsyncData(<Meditation>[])
          : ref
                .watch(currentMeditationCatalogProvider)
                .whenData(
                  (c) => _pick(topic.meditationIds, [
                    ?c.featured,
                    ...c.items,
                  ], (m) => m.id),
                );

      if (tools case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      if (meditations case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      if (tools.value case final tools?) {
        if (meditations.value case final meditations?) {
          return AsyncData((tools: tools, meditations: meditations));
        }
      }
      return const AsyncLoading();
    });

List<T> _pick<T>(List<int> ids, List<T> items, int Function(T) idOf) {
  final byId = {for (final item in items) idOf(item): item};
  return [for (final id in ids) ?byId[id]];
}
