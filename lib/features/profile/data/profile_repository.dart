import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/core/errors/index.dart';
import 'package:hoffman/core/network/index.dart';
import 'package:hoffman/features/profile/domain/profile.dart';

/// `/api/v1/profile/*` endpoints of hoffman-backend, on the shared [Dio]
/// from `core/network`. Every method throws [ApiException] on failure.
class ProfileRepository {
  ProfileRepository(this._dio);

  static const String _base = '/api/v1/profile';

  final Dio _dio;

  /// `GET /profile`.
  Future<Profile> fetch() async {
    final data = await _request(() => _dio.get<Map<String, dynamic>>(_base));
    return _profile(data);
  }

  /// `PATCH /profile`.
  Future<Profile> updateName(String name) async {
    final data = await _request(
      () => _dio.patch<Map<String, dynamic>>(_base, data: {'name': name}),
    );
    return _profile(data);
  }

  /// `PATCH /profile/email`: sends a 6-digit code to [newEmail]. The email
  /// only changes once [confirmEmailChange] succeeds; calling this again
  /// replaces the pending code (that is how the code is re-sent).
  Future<void> requestEmailChange(String newEmail) {
    return _request(
      () => _dio.patch<Map<String, dynamic>>(
        '$_base/email',
        data: {'new_email': newEmail},
      ),
    );
  }

  /// `POST /profile/email/confirm`.
  Future<Profile> confirmEmailChange(String code) async {
    final data = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '$_base/email/confirm',
        data: {'code': code},
      ),
    );
    return _profile(data);
  }

  /// `PATCH /profile/password`. The backend has no confirmation field; the
  /// "repeat" check is client-side only.
  Future<void> updatePassword({
    required String oldPassword,
    required String password,
  }) {
    return _request(
      () => _dio.patch<Map<String, dynamic>>(
        '$_base/password',
        data: {'old_password': oldPassword, 'password': password},
      ),
    );
  }

  /// `PATCH /profile/notifications` with a single category.
  Future<NotificationSettings> updateNotification(
    NotificationCategory category, {
    required bool enabled,
  }) async {
    final data = await _request(
      () => _dio.patch<Map<String, dynamic>>(
        '$_base/notifications',
        data: {category.jsonKey: enabled},
      ),
    );
    return NotificationSettings.fromJson(
      data['notification_settings'] as Map<String, dynamic>?,
    );
  }

  /// `POST /profile/deletion-request`: deletion after the backend's 30-day
  /// grace period. `422 DELETION_ALREADY_REQUESTED` if one is pending.
  Future<void> requestDeletion() {
    return _request(
      () => _dio.post<Map<String, dynamic>>('$_base/deletion-request'),
    );
  }

  /// `DELETE /profile`: deletes the account right away and revokes every
  /// token (204).
  Future<void> deleteAccount() {
    return _request(() => _dio.delete<Map<String, dynamic>>(_base));
  }

  static Profile _profile(Map<String, dynamic> data) =>
      Profile.fromJson(data['profile'] as Map<String, dynamic>);

  Future<Map<String, dynamic>> _request(
    Future<Response<Map<String, dynamic>>> Function() send,
  ) async {
    try {
      final response = await send();
      return response.data ?? const {};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});
