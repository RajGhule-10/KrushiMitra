import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/farm_providers.dart';
import '../../data/models/farm.dart';
import '../../data/models/farm_create_request.dart';
import '../../data/models/farm_update_request.dart';
import 'farm_state.dart';
import 'package:flutter/foundation.dart';

final farmControllerProvider = NotifierProvider<FarmController, FarmState>(
  FarmController.new,
);

class FarmController extends Notifier<FarmState> {
  @override
  FarmState build() {
    return const FarmInitial();
  }

  Future<void> loadFarms() async {
    state = const FarmLoading();

    try {
      final farms = await ref.read(farmRepositoryProvider).getFarms();

      state = FarmLoaded(farms);
    } catch (error) {
      state = const FarmError('Unable to load your farms. Please try again.');
    }
  }

  Future<void> createFarm(FarmCreateRequest request) async {
    final currentState = state;

    final existingFarms = currentState is FarmLoaded
        ? currentState.farms
        : <Farm>[];

    state = FarmCreating(existingFarms);

    try {
      final farm = await ref.read(farmRepositoryProvider).createFarm(request);

      state = FarmLoaded([...existingFarms, farm]);
    } catch (error, stackTrace) {
      debugPrint('CREATE FARM ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      state = FarmError('Unable to create your farm. Please try again.');
    }
  }

  Future<void> updateFarm(String farmId, FarmUpdateRequest request) async {
    final currentState = state;

    if (currentState is! FarmLoaded) {
      return;
    }

    state = FarmUpdating(currentState.farms);

    try {
      final updatedFarm = await ref
          .read(farmRepositoryProvider)
          .updateFarm(farmId, request);

      final updatedFarms = currentState.farms.map((farm) {
        if (farm.id == farmId) {
          return updatedFarm;
        }

        return farm;
      }).toList();

      state = FarmLoaded(updatedFarms);
    } catch (error) {
      state = FarmError('Unable to update your farm. Please try again.');
    }
  }
}
