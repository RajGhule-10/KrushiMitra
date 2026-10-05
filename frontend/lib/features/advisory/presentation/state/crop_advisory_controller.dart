import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/advisory_providers.dart';
import 'crop_advisory_state.dart';

final cropAdvisoryControllerProvider =
    NotifierProvider<CropAdvisoryController, CropAdvisoryState>(
      CropAdvisoryController.new,
    );

class CropAdvisoryController extends Notifier<CropAdvisoryState> {
  @override
  CropAdvisoryState build() {
    return const CropAdvisoryInitial();
  }

  Future<void> loadCropAdvisory(String cropId) async {
    state = const CropAdvisoryLoading();

    try {
      final data = await ref
          .read(advisoryRepositoryProvider)
          .getCropAdvisory(cropId);

      state = CropAdvisoryLoaded(data);
    } catch (error) {
      state = const CropAdvisoryError(
        'Unable to load the crop advisory. Please try again.',
      );
    }
  }
}
