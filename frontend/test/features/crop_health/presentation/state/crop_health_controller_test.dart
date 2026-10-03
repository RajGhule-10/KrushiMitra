import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/crop_health/data/crop_health_providers.dart';
import 'package:frontend/features/crop_health/data/crop_health_repository_contract.dart';
import 'package:frontend/features/crop_health/data/models/crop_health.dart';
import 'package:frontend/features/crop_health/data/models/crop_health_history_item.dart';
import 'package:frontend/features/crop_health/data/models/crop_health_trend.dart';
import 'package:frontend/features/crop_health/presentation/state/crop_health_controller.dart';
import 'package:frontend/features/crop_health/presentation/state/crop_health_state.dart';

class _FakeCropHealthRepository implements CropHealthRepositoryContract {
  _FakeCropHealthRepository({
    this.cropHealthResult,
    this.historyResult,
    this.trendResult,
    this.shouldThrow = false,
  });

  final CropHealth? cropHealthResult;
  final List<CropHealthHistoryItem>? historyResult;
  final CropHealthTrend? trendResult;
  final bool shouldThrow;

  @override
  Future<CropHealth> getCropHealth(String cropId) async {
    if (shouldThrow) {
      throw Exception('boom');
    }
    return cropHealthResult!;
  }

  @override
  Future<List<CropHealthHistoryItem>> getCropHealthHistory(
    String cropId,
  ) async {
    if (shouldThrow) {
      throw Exception('boom');
    }
    return historyResult!;
  }

  @override
  Future<CropHealthTrend> getCropHealthTrend(String cropId) async {
    if (shouldThrow) {
      throw Exception('boom');
    }
    return trendResult!;
  }
}

void main() {
  const cropHealth = CropHealth(cropId: 'crop-1', cropName: 'Wheat');
  final historyItem = CropHealthHistoryItem(
    observationDate: DateTime(2026, 9, 20),
    dataSource: 'sentinel-2',
    cloudPercentage: 8.25,
    ndviMean: 0.65,
    healthStatus: 'Good',
  );
  const trend = CropHealthTrend(
    cropId: 'crop-1',
    direction: 'Improving',
    firstNdvi: 0.20,
    latestNdvi: 0.80,
    change: 0.60,
    observationCount: 2,
  );

  test('loadCropHealth sets a loaded state on success', () async {
    final container = ProviderContainer(
      overrides: [
        cropHealthRepositoryProvider.overrideWithValue(
          _FakeCropHealthRepository(cropHealthResult: cropHealth),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(cropHealthControllerProvider.notifier)
        .loadCropHealth('crop-1');

    final state = container.read(cropHealthControllerProvider);
    expect(state, isA<CropHealthLoaded>());
    expect((state as CropHealthLoaded).cropHealth, cropHealth);
  });

  test('loadCropHealth sets a friendly error state on failure', () async {
    final container = ProviderContainer(
      overrides: [
        cropHealthRepositoryProvider.overrideWithValue(
          _FakeCropHealthRepository(shouldThrow: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(cropHealthControllerProvider.notifier)
        .loadCropHealth('crop-1');

    final state = container.read(cropHealthControllerProvider);
    expect(state, isA<CropHealthError>());
    expect(
      (state as CropHealthError).message,
      'Unable to load crop health. Please try again.',
    );
  });

  test('loading history preserves a previously loaded crop health', () async {
    final container = ProviderContainer(
      overrides: [
        cropHealthRepositoryProvider.overrideWithValue(
          _FakeCropHealthRepository(
            cropHealthResult: cropHealth,
            historyResult: [historyItem],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(cropHealthControllerProvider.notifier);

    await notifier.loadCropHealth('crop-1');
    await notifier.loadCropHealthHistory('crop-1');

    final state =
        container.read(cropHealthControllerProvider) as CropHealthLoaded;
    expect(state.cropHealth, cropHealth);
    expect(state.history, [historyItem]);
  });

  test('loadCropHealthTrend sets a loaded state on success', () async {
    final container = ProviderContainer(
      overrides: [
        cropHealthRepositoryProvider.overrideWithValue(
          _FakeCropHealthRepository(trendResult: trend),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(cropHealthControllerProvider.notifier)
        .loadCropHealthTrend('crop-1');

    final state = container.read(cropHealthControllerProvider);
    expect(state, isA<CropHealthLoaded>());
    expect((state as CropHealthLoaded).trend, trend);
  });
}
