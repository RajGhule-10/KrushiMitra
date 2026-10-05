import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'models/crop_advisory.dart';

class AdvisoryApi {
  AdvisoryApi(this._client);

  final ApiClient _client;

  Future<CropAdvisory> getCropAdvisory(String cropId) async {
    final response = await _client.dio.get(ApiEndpoints.cropAdvisory(cropId));

    return CropAdvisory.fromJson(response.data as Map<String, dynamic>);
  }
}
