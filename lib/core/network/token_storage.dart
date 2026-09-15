import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraction over the secure-storage access token, so interceptors can be
/// unit-tested without touching platform channels.
abstract class TokenStorage {
  Future<String?> readAccessToken();
}

/// [TokenStorage] backed by `flutter_secure_storage`.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String accessTokenKey = 'access_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: accessTokenKey);
}
