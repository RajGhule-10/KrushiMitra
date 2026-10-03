import '../../data/models/crop_health.dart';
import '../../data/models/crop_health_history_item.dart';
import '../../data/models/crop_health_trend.dart';

sealed class CropHealthState {
  const CropHealthState();
}

class CropHealthInitial extends CropHealthState {
  const CropHealthInitial();
}

class CropHealthLoading extends CropHealthState {
  const CropHealthLoading();
}

/// Holds whichever of the three crop-health pieces have been loaded so
/// far. Fields are independently nullable because the latest-health,
/// history, and trend endpoints are loaded separately; loading one
/// does not clear the others.
class CropHealthLoaded extends CropHealthState {
  const CropHealthLoaded({this.cropHealth, this.history, this.trend});

  final CropHealth? cropHealth;
  final List<CropHealthHistoryItem>? history;
  final CropHealthTrend? trend;
}

class CropHealthError extends CropHealthState {
  const CropHealthError(this.message);

  final String message;
}
