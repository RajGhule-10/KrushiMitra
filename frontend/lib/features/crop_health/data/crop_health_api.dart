import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'models/crop_health.dart';
import 'models/crop_health_analysis.dart';
import 'models/crop_health_history_item.dart';
import 'models/crop_health_map.dart';
import 'models/crop_health_trend.dart';

class CropHealthApi {
  CropHealthApi(this._client);

  final ApiClient _client;

  Future<CropHealthAnalysis> analyzeCropHealth(String cropId) async {
    final response = await _client.dio.post(
      ApiEndpoints.cropHealthAnalysis(cropId),
    );

    return CropHealthAnalysis.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CropHealth> getCropHealth(String cropId) async {
    final response = await _client.dio.get(ApiEndpoints.cropHealth(cropId));

    return CropHealth.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CropHealthHistoryItem>> getCropHealthHistory(
    String cropId,
  ) async {
    final response = await _client.dio.get(
      ApiEndpoints.cropHealthHistory(cropId),
    );

    final data = response.data as Map<String, dynamic>;
    final history = data['history'] as List<dynamic>;

    return history
        .map(
          (item) =>
              CropHealthHistoryItem.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<CropHealthTrend> getCropHealthTrend(String cropId) async {
    final response = await _client.dio.get(
      ApiEndpoints.cropHealthTrend(cropId),
    );

    return CropHealthTrend.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CropHealthMap> getCropHealthMap(String cropId) async {
    final response = await _client.dio.get(ApiEndpoints.cropHealthMap(cropId));

    return CropHealthMap.fromJson(response.data as Map<String, dynamic>);
  }
}
