import 'crop_health_api.dart';
import 'crop_health_repository_contract.dart';
import 'models/crop_health.dart';
import 'models/crop_health_history_item.dart';
import 'models/crop_health_trend.dart';

class CropHealthRepository implements CropHealthRepositoryContract {
  CropHealthRepository(this._api);

  final CropHealthApi _api;

  @override
  Future<CropHealth> getCropHealth(String cropId) {
    return _api.getCropHealth(cropId);
  }

  @override
  Future<List<CropHealthHistoryItem>> getCropHealthHistory(String cropId) {
    return _api.getCropHealthHistory(cropId);
  }

  @override
  Future<CropHealthTrend> getCropHealthTrend(String cropId) {
    return _api.getCropHealthTrend(cropId);
  }
}
