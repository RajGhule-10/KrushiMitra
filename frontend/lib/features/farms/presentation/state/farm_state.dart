import '../../data/models/farm.dart';

sealed class FarmState {
  const FarmState();
}

class FarmInitial extends FarmState {
  const FarmInitial();
}

class FarmLoading extends FarmState {
  const FarmLoading();
}

class FarmLoaded extends FarmState {
  const FarmLoaded(this.farms);

  final List<Farm> farms;
}

class FarmError extends FarmState {
  const FarmError(this.message);

  final String message;
}

class FarmCreating extends FarmState {
  const FarmCreating(this.farms);

  final List<Farm> farms;
}

class FarmUpdating extends FarmState {
  const FarmUpdating(this.farms);

  final List<Farm> farms;
}
