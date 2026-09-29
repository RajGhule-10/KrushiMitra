import 'models/farm.dart';
import 'models/farm_create_request.dart';
import 'models/farm_update_request.dart';

abstract interface class FarmRepositoryContract {
  Future<List<Farm>> getFarms();

  Future<Farm> getFarm(String farmId);

  Future<Farm> createFarm(FarmCreateRequest request);

  Future<Farm> updateFarm(String farmId, FarmUpdateRequest request);
}
