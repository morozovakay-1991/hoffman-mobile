import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/network/auth_interceptor.dart';
import 'package:hoffman/core/network/token_storage.dart';
import 'package:mocktail/mocktail.dart';

class _MockTokenStorage extends Mock implements TokenStorage {}

/// Records the last request and returns a canned response, so interceptor
/// behavior can be exercised through a real [Dio] request/response cycle
/// without any actual network I/O.
class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._statusCode);

  final int _statusCode;
  RequestOptions? lastRequestOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    return ResponseBody.fromString(
      '{}',
      _statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _buildDio({
  required TokenStorage tokenStorage,
  required void Function() logout,
  required int statusCode,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
    ..httpClientAdapter = _FakeHttpClientAdapter(statusCode)
    ..interceptors.add(
      AuthInterceptor(tokenStorage: tokenStorage, logout: logout),
    );
  return dio;
}

void main() {
  late _MockTokenStorage tokenStorage;

  setUp(() {
    tokenStorage = _MockTokenStorage();
  });

  group('AuthInterceptor', () {
    test(
      'attaches the Bearer token from TokenStorage to outgoing requests',
      () async {
        when(tokenStorage.readAccessToken).thenAnswer((_) async => 'abc123');
        var logoutCalled = false;

        final dio = _buildDio(
          tokenStorage: tokenStorage,
          logout: () => logoutCalled = true,
          statusCode: 200,
        );

        await dio.get<void>('/ping');

        final adapter = dio.httpClientAdapter as _FakeHttpClientAdapter;
        expect(
          adapter.lastRequestOptions?.headers['Authorization'],
          'Bearer abc123',
        );
        expect(logoutCalled, isFalse);
      },
    );

    test(
      'sends no Authorization header when there is no stored token',
      () async {
        when(tokenStorage.readAccessToken).thenAnswer((_) async => null);

        final dio = _buildDio(
          tokenStorage: tokenStorage,
          logout: () {},
          statusCode: 200,
        );

        await dio.get<void>('/ping');

        final adapter = dio.httpClientAdapter as _FakeHttpClientAdapter;
        expect(
          adapter.lastRequestOptions?.headers.containsKey('Authorization'),
          isFalse,
        );
      },
    );

    test('invokes the logout callback on a 401 response', () async {
      when(tokenStorage.readAccessToken)
          .thenAnswer((_) async => 'expired-token');
      var logoutCalled = false;

      final dio = _buildDio(
        tokenStorage: tokenStorage,
        logout: () => logoutCalled = true,
        statusCode: 401,
      );

      await expectLater(dio.get<void>('/ping'), throwsA(isA<DioException>()));
      expect(logoutCalled, isTrue);
    });

    test('does not invoke the logout callback on a non-401 response', () async {
      when(tokenStorage.readAccessToken).thenAnswer((_) async => 'a-token');
      var logoutCalled = false;

      final dio = _buildDio(
        tokenStorage: tokenStorage,
        logout: () => logoutCalled = true,
        statusCode: 200,
      );

      await dio.get<void>('/ping');

      expect(logoutCalled, isFalse);
    });
  });
}
