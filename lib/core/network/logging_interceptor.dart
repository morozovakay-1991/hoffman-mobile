import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Prints request/response/error details to the console. Guarded by
/// [kDebugMode] so release builds never log network payloads.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('--> ${options.method} ${options.uri}');
      if (options.data != null) {
        debugPrint('    body: ${options.data}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      final request = response.requestOptions;
      debugPrint('<-- ${response.statusCode} ${request.method} ${request.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final request = err.requestOptions;
      debugPrint(
        '<-- ERROR ${err.response?.statusCode} ${request.method} ${request.uri}: ${err.message}',
      );
    }
    handler.next(err);
  }
}
