import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/core/network/index.dart';
import 'package:hoffman/features/profile/domain/legal_document.dart';

/// Public `/api/v1/legal-documents/*` endpoints of hoffman-backend, on the
/// shared [Dio] from `core/network`. Both are Laravel API resources, so the
/// payload sits under `data`. Every method throws [ApiException] on failure.
class LegalRepository {
  LegalRepository(this._dio);

  static const String _base = '/api/v1/legal-documents';

  final Dio _dio;

  /// `GET /legal-documents`, ordered by slug on the backend.
  Future<List<LegalDocumentSummary>> list() async {
    final data = await _request(() => _dio.get<Object?>(_base));
    return [
      for (final item in data as List<dynamic>? ?? const [])
        LegalDocumentSummary.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// `GET /legal-documents/{slug}`; an unknown slug is a 404.
  Future<LegalDocument> document(String slug) async {
    final data = await _request(
      () => _dio.get<Object?>('$_base/${Uri.encodeComponent(slug)}'),
    );
    return LegalDocument.fromJson(data as Map<String, dynamic>? ?? const {});
  }

  Future<Object?> _request(Future<Response<Object?>> Function() send) async {
    try {
      final body = (await send()).data;
      return body is Map ? body['data'] : null;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final legalRepositoryProvider = Provider<LegalRepository>((ref) {
  return LegalRepository(ref.watch(dioProvider));
});
