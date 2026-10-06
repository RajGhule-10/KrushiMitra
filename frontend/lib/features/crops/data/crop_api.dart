import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'models/crop.dart';
import 'models/crop_create_request.dart';
import 'models/crop_update_request.dart';

class CropApi {
  CropApi(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Crop>> getCrops(String farmId) async {
    final response = await _apiClient.dio.get(ApiEndpoints.farmCrops(farmId));
    final crops = response.data as List<dynamic>;
    return crops
        .map((crop) => Crop.fromJson(crop as Map<String, dynamic>))
        .toList();
  }

  Future<Crop> getCrop(String cropId) async {
    final response = await _apiClient.dio.get(ApiEndpoints.crop(cropId));
    return Crop.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Crop> createCrop(String farmId, CropCreateRequest request) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.farmCrops(farmId),
      data: request.toJson(),
    );
    return Crop.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Crop> updateCrop(String cropId, CropUpdateRequest request) async {
    final response = await _apiClient.dio.patch(
      ApiEndpoints.crop(cropId),
      data: request.toJson(),
    );
    return Crop.fromJson(response.data as Map<String, dynamic>);
  }
}
