class ApiEndpoints {
  ApiEndpoints._();

  static const String authRegister = '/api/v1/auth/register';
  static const String authLogin = '/api/v1/auth/login';
  static const String authMe = '/api/v1/auth/me';

  static const String farmerProfile = '/api/v1/farmer/profile';

  static const String farms = '/api/v1/farms';

  static String farm(String farmId) => '$farms/$farmId';

  static String farmBoundary(String farmId) => '$farms/$farmId/boundary';

  static const String crops = '/api/v1/crops';

  static String farmCrops(String farmId) => '$farms/$farmId/crops';

  static String crop(String cropId) => '$crops/$cropId';

  static String cropHealth(String cropId) => '$crops/$cropId/health';

  static String cropHealthAnalysis(String cropId) => '$crops/$cropId/analyze';

  static String cropHealthHistory(String cropId) =>
      '$crops/$cropId/health/history';

  static String cropHealthTrend(String cropId) => '$crops/$cropId/health/trend';

  static String cropHealthMap(String cropId) => '$crops/$cropId/health/map';

  static String cropAdvisory(String cropId) => '$crops/$cropId/advisory';
}
