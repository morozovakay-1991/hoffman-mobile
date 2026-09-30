import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/core/network/index.dart';
import 'package:hoffman/features/tools/domain/tool.dart';

class ToolsRepository {
  ToolsRepository(this._dio);

  static const String _path = '/api/v1/tools';

  final Dio _dio;

  /// Every published tool, the featured one apart.
  Future<ToolCatalog> fetchCatalog() async {
    final data = await _get(_path);
    return ToolCatalog.fromJson(data);
  }

  /// One tool.
  Future<Tool> fetch(int id) async {
    final data = await _get('$_path/$id');
    return Tool.fromJson(data ?? const {});
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

final toolsRepositoryProvider = Provider<ToolsRepository>((ref) {
  return ToolsRepository(ref.watch(dioProvider));
});
