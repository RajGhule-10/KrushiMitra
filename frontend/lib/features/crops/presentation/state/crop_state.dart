import '../../data/models/crop.dart';

sealed class CropState {
  const CropState();
}

class CropInitial extends CropState {
  const CropInitial();
}

class CropLoading extends CropState {
  const CropLoading();
}

class CropLoaded extends CropState {
  const CropLoaded(this.crops);

  final List<Crop> crops;
}

class CropCreating extends CropState {
  const CropCreating(this.crops);

  final List<Crop> crops;
}

class CropError extends CropState {
  const CropError(this.message, {this.crops = const []});

  final String message;
  final List<Crop> crops;
}
