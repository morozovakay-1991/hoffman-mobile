import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/core/network/index.dart';
import 'package:hoffman/features/auth/domain/auth_exception.dart';
import 'package:hoffman/features/auth/domain/verification_request.dart';

/// `/api/v1/verification/*` endpoints of hoffman-backend (graduate status),
/// on the shared [Dio] from `core/network`. Every method throws
/// [AuthException] on failure.
class VerificationRepository {
  VerificationRepository(this._dio);

  static const String _base = '/api/v1/verification';

  final Dio _dio;

  /// `POST /verification/submit`. The backend matches the data against the
  /// graduate directory right away, so the returned status is already
  /// final for a match ([VerificationStatus.confirmed]).
  Future<VerificationRequest> submit({
    required String lastName,
    required String firstName,
    required String phone,
  }) async {
    final request = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '$_base/submit',
        data: {'last_name': lastName, 'first_name': firstName, 'phone': phone},
      ),
    );
    // The backend always returns the request it has just saved.
    return request!;
  }

  /// `GET /verification/status`: the latest request, `null` if the user has
  /// never submitted one.
  Future<VerificationRequest?> status() {
    return _request(() => _dio.get<Map<String, dynamic>>('$_base/status'));
  }

  Future<VerificationRequest?> _request(
    Future<Response<Map<String, dynamic>>> Function() send,
  ) async {
    try {
      final json = (await send()).data?['verification_request'];
      return json is Map<String, dynamic>
          ? VerificationRequest.fromJson(json)
          : null;
    } on DioException catch (e) {
      throw AuthException.fromDio(e);
    }
  }
}

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepository(ref.watch(dioProvider));
});
