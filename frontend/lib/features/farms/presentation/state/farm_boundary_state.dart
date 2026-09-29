import '../../data/models/farm_boundary.dart';

sealed class FarmBoundaryState {
  const FarmBoundaryState();
}

class FarmBoundaryInitial extends FarmBoundaryState {
  const FarmBoundaryInitial();
}

class FarmBoundaryLoading extends FarmBoundaryState {
  const FarmBoundaryLoading();
}

class FarmBoundaryEmpty extends FarmBoundaryState {
  const FarmBoundaryEmpty();
}

class FarmBoundaryLoaded extends FarmBoundaryState {
  const FarmBoundaryLoaded(this.boundary);

  final FarmBoundary boundary;
}

class FarmBoundarySaving extends FarmBoundaryState {
  const FarmBoundarySaving({this.boundary});

  final FarmBoundary? boundary;
}

class FarmBoundaryError extends FarmBoundaryState {
  const FarmBoundaryError(this.message, {this.boundary});

  final String message;
  final FarmBoundary? boundary;
}
