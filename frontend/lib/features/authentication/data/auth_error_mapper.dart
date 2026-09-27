import 'package:dio/dio.dart';

String mapAuthError(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;

    switch (statusCode) {
      case 401:
        return 'Mobile number or password is incorrect.';
      case 422:
        return 'Please check the details you entered.';
      case 429:
        return 'Too many attempts. Please try again later.';
      case 500:
      case 502:
      case 503:
        return 'The service is temporarily unavailable. Please try again.';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'The connection is taking too long. Please try again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to KrushiMitra. Check your internet connection.';
    }

    return 'Something went wrong. Please try again.';
  }

  return 'Something went wrong. Please try again.';
}
