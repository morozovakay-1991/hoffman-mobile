import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/errors/index.dart';

RequestOptions _requestOptions() => RequestOptions(path: '/x');

DioException _withResponse(
  int statusCode, {
  Object? data,
  Map<String, List<String>> headers = const {},
}) {
  return DioException(
    requestOptions: _requestOptions(),
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: _requestOptions(),
      statusCode: statusCode,
      data: data,
      headers: Headers.fromMap(headers),
    ),
  );
}

Map<String, Object> _error(
  String code, [
  Map<String, Object> fields = const {},
]) => {
  'error': {'code': code, 'message': code, 'fields': fields},
};

void main() {
  group('ApiException.fromDio', () {
    test('no response: a network failure without a status', () {
      final e = ApiException.fromDio(
        DioException.connectionError(
          requestOptions: _requestOptions(),
          reason: 'offline',
        ),
      );

      expect(e.failure, const Failure.network());
      expect(e.statusCode, isNull);
      expect(e.isNetwork, isTrue);
      expect(e.isRateLimited, isFalse);
    });

    test('reads the backend error code and validation fields', () {
      final e = ApiException.fromDio(
        _withResponse(
          422,
          data: _error('EMAIL_TAKEN', {
            'new_email': ['This email address is already registered.'],
          }),
        ),
      );

      expect(e.statusCode, 422);
      expect(e.code, 'EMAIL_TAKEN');
      expect(e.failure, isA<ValidationFailure>());
      expect(e.fields.keys, ['new_email']);
      expect(e.isNetwork, isFalse);
    });

    test('a domain 422 without fields keeps its code', () {
      final e = ApiException.fromDio(
        _withResponse(422, data: _error('INVALID_OLD_PASSWORD')),
      );

      expect(e.code, 'INVALID_OLD_PASSWORD');
      expect(e.fields, isEmpty);
    });

    test('429: rate limited with Retry-After, not a network failure', () {
      final e = ApiException.fromDio(
        _withResponse(
          429,
          data: _error('TOO_MANY_REQUESTS'),
          headers: {
            'retry-after': ['90'],
          },
        ),
      );

      expect(e.isRateLimited, isTrue);
      expect(e.isNetwork, isFalse);
      expect(e.retryAfter, const Duration(seconds: 90));
    });

    test('404 and 5xx map to their failures; a non-JSON body has no code', () {
      final notFound = ApiException.fromDio(
        _withResponse(404, data: _error('NOT_FOUND')),
      );
      final server = ApiException.fromDio(
        _withResponse(502, data: '<html>Bad gateway</html>'),
      );

      expect(notFound.failure, const Failure.notFound());
      expect(server.failure, const Failure.server());
      expect(server.code, isNull);
    });
  });
}
