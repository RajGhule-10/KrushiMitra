import 'farm_api.dart';
import 'farm_repository_contract.dart';
import 'models/farm.dart';
import 'models/farm_create_request.dart';
import 'models/farm_update_request.dart';

class FarmRepository implements FarmRepositoryContract {
  FarmRepository(this._api);

  final FarmApi _api;

  @override
  Future<List<Farm>> getFarms() {
    return _api.getFarms();
  }

  @override
  Future<Farm> getFarm(String farmId) {
    return _api.getFarm(farmId);
  }

  @override
  Future<Farm> createFarm(FarmCreateRequest request) {
    return _api.createFarm(request);
  }

  @override
  Future<Farm> updateFarm(String farmId, FarmUpdateRequest request) {
    return _api.updateFarm(farmId, request);
  }
}
