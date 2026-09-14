import 'package:dio/dio.dart';
import 'package:hoffman/core/network/token_storage.dart';

/// Attaches the bearer access token (read from [TokenStorage]) to every
/// outgoing request, and invokes `logout` whenever the backend responds
/// with 401 so the caller can clear the session and route back to login.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required TokenStorage tokenStorage, required void Function() logout})
    : _tokenStorage = tokenStorage,
      _logout = logout;

  final TokenStorage _tokenStorage;
  final void Function() _logout;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _logout();
    }
    handler.next(err);
  }
}
