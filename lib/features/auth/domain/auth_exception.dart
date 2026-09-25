import 'package:dio/dio.dart';
import 'package:hoffman/core/errors/index.dart';

/// What went wrong in an auth request, decoded from the backend's
/// `{error: {code, message, fields}}` body.
enum AuthErrorCode {
  /// 401 `INVALID_CREDENTIALS` — wrong email/password pair.
  invalidCredentials,

  /// Any other 401 (`UNAUTHENTICATED`) — the bearer token is missing,
  /// expired or revoked.
  unauthorized,

  /// 422 `VALIDATION_ERROR` with a `unique` failure on `email`.
  emailTaken,

  /// 404 `EMAIL_NOT_FOUND` (reset-password `verify-code` / `reset`).
  emailNotFound,

  /// 422 `INVALID_CODE`.
  invalidCode,

  /// 422 `CODE_EXPIRED` — past the backend's 5-minute code TTL.
  codeExpired,

  /// 422 `TOO_MANY_ATTEMPTS`, or 429 from the rate limiter.
  tooManyAttempts,

  /// 403 `ACCOUNT_BLOCKED`.
  accountBlocked,

  /// Any other 422 validation failure; see [AuthException.fields].
  validation,

  /// No connection or timeout.
  network,

  /// 5xx or an unrecognized response.
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.code, {this.fields = const {}, this.retryAfter});

  /// Decodes a failed auth request.
  factory AuthException.fromDio(DioException exception) {
    final failure = ErrorMapper.map(exception);
    final response = exception.response;
    final status = response?.statusCode;
    final fields = failure is ValidationFailure
        ? failure.fields
        : const <String, List<String>>{};

    if (failure is NetworkFailure && response == null) {
      return const AuthException(AuthErrorCode.network);
    }
    if (status == 429) {
      return AuthException(
        AuthErrorCode.tooManyAttempts,
        retryAfter: _retryAfter(response),
      );
    }

    final code = switch (_errorCode(response?.data)) {
      'INVALID_CREDENTIALS' => AuthErrorCode.invalidCredentials,
      'EMAIL_NOT_FOUND' => AuthErrorCode.emailNotFound,
      'INVALID_CODE' => AuthErrorCode.invalidCode,
      'CODE_EXPIRED' => AuthErrorCode.codeExpired,
      'TOO_MANY_ATTEMPTS' => AuthErrorCode.tooManyAttempts,
      'ACCOUNT_BLOCKED' => AuthErrorCode.accountBlocked,
      _ when status == 401 => AuthErrorCode.unauthorized,
      'VALIDATION_ERROR' when _isEmailTaken(fields) => AuthErrorCode.emailTaken,
      'VALIDATION_ERROR' => AuthErrorCode.validation,
      _ => AuthErrorCode.unknown,
    };
    return AuthException(code, fields: fields);
  }

  final AuthErrorCode code;

  /// Backend validation messages per field (English, not shown to users).
  final Map<String, List<String>> fields;

  /// From the `Retry-After` header of a 429 response.
  final Duration? retryAfter;

  static String? _errorCode(Object? data) {
    if (data is Map && data['error'] is Map) {
      return (data['error'] as Map)['code'] as String?;
    }
    return null;
  }

  /// Laravel's `unique` rule message is "The email has already been taken."
  static bool _isEmailTaken(Map<String, List<String>> fields) {
    return fields['email']?.any((m) => m.contains('already been taken')) ??
        false;
  }

  static Duration? _retryAfter(Response<dynamic>? response) {
    final seconds = int.tryParse(response?.headers.value('retry-after') ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }

  @override
  String toString() => 'AuthException($code, $fields)';
}
