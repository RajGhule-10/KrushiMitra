import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_store.dart';

class TokenStorage implements TokenStore {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  @override
  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  @override
  Future<void> clearAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }
}
