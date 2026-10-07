import 'models/crop_health.dart';
import 'models/crop_health_analysis.dart';
import 'models/crop_health_history_item.dart';
import 'models/crop_health_map.dart';
import 'models/crop_health_trend.dart';

abstract interface class CropHealthRepositoryContract {
  Future<CropHealthAnalysis> analyzeCropHealth(String cropId);

  Future<CropHealth> getCropHealth(String cropId);

  Future<List<CropHealthHistoryItem>> getCropHealthHistory(String cropId);

  Future<CropHealthTrend> getCropHealthTrend(String cropId);

  Future<CropHealthMap> getCropHealthMap(String cropId);
}
