import 'package:dio/dio.dart';
import 'package:hoffman/core/errors/error_mapper.dart';
import 'package:hoffman/core/errors/failure.dart';

/// A failed hoffman-backend request: the [Failure] category from
/// [ErrorMapper] plus the backend's own `{error: {code, message, fields}}`
/// details, so a feature can react to a specific [code] (e.g.
/// `INVALID_CODE`) without re-parsing the response.
class ApiException implements Exception {
  const ApiException(
    this.failure, {
    this.statusCode,
    this.code,
    this.fields = const {},
    this.retryAfter,
  });

  factory ApiException.fromDio(DioException exception) {
    final response = exception.response;
    final failure = ErrorMapper.map(exception);
    return ApiException(
      failure,
      statusCode: response?.statusCode,
      code: _errorCode(response?.data),
      fields: failure is ValidationFailure
          ? failure.fields
          : const <String, List<String>>{},
      retryAfter: _retryAfter(response),
    );
  }

  final Failure failure;

  /// HTTP status; `null` when no response arrived (offline, timeout).
  final int? statusCode;

  /// Backend `error.code`, e.g. `VALIDATION_ERROR`, `INVALID_CODE`.
  final String? code;

  /// Backend validation messages per field (English, not shown to users).
  final Map<String, List<String>> fields;

  /// From the `Retry-After` header of a 429 response.
  final Duration? retryAfter;

  /// No connection or timeout: nothing reached the backend.
  bool get isNetwork => failure is NetworkFailure && statusCode == null;

  /// 429 from the rate limiter (`TOO_MANY_REQUESTS`). [ErrorMapper] files it
  /// under [NetworkFailure], so check this before [isNetwork].
  bool get isRateLimited => statusCode == 429;

  static String? _errorCode(Object? data) {
    if (data is Map && data['error'] is Map) {
      return (data['error'] as Map)['code'] as String?;
    }
    return null;
  }

  static Duration? _retryAfter(Response<dynamic>? response) {
    final seconds = int.tryParse(response?.headers.value('retry-after') ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }

  @override
  String toString() => 'ApiException($statusCode, $code, $fields)';
}
