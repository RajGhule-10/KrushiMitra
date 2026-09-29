import 'farm_boundary_api.dart';
import 'farm_boundary_repository_contract.dart';
import 'models/farm_boundary.dart';

class FarmBoundaryRepository implements FarmBoundaryRepositoryContract {
  FarmBoundaryRepository(this._api);

  final FarmBoundaryApi _api;

  @override
  Future<FarmBoundary> getBoundary(String farmId) {
    return _api.getBoundary(farmId);
  }

  @override
  Future<FarmBoundary> saveBoundary(
    String farmId,
    Map<String, dynamic> geometry,
  ) {
    return _api.saveBoundary(farmId, geometry);
  }
}
