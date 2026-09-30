import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/core/network/index.dart';
import 'package:hoffman/features/articles/domain/article.dart';

class ArticlesRepository {
  ArticlesRepository(this._dio);

  static const String _path = '/api/v1/articles';

  final Dio _dio;

  /// Every published article, the featured one apart.
  Future<ArticleCatalog> fetchCatalog() async {
    final data = await _get(_path);
    return ArticleCatalog.fromJson(data);
  }

  /// One article. Throws [ApiException] with [NotFoundFailure] for an
  /// unpublished or missing one.
  Future<Article> fetch(int id) async {
    final data = await _get('$_path/$id');
    return Article.fromJson(data ?? const {});
  }

  /// The `data` of the response.
  Future<Map<String, dynamic>?> _get(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      return response.data?['data'] as Map<String, dynamic>?;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final articlesRepositoryProvider = Provider<ArticlesRepository>((ref) {
  return ArticlesRepository(ref.watch(dioProvider));
});
