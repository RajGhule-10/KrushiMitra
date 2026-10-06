import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/crop_providers.dart';
import '../../data/models/crop.dart';
import '../../data/models/crop_create_request.dart';
import '../../data/models/crop_update_request.dart';
import 'crop_state.dart';

final cropControllerProvider = NotifierProvider<CropController, CropState>(
  CropController.new,
);

class CropController extends Notifier<CropState> {
  @override
  CropState build() => const CropInitial();

  Future<void> loadCrops(String farmId) async {
    state = const CropLoading();
    try {
      state = CropLoaded(
        await ref.read(cropRepositoryProvider).getCrops(farmId),
      );
    } catch (_) {
      state = const CropError('Unable to load your crops. Please try again.');
    }
  }

  Future<bool> createCrop(String farmId, CropCreateRequest request) async {
    final existing = state is CropLoaded
        ? (state as CropLoaded).crops
        : state is CropCreating
        ? (state as CropCreating).crops
        : <Crop>[];
    state = CropCreating(existing);
    try {
      final crop = await ref
          .read(cropRepositoryProvider)
          .createCrop(farmId, request);
      state = CropLoaded([...existing, crop]);
      return true;
    } catch (_) {
      state = CropError(
        'Unable to create your crop. Please try again.',
        crops: existing,
      );
      return false;
    }
  }

  Future<void> updateCrop(String cropId, CropUpdateRequest request) async {
    final current = state;
    if (current is! CropLoaded) return;
    try {
      final updated = await ref
          .read(cropRepositoryProvider)
          .updateCrop(cropId, request);
      state = CropLoaded(
        current.crops
            .map((crop) => crop.id == cropId ? updated : crop)
            .toList(),
      );
    } catch (_) {
      state = CropError(
        'Unable to update your crop. Please try again.',
        crops: current.crops,
      );
    }
  }
}
