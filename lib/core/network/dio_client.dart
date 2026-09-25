import 'package:dio/dio.dart';
import 'package:hoffman/core/network/api_base_url.dart';
import 'package:hoffman/core/network/auth_interceptor.dart';
import 'package:hoffman/core/network/logging_interceptor.dart';
import 'package:hoffman/core/network/token_storage.dart';

/// Builds the app-wide [Dio] client: base URL resolution, bearer-token
/// injection and debug-only logging.
class DioClient {
  DioClient({
    required void Function() onLogout,
    TokenStorage? tokenStorage,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = ApiBaseUrl.resolve()
      ..connectTimeout = timeout
      ..receiveTimeout = timeout
      ..headers['Accept'] = 'application/json';
    _dio.interceptors.addAll([
      AuthInterceptor(
        tokenStorage: tokenStorage ?? SecureTokenStorage(),
        logout: onLogout,
      ),
      LoggingInterceptor(),
    ]);
  }

  /// Connect/receive timeout, so a dead network surfaces as a
  /// `NetworkFailure` instead of an endless loader.
  static const Duration timeout = Duration(seconds: 15);

  final Dio _dio;

  Dio get dio => _dio;
}
