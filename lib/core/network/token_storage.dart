import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraction over the secure-storage access token, so interceptors can be
/// unit-tested without touching platform channels.
abstract class TokenStorage {
  Future<String?> readAccessToken();

  Future<void> writeAccessToken(String token);

  Future<void> deleteAccessToken();
}

/// [TokenStorage] backed by `flutter_secure_storage`.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String accessTokenKey = 'access_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: accessTokenKey);

  @override
  Future<void> writeAccessToken(String token) =>
      _storage.write(key: accessTokenKey, value: token);

  @override
  Future<void> deleteAccessToken() => _storage.delete(key: accessTokenKey);
}
