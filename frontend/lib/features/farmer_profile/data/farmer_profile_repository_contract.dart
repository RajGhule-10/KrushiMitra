import 'models/farmer_profile.dart';
import 'models/farmer_profile_update_request.dart';

abstract interface class FarmerProfileRepositoryContract {
  Future<FarmerProfile> getProfile();

  Future<FarmerProfile> updateProfile(FarmerProfileUpdateRequest request);
}
