import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'models/farm_boundary.dart';

class FarmBoundaryApi {
  FarmBoundaryApi(this._apiClient);

  final ApiClient _apiClient;

  Future<FarmBoundary> getBoundary(String farmId) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.farmBoundary(farmId),
    );

    return FarmBoundary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FarmBoundary> saveBoundary(
    String farmId,
    Map<String, dynamic> geometry,
  ) async {
    final response = await _apiClient.dio.put(
      ApiEndpoints.farmBoundary(farmId),
      data: geometry,
    );

    return FarmBoundary.fromJson(response.data as Map<String, dynamic>);
  }
}
