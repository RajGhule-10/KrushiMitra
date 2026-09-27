import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/authentication/data/auth_error_mapper.dart';

void main() {
  test('maps 401 to invalid credentials message', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/login'),
      response: Response(
        requestOptions: RequestOptions(path: '/login'),
        statusCode: 401,
      ),
    );

    expect(mapAuthError(error), 'Mobile number or password is incorrect.');
  });

  test('maps 422 to validation message', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/login'),
      response: Response(
        requestOptions: RequestOptions(path: '/login'),
        statusCode: 422,
      ),
    );

    expect(mapAuthError(error), 'Please check the details you entered.');
  });

  test('maps connection error', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/login'),
      type: DioExceptionType.connectionError,
    );

    expect(
      mapAuthError(error),
      'Unable to connect to KrushiMitra. Check your internet connection.',
    );
  });

  test('maps timeout error', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/login'),
      type: DioExceptionType.connectionTimeout,
    );

    expect(
      mapAuthError(error),
      'The connection is taking too long. Please try again.',
    );
  });

  test('maps unknown errors to generic message', () {
    expect(
      mapAuthError(Exception('unexpected failure')),
      'Something went wrong. Please try again.',
    );
  });
}
