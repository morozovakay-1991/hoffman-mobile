import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/features/auth/index.dart';

final _options = RequestOptions(path: '/api/v1/auth/x');

/// A failed response with hoffman-backend's `{error: {code, message,
/// fields}}` body (shapes captured from the running backend).
DioException _response(
  int status,
  String code, {
  Map<String, List<String>> fields = const {},
  Map<String, List<String>> headers = const {},
}) {
  return DioException(
    requestOptions: _options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: _options,
      statusCode: status,
      headers: Headers.fromMap(headers),
      data: {
        'error': {'code': code, 'message': '…', 'fields': fields},
      },
    ),
  );
}

void main() {
  final cases = <String, (DioException, AuthErrorCode)>{
    '401 INVALID_CREDENTIALS': (
      _response(401, 'INVALID_CREDENTIALS'),
      AuthErrorCode.invalidCredentials,
    ),
    '401 UNAUTHENTICATED': (
      _response(401, 'UNAUTHENTICATED'),
      AuthErrorCode.unauthorized,
    ),
    '403 ACCOUNT_BLOCKED': (
      _response(403, 'ACCOUNT_BLOCKED'),
      AuthErrorCode.accountBlocked,
    ),
    '404 EMAIL_NOT_FOUND': (
      _response(404, 'EMAIL_NOT_FOUND'),
      AuthErrorCode.emailNotFound,
    ),
    '422 INVALID_CODE': (
      _response(422, 'INVALID_CODE'),
      AuthErrorCode.invalidCode,
    ),
    '422 CODE_EXPIRED': (
      _response(422, 'CODE_EXPIRED'),
      AuthErrorCode.codeExpired,
    ),
    '422 TOO_MANY_ATTEMPTS': (
      _response(422, 'TOO_MANY_ATTEMPTS'),
      AuthErrorCode.tooManyAttempts,
    ),
    '422 email taken': (
      _response(
        422,
        'VALIDATION_ERROR',
        fields: {
          'email': ['The email has already been taken.'],
        },
      ),
      AuthErrorCode.emailTaken,
    ),
    '422 other validation': (
      _response(
        422,
        'VALIDATION_ERROR',
        fields: {
          'email': ['The email field must be a valid email address.'],
        },
      ),
      AuthErrorCode.validation,
    ),
    '500': (_response(500, 'SERVER_ERROR'), AuthErrorCode.unknown),
    'connection error': (
      DioException.connectionError(requestOptions: _options, reason: 'x'),
      AuthErrorCode.network,
    ),
    'timeout': (
      DioException.connectionTimeout(
        requestOptions: _options,
        timeout: const Duration(seconds: 15),
      ),
      AuthErrorCode.network,
    ),
  };

  for (final MapEntry(key: name, value: (exception, code)) in cases.entries) {
    test('$name → $code', () {
      expect(AuthException.fromDio(exception).code, code);
    });
  }

  test('keeps validation fields', () {
    final e = AuthException.fromDio(
      _response(
        422,
        'VALIDATION_ERROR',
        fields: {
          'password': ['The password field format is invalid.'],
        },
      ),
    );
    expect(e.fields.keys, ['password']);
  });

  test('429 reads Retry-After', () {
    final e = AuthException.fromDio(
      _response(
        429,
        'TOO_MANY_REQUESTS',
        headers: {
          'retry-after': ['90'],
        },
      ),
    );
    expect(e.code, AuthErrorCode.tooManyAttempts);
    expect(e.retryAfter, const Duration(seconds: 90));
  });
}
