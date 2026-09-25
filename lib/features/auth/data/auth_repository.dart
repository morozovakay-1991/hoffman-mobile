import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/core/network/index.dart';
import 'package:hoffman/features/auth/domain/auth_exception.dart';
import 'package:hoffman/features/auth/domain/auth_user.dart';

/// `/api/v1/auth/*` endpoints of hoffman-backend, on the shared [Dio] from
/// `core/network`. Every method throws [AuthException] on failure; the
/// bearer token is stored in [TokenStorage] on a successful login/register.
class AuthRepository {
  AuthRepository({required Dio dio, required TokenStorage tokenStorage})
    : _dio = dio,
      _tokenStorage = tokenStorage;

  static const String _base = '/api/v1/auth';

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<bool> hasToken() async {
    final token = await _tokenStorage.readAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<AuthUser> login({required String email, required String password}) {
    return _authenticate('$_base/login', {
      'email': email,
      'password': password,
    });
  }

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) {
    return _authenticate('$_base/register', {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  /// `GET /auth/me`.
  Future<AuthUser> me() async {
    final data = await _request(
      () => _dio.get<Map<String, dynamic>>('$_base/me'),
    );
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Revokes the token on the backend (best effort — offline logout must
  /// still work) and always removes it locally.
  Future<void> logout() async {
    try {
      await _dio.post<void>('$_base/logout');
    } on DioException {
      // The token is dropped locally below either way.
    } finally {
      await _tokenStorage.deleteAccessToken();
    }
  }

  Future<void> clearToken() => _tokenStorage.deleteAccessToken();

  /// `POST /auth/password/forgot`. The backend answers 200 even for an
  /// unknown email, so that case only surfaces at [verifyResetCode].
  Future<void> requestPasswordReset({required String email}) {
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '$_base/password/forgot',
        data: {'email': email},
      ),
    );
  }

  Future<void> verifyResetCode({required String email, required String code}) {
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '$_base/password/verify-code',
        data: {'email': email, 'code': code},
      ),
    );
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) {
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '$_base/password/reset',
        data: {
          'email': email,
          'code': code,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      ),
    );
  }

  Future<AuthUser> _authenticate(String path, Map<String, String> body) async {
    final data = await _request(
      () => _dio.post<Map<String, dynamic>>(path, data: body),
    );
    await _tokenStorage.writeAccessToken(data['token'] as String);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> _request(
    Future<Response<Map<String, dynamic>>> Function() send,
  ) async {
    try {
      final response = await send();
      return response.data ?? const {};
    } on DioException catch (e) {
      throw AuthException.fromDio(e);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});
