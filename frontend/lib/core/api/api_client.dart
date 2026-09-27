import 'package:dio/dio.dart';

import '../storage/token_store.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient({required TokenStore tokenStore, String? baseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? 'http://127.0.0.1:8000',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    _dio.interceptors.add(AuthInterceptor(tokenStore));
  }

  final Dio _dio;

  Dio get dio => _dio;
}
