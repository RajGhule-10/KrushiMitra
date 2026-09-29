import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'models/farm.dart';
import 'models/farm_create_request.dart';
import 'models/farm_update_request.dart';

class FarmApi {
  FarmApi(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Farm>> getFarms() async {
    final response = await _apiClient.dio.get(ApiEndpoints.farms);

    final farms = response.data as List<dynamic>;

    return farms
        .map((farm) => Farm.fromJson(farm as Map<String, dynamic>))
        .toList();
  }

  Future<Farm> getFarm(String farmId) async {
    final response = await _apiClient.dio.get(ApiEndpoints.farm(farmId));

    return Farm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Farm> createFarm(FarmCreateRequest request) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.farms,
      data: request.toJson(),
    );

    return Farm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Farm> updateFarm(String farmId, FarmUpdateRequest request) async {
    final response = await _apiClient.dio.patch(
      ApiEndpoints.farm(farmId),
      data: request.toJson(),
    );

    return Farm.fromJson(response.data as Map<String, dynamic>);
  }
}
