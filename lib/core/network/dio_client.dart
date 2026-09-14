import 'package:dio/dio.dart';
import 'package:hoffman/core/network/api_base_url.dart';
import 'package:hoffman/core/network/auth_interceptor.dart';
import 'package:hoffman/core/network/logging_interceptor.dart';
import 'package:hoffman/core/network/token_storage.dart';

/// Builds the app-wide [Dio] client: base URL resolution, bearer-token
/// injection and debug-only logging.
class DioClient {
  DioClient({required void Function() onLogout, TokenStorage? tokenStorage, Dio? dio})
    : _dio = dio ?? Dio() {
    _dio.options.baseUrl = ApiBaseUrl.resolve();
    _dio.interceptors.addAll([
      AuthInterceptor(tokenStorage: tokenStorage ?? SecureTokenStorage(), logout: onLogout),
      LoggingInterceptor(),
    ]);
  }

  final Dio _dio;

  Dio get dio => _dio;
}
