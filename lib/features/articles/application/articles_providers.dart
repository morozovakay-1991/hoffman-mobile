import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:hoffman/features/articles/data/articles_repository.dart';
import 'package:hoffman/features/articles/domain/article.dart';

/// `GET /articles`. Not keyed by user, unlike the meditations: articles are
/// the same for every account (no `is_locked`).
final FutureProvider<ArticleCatalog> articleCatalogProvider =
    FutureProvider.autoDispose<ArticleCatalog>(
      (ref) => ref.watch(articlesRepositoryProvider).fetchCatalog(),
      // The screen shows its own retry instead.
      retry: (_, _) => null,
    );

/// `GET /articles/{id}`.
final FutureProviderFamily<Article, int> articleProvider = FutureProvider
    .autoDispose
    .family<Article, int>(
      (ref, id) => ref.watch(articlesRepositoryProvider).fetch(id),
      retry: (_, _) => null,
    );
