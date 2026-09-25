import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/network/index.dart';
import 'package:hoffman/features/auth/index.dart';

import '../../helpers/app_harness.dart';

const _me = 'GET /api/v1/auth/me';
const _meOk = FakeResponse(200, {'user': testUserJson});
const _user = AuthUser(id: 1, name: 'Kate', email: 'kate@example.com');

void main() {
  late TestEnvironment env;
  late ProviderContainer container;

  void start({String? token, Map<String, FakeResponse> routes = const {}}) {
    env = TestEnvironment(token: token, backend: FakeBackend(routes));
    container = env.createContainer();
  }

  Future<AuthState> restore() => container.read(authControllerProvider.future);

  group('session restore (build)', () {
    test('no stored token → Unauthenticated without a request', () async {
      start();

      expect(await restore(), const Unauthenticated());
      expect(env.backend.requests, isEmpty);
    });

    test('stored token + /auth/me 200 → Authenticated', () async {
      start(token: 't', routes: {_me: _meOk});

      expect(await restore(), const Authenticated(_user));
    });

    test(
      'stored token rejected (401) → Unauthenticated, token deleted',
      () async {
        start(
          token: 't',
          routes: {_me: FakeResponse.error(401, 'UNAUTHENTICATED')},
        );

        expect(await restore(), const Unauthenticated());
        expect(env.tokenStorage.token, isNull);
      },
    );

    test('blocked account (403) → Unauthenticated, token deleted', () async {
      start(
        token: 't',
        routes: {_me: FakeResponse.error(403, 'ACCOUNT_BLOCKED')},
      );

      expect(await restore(), const Unauthenticated());
      expect(env.tokenStorage.token, isNull);
    });

    test('offline → error (for the splash retry), token kept', () async {
      start(token: 't', routes: {_me: _meOk});
      env.backend.offline = true;

      await expectLater(
        restore(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            AuthErrorCode.network,
          ),
        ),
      );
      expect(env.tokenStorage.token, 't');
    });
  });

  group('login / register / logout', () {
    test('login stores the token and authenticates', () async {
      start(routes: {'POST /api/v1/auth/login': authSuccess});
      await restore();

      await container
          .read(authControllerProvider.notifier)
          .login(email: 'kate@example.com', password: 'secret1!');

      expect(env.tokenStorage.token, 'new-token');
      expect(
        container.read(authControllerProvider).value,
        const Authenticated(_user),
      );
    });

    test('failed login throws and leaves the state untouched', () async {
      start(
        routes: {
          'POST /api/v1/auth/login': FakeResponse.error(
            401,
            'INVALID_CREDENTIALS',
          ),
        },
      );
      await restore();

      await expectLater(
        container
            .read(authControllerProvider.notifier)
            .login(email: 'kate@example.com', password: 'nope'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            AuthErrorCode.invalidCredentials,
          ),
        ),
      );
      expect(
        container.read(authControllerProvider).value,
        const Unauthenticated(),
      );
      expect(env.tokenStorage.token, isNull);
    });

    test('register marks the session as just registered', () async {
      start(routes: {'POST /api/v1/auth/register': authSuccess});
      await restore();

      await container
          .read(authControllerProvider.notifier)
          .register(
            name: 'Kate',
            email: 'kate@example.com',
            password: 'secret1!',
            passwordConfirmation: 'secret1!',
          );

      expect(
        container.read(authControllerProvider).value,
        const Authenticated(_user, justRegistered: true),
      );
      expect(env.tokenStorage.token, 'new-token');
    });

    test(
      'logout deletes the token even when the backend is unreachable',
      () async {
        start(token: 't', routes: {_me: _meOk});
        await restore();
        env.backend.offline = true;

        await container.read(authControllerProvider.notifier).logout();

        expect(env.tokenStorage.token, isNull);
        expect(
          container.read(authControllerProvider).value,
          const Unauthenticated(),
        );
      },
    );
  });

  test('a 401 on any request signs the user out (expired session)', () async {
    start(
      token: 't',
      routes: {
        _me: _meOk,
        'GET /api/v1/diary': FakeResponse.error(401, 'UNAUTHENTICATED'),
      },
    );
    await restore();

    await expectLater(
      container.read(dioProvider).get<void>('/api/v1/diary'),
      throwsA(isA<DioException>()),
    );
    await pumpEventQueue();

    expect(
      container.read(authControllerProvider).value,
      const Unauthenticated(),
    );
    expect(env.tokenStorage.token, isNull);
  });
}
