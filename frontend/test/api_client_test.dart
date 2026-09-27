import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/api/api_client.dart';
import 'package:frontend/core/storage/token_store.dart';

class FakeTokenStore implements TokenStore {
  @override
  Future<void> saveAccessToken(String token) async {}

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<void> clearAccessToken() async {}
}

void main() {
  test('creates API client with the development backend URL', () {
    final client = ApiClient(tokenStore: FakeTokenStore());

    expect(client.dio.options.baseUrl, 'http://127.0.0.1:8000');

    expect(client.dio.options.headers['Content-Type'], 'application/json');
  });

  test('creates API client with a custom backend URL', () {
    final client = ApiClient(
      tokenStore: FakeTokenStore(),
      baseUrl: 'http://10.0.2.2:8000',
    );

    expect(client.dio.options.baseUrl, 'http://10.0.2.2:8000');
  });
}
