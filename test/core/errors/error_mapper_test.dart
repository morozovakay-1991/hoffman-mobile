import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/errors/error_mapper.dart';
import 'package:hoffman/core/errors/failure.dart';

RequestOptions _requestOptions() => RequestOptions(path: '/x');

DioException _withResponse(int statusCode, {dynamic data}) {
  return DioException(
    requestOptions: _requestOptions(),
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: _requestOptions(),
      statusCode: statusCode,
      data: data,
    ),
  );
}

void main() {
  group('ErrorMapper.map', () {
    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    ]) {
      test('maps $type to NetworkFailure', () {
        final exception = DioException(requestOptions: _requestOptions(), type: type);
        expect(ErrorMapper.map(exception), const Failure.network());
      });
    }

    test('maps 400 to ValidationFailure with fields from the response body', () {
      final failure = ErrorMapper.map(
        _withResponse(
          400,
          data: {
            'errors': {
              'email': ['is invalid'],
            },
          },
        ),
      );

      expect(
        failure,
        Failure.validation({
          'email': ['is invalid'],
        }),
      );
    });

    test('maps 422 to ValidationFailure with fields from a flat body', () {
      final failure = ErrorMapper.map(
        _withResponse(
          422,
          data: {
            'password': ['too short'],
          },
        ),
      );

      expect(
        failure,
        Failure.validation({
          'password': ['too short'],
        }),
      );
    });

    test('maps 401 to UnauthorizedFailure', () {
      expect(ErrorMapper.map(_withResponse(401)), const Failure.unauthorized());
    });

    test('maps 403 to AccessDeniedFailure', () {
      expect(ErrorMapper.map(_withResponse(403)), const Failure.accessDenied());
    });

    test('maps 404 to NotFoundFailure', () {
      expect(ErrorMapper.map(_withResponse(404)), const Failure.notFound());
    });

    test('maps 500 to ServerFailure', () {
      expect(ErrorMapper.map(_withResponse(500)), const Failure.server());
    });

    test('maps 503 to ServerFailure', () {
      expect(ErrorMapper.map(_withResponse(503)), const Failure.server());
    });
  });
}
