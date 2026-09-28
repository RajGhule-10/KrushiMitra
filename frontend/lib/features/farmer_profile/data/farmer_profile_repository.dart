import 'farmer_profile_api.dart';
import 'farmer_profile_repository_contract.dart';
import 'models/farmer_profile.dart';
import 'models/farmer_profile_update_request.dart';

class FarmerProfileRepository implements FarmerProfileRepositoryContract {
  FarmerProfileRepository(this._api);

  final FarmerProfileApi _api;

  @override
  Future<FarmerProfile> getProfile() {
    return _api.getProfile();
  }

  @override
  Future<FarmerProfile> updateProfile(FarmerProfileUpdateRequest request) {
    return _api.updateProfile(request);
  }
}
