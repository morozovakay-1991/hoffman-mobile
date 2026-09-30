import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/core/network/index.dart';
import 'package:hoffman/features/topics/domain/topic.dart';

class TopicsRepository {
  TopicsRepository(this._dio);

  static const String _path = '/api/v1/topics';

  final Dio _dio;

  /// Every published topic, the featured one apart.
  Future<TopicCatalog> fetchCatalog() async {
    final data = await _get(_path);
    return TopicCatalog.fromJson(data);
  }

  /// One topic with its tool and meditation ids.
  Future<Topic> fetch(int id) async {
    final data = await _get('$_path/$id');
    return Topic.fromJson(data ?? const {});
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

final topicsRepositoryProvider = Provider<TopicsRepository>((ref) {
  return TopicsRepository(ref.watch(dioProvider));
});
