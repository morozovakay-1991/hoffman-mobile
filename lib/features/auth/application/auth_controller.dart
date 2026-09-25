import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/core/network/index.dart';
import 'package:hoffman/features/auth/data/auth_repository.dart';
import 'package:hoffman/features/auth/domain/auth_exception.dart';
import 'package:hoffman/features/auth/domain/auth_user.dart';

/// Session state held by [AuthController].
@immutable
sealed class AuthState {
  const AuthState();
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();

  @override
  bool operator ==(Object other) => other is Unauthenticated;

  @override
  int get hashCode => 0;
}

final class Authenticated extends AuthState {
  const Authenticated(this.user, {this.justRegistered = false});

  final AuthUser user;

  /// True right after `/auth/register`, until the next app start or login;
  /// lets the router send the new user to `/verification` instead of home.
  final bool justRegistered;

  @override
  bool operator ==(Object other) =>
      other is Authenticated &&
      other.user == user &&
      other.justRegistered == justRegistered;

  @override
  int get hashCode => Object.hash(user, justRegistered);
}

/// App-wide auth state.
///
/// `build` restores the session: no stored token → [Unauthenticated]; a
/// token → `GET /auth/me`, which yields [Authenticated], or
/// [Unauthenticated] (and drops the token) when the backend rejects it.
/// A network failure is surfaced as `AsyncError` so the splash screen can
/// offer a retry instead of spinning forever.
///
/// [login]/[register] never put the provider into loading (the router would
/// bounce the user to the splash screen); the forms track their own
/// progress and catch the thrown [AuthException].
class AuthController extends AsyncNotifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<AuthState> build() async {
    ref.listen(
      sessionExpiredProvider,
      (_, _) => unawaited(_onSessionExpired()),
    );

    final repository = ref.watch(authRepositoryProvider);
    if (!await repository.hasToken()) return const Unauthenticated();

    try {
      return Authenticated(await repository.me());
    } on AuthException catch (e) {
      if (e.code == AuthErrorCode.network || e.code == AuthErrorCode.unknown) {
        rethrow;
      }
      // 401 (revoked/expired token) or 403 (blocked account).
      await repository.clearToken();
      return const Unauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    final user = await _repository.login(email: email, password: password);
    state = AsyncData(Authenticated(user));
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final user = await _repository.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    state = AsyncData(Authenticated(user, justRegistered: true));
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncData(Unauthenticated());
  }

  Future<void> _onSessionExpired() async {
    if (state.value is! Authenticated) return;
    await _repository.clearToken();
    state = const AsyncData(Unauthenticated());
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
  // A failed session restore is retried from the splash screen instead.
  retry: (_, _) => null,
);
