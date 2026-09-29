import 'models/farm_boundary.dart';

abstract interface class FarmBoundaryRepositoryContract {
  Future<FarmBoundary> getBoundary(String farmId);

  Future<FarmBoundary> saveBoundary(
    String farmId,
    Map<String, dynamic> geometry,
  );
}
