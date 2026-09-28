import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'models/farmer_profile.dart';
import 'models/farmer_profile_update_request.dart';

class FarmerProfileApi {
  FarmerProfileApi(this._apiClient);

  final ApiClient _apiClient;

  Future<FarmerProfile> getProfile() async {
    final response = await _apiClient.dio.get(ApiEndpoints.farmerProfile);

    return FarmerProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FarmerProfile> updateProfile(
    FarmerProfileUpdateRequest request,
  ) async {
    final response = await _apiClient.dio.patch(
      ApiEndpoints.farmerProfile,
      data: request.toJson(),
    );

    return FarmerProfile.fromJson(response.data as Map<String, dynamic>);
  }
}
