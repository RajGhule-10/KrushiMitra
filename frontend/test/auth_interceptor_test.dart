import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/api/auth_interceptor.dart';
import 'package:frontend/core/storage/token_store.dart';

class FakeTokenStore implements TokenStore {
  String? token;

  @override
  Future<void> saveAccessToken(String token) async {
    this.token = token;
  }

  @override
  Future<String?> getAccessToken() async {
    return token;
  }

  @override
  Future<void> clearAccessToken() async {
    token = null;
  }
}

class TestRequestInterceptorHandler extends RequestInterceptorHandler {
  TestRequestInterceptorHandler({this.onNext});

  final void Function()? onNext;

  @override
  void next(RequestOptions request) {
    onNext?.call();
  }
}

void main() {
  test('adds bearer token when token exists', () async {
    final tokenStore = FakeTokenStore()..token = 'test-token';

    final interceptor = AuthInterceptor(tokenStore);

    final options = RequestOptions(path: '/test');

    var continued = false;

    final handler = TestRequestInterceptorHandler(
      onNext: () {
        continued = true;
      },
    );

    await interceptor.onRequest(options, handler);

    expect(options.headers['Authorization'], 'Bearer test-token');

    expect(continued, true);
  });

  test('does not add authorization when token is absent', () async {
    final tokenStore = FakeTokenStore();

    final interceptor = AuthInterceptor(tokenStore);

    final options = RequestOptions(path: '/test');

    final handler = TestRequestInterceptorHandler();

    await interceptor.onRequest(options, handler);

    expect(options.headers.containsKey('Authorization'), false);
  });
}
