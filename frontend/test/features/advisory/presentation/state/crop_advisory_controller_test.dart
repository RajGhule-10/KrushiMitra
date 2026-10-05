import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/advisory/data/advisory_providers.dart';
import 'package:frontend/features/advisory/data/advisory_repository_contract.dart';
import 'package:frontend/features/advisory/data/models/crop_advisory.dart';
import 'package:frontend/features/advisory/presentation/state/crop_advisory_controller.dart';
import 'package:frontend/features/advisory/presentation/state/crop_advisory_state.dart';

class _FakeAdvisoryRepository implements AdvisoryRepositoryContract {
  _FakeAdvisoryRepository({this.result, this.shouldThrow = false});

  final CropAdvisory? result;
  final bool shouldThrow;

  @override
  Future<CropAdvisory> getCropAdvisory(String cropId) async {
    if (shouldThrow) {
      throw Exception('boom');
    }
    return result!;
  }
}

void main() {
  final advisoryPresent = CropAdvisory(
    cropId: 'crop-1',
    advisory: AdvisoryItem(
      id: 'advisory-1',
      cropId: 'crop-1',
      observationId: 'obs-1',
      title: 'Irrigation recommended',
      message: 'Soil moisture indicators suggest irrigation soon.',
      severity: 'Medium',
      priority: 'High',
      category: 'Irrigation',
      isRead: false,
      createdAt: DateTime(2026, 9, 20),
    ),
  );

  const advisoryEmpty = CropAdvisory(cropId: 'crop-1');

  test('loadCropAdvisory sets a loaded state on success', () async {
    final container = ProviderContainer(
      overrides: [
        advisoryRepositoryProvider.overrideWithValue(
          _FakeAdvisoryRepository(result: advisoryPresent),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(cropAdvisoryControllerProvider.notifier)
        .loadCropAdvisory('crop-1');

    final state = container.read(cropAdvisoryControllerProvider);
    expect(state, isA<CropAdvisoryLoaded>());
    expect((state as CropAdvisoryLoaded).data.advisory, isNotNull);
  });

  test(
    'loadCropAdvisory treats a null advisory as loaded, not an error',
    () async {
      final container = ProviderContainer(
        overrides: [
          advisoryRepositoryProvider.overrideWithValue(
            _FakeAdvisoryRepository(result: advisoryEmpty),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(cropAdvisoryControllerProvider.notifier)
          .loadCropAdvisory('crop-1');

      final state = container.read(cropAdvisoryControllerProvider);
      expect(state, isA<CropAdvisoryLoaded>());
      expect((state as CropAdvisoryLoaded).data.advisory, isNull);
    },
  );

  test('loadCropAdvisory sets a friendly error state on failure', () async {
    final container = ProviderContainer(
      overrides: [
        advisoryRepositoryProvider.overrideWithValue(
          _FakeAdvisoryRepository(shouldThrow: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(cropAdvisoryControllerProvider.notifier)
        .loadCropAdvisory('crop-1');

    final state = container.read(cropAdvisoryControllerProvider);
    expect(state, isA<CropAdvisoryError>());
    expect(
      (state as CropAdvisoryError).message,
      'Unable to load the crop advisory. Please try again.',
    );
  });

  test('retry after an error can recover to a loaded state', () async {
    final failingRepository = _FakeAdvisoryRepository(shouldThrow: true);
    final container = ProviderContainer(
      overrides: [
        advisoryRepositoryProvider.overrideWithValue(failingRepository),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(cropAdvisoryControllerProvider.notifier);

    await notifier.loadCropAdvisory('crop-1');
    expect(
      container.read(cropAdvisoryControllerProvider),
      isA<CropAdvisoryError>(),
    );

    container.updateOverrides([
      advisoryRepositoryProvider.overrideWithValue(
        _FakeAdvisoryRepository(result: advisoryPresent),
      ),
    ]);

    await notifier.loadCropAdvisory('crop-1');
    expect(
      container.read(cropAdvisoryControllerProvider),
      isA<CropAdvisoryLoaded>(),
    );
  });
}
