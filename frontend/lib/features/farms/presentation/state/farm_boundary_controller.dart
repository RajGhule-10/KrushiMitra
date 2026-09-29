import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../data/farm_boundary_providers.dart';
import '../../data/models/farm_boundary.dart';
import 'farm_boundary_state.dart';

final farmBoundaryControllerProvider =
    NotifierProvider<FarmBoundaryController, FarmBoundaryState>(
      FarmBoundaryController.new,
    );

class FarmBoundaryController extends Notifier<FarmBoundaryState> {
  @override
  FarmBoundaryState build() {
    return const FarmBoundaryInitial();
  }

  Future<void> loadBoundary(String farmId) async {
    state = const FarmBoundaryLoading();

    try {
      final boundary = await ref
          .read(farmBoundaryRepositoryProvider)
          .getBoundary(farmId);

      if (state is FarmBoundarySaving) {
        return;
      }
      state = FarmBoundaryLoaded(boundary);
    } on DioException catch (error) {
      if (state is FarmBoundarySaving) {
        return;
      }
      if (error.response?.statusCode == 404) {
        state = const FarmBoundaryEmpty();
        return;
      }

      state = const FarmBoundaryError(
        'Unable to load the farm boundary. Please try again.',
      );
    } catch (error) {
      if (state is FarmBoundarySaving) {
        return;
      }
      state = const FarmBoundaryError(
        'Unable to load the farm boundary. Please try again.',
      );
    }
  }

  Future<void> saveBoundary(
    String farmId,
    Map<String, dynamic> geometry,
  ) async {
    final currentBoundary = _currentBoundary(state);
    state = FarmBoundarySaving(boundary: currentBoundary);

    try {
      final boundary = await ref
          .read(farmBoundaryRepositoryProvider)
          .saveBoundary(farmId, geometry);

      state = FarmBoundaryLoaded(boundary);
    } catch (error) {
      state = FarmBoundaryError(
        'Unable to save the farm boundary. Please try again.',
        boundary: currentBoundary,
      );
    }
  }

  FarmBoundary? _currentBoundary(FarmBoundaryState currentState) {
    return switch (currentState) {
      FarmBoundaryLoaded(:final boundary) => boundary,
      FarmBoundarySaving(:final boundary) => boundary,
      FarmBoundaryError(:final boundary) => boundary,
      FarmBoundaryInitial() ||
      FarmBoundaryLoading() ||
      FarmBoundaryEmpty() => null,
    };
  }
}
