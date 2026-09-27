import 'package:flutter_test/flutter_test.dart';

abstract class TestTokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();
  Future<void> clearAccessToken();
}

class InMemoryTokenStorage implements TestTokenStorage {
  String? _token;

  @override
  Future<void> saveAccessToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> getAccessToken() async {
    return _token;
  }

  @override
  Future<void> clearAccessToken() async {
    _token = null;
  }
}

void main() {
  test('stores and retrieves access token', () async {
    final storage = InMemoryTokenStorage();

    await storage.saveAccessToken('test-token');

    expect(await storage.getAccessToken(), 'test-token');
  });

  test('clears access token', () async {
    final storage = InMemoryTokenStorage();

    await storage.saveAccessToken('test-token');
    await storage.clearAccessToken();

    expect(await storage.getAccessToken(), isNull);
  });
}
