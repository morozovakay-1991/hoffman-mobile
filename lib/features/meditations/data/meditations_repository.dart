import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/core/network/index.dart';
import 'package:hoffman/features/meditations/domain/meditation.dart';

class MeditationsRepository {
  MeditationsRepository(this._dio);

  static const String _path = '/api/v1/meditations';

  final Dio _dio;

  /// Every published meditation, the featured one apart.
  Future<MeditationCatalog> fetchCatalog() async {
    final data = await _get(_path);
    return MeditationCatalog.fromJson(data);
  }

  /// One meditation. Throws [ApiException] with [AccessDeniedFailure]
  /// (`ACCESS_DENIED`) when the user's access level does not open it.
  Future<Meditation> fetch(int id) async {
    final data = await _get('$_path/$id');
    return Meditation.fromJson(data ?? const {});
  }

  /// A fresh presigned URL to the meditation's audio. Access is checked as
  /// in [fetch].
  Future<MeditationAudio> fetchAudio(int id) async {
    final data = await _get('$_path/$id/audio');
    return MeditationAudio.fromJson(data ?? const {});
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

final meditationsRepositoryProvider = Provider<MeditationsRepository>((ref) {
  return MeditationsRepository(ref.watch(dioProvider));
});
