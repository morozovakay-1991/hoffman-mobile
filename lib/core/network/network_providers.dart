import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/core/network/dio_client.dart';
import 'package:hoffman/core/network/token_storage.dart';

/// Secure storage for the bearer token. Overridden with a fake in tests.
final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);

/// Counts 401 responses from the backend. `AuthController` listens to it to
/// drop the session; kept in core so the network layer does not depend on
/// the auth feature.
final sessionExpiredProvider = NotifierProvider<SessionExpiredNotifier, int>(
  SessionExpiredNotifier.new,
);

class SessionExpiredNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void notify() => state++;
}

/// App-wide [Dio] built by [DioClient].
final dioProvider = Provider<Dio>((ref) {
  final client = DioClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    onLogout: () => ref.read(sessionExpiredProvider.notifier).notify(),
  );
  ref.onDispose(client.dio.close);
  return client.dio;
});
