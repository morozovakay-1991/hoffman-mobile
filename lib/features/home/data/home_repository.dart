import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/core/network/index.dart';
import 'package:hoffman/features/home/domain/home_summary.dart';

/// `GET /api/v1/home` of hoffman-backend, on the shared [Dio] from
/// `core/network`. Throws [ApiException] on failure.
class HomeRepository {
  HomeRepository(this._dio);

  static const String _path = '/api/v1/home';

  final Dio _dio;

  /// Where the backend serves its public disk (`storage:link`), against
  /// which article cover paths are resolved.
  Uri get _storageBaseUrl =>
      Uri.parse(_dio.options.baseUrl).resolve('/storage/');

  /// The whole home screen in one request.
  Future<HomeSummary> fetch() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_path);
      final data = response.data?['data'] as Map<String, dynamic>? ?? const {};
      return HomeSummary.fromJson(data, storageBaseUrl: _storageBaseUrl);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(dioProvider));
});
