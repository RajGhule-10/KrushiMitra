class ApiEndpoints {
  ApiEndpoints._();

  static const String authRegister = '/api/v1/auth/register';
  static const String authLogin = '/api/v1/auth/login';
  static const String authMe = '/api/v1/auth/me';

  static const String farmerProfile = '/api/v1/farmer/profile';

  static const String farms = '/api/v1/farms';

  static String farm(String farmId) => '$farms/$farmId';

  static String farmBoundary(String farmId) => '$farms/$farmId/boundary';
}
