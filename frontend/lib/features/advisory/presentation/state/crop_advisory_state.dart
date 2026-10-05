import '../../data/models/crop_advisory.dart';

sealed class CropAdvisoryState {
  const CropAdvisoryState();
}

class CropAdvisoryInitial extends CropAdvisoryState {
  const CropAdvisoryInitial();
}

class CropAdvisoryLoading extends CropAdvisoryState {
  const CropAdvisoryLoading();
}

/// `data.advisory` may be null — that is a normal empty state
/// (no advisory available yet), handled by the screen, not an error.
class CropAdvisoryLoaded extends CropAdvisoryState {
  const CropAdvisoryLoaded(this.data);

  final CropAdvisory data;
}

class CropAdvisoryError extends CropAdvisoryState {
  const CropAdvisoryError(this.message);

  final String message;
}
