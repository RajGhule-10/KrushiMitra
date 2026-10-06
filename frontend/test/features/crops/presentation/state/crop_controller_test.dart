import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/crops/data/crop_providers.dart';
import 'package:frontend/features/crops/data/crop_repository_contract.dart';
import 'package:frontend/features/crops/data/models/crop.dart';
import 'package:frontend/features/crops/data/models/crop_create_request.dart';
import 'package:frontend/features/crops/data/models/crop_update_request.dart';
import 'package:frontend/features/crops/presentation/state/crop_controller.dart';
import 'package:frontend/features/crops/presentation/state/crop_state.dart';

Crop _crop(String id) => Crop(
  id: id,
  farmId: 'farm-1',
  cropName: 'Wheat',
  season: 'rabi',
  status: 'active',
  createdAt: DateTime.utc(2026, 10, 1),
  updatedAt: DateTime.utc(2026, 10, 1),
);

class _FakeCropRepository implements CropRepositoryContract {
  _FakeCropRepository({this.crops = const [], this.shouldThrow = false});

  final List<Crop> crops;
  final bool shouldThrow;

  @override
  Future<List<Crop>> getCrops(String farmId) async {
    if (shouldThrow) throw Exception('failure');
    return crops;
  }

  @override
  Future<Crop> createCrop(String farmId, CropCreateRequest request) async {
    if (shouldThrow) throw Exception('failure');
    return _crop('created');
  }

  @override
  Future<Crop> getCrop(String cropId) => throw UnimplementedError();

  @override
  Future<Crop> updateCrop(String cropId, CropUpdateRequest request) =>
      throw UnimplementedError();
}

void main() {
  test('loads crops successfully', () async {
    final container = ProviderContainer(
      overrides: [
        cropRepositoryProvider.overrideWithValue(
          _FakeCropRepository(crops: [_crop('crop-1')]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(cropControllerProvider.notifier).loadCrops('farm-1');

    expect(container.read(cropControllerProvider), isA<CropLoaded>());
    expect(
      (container.read(cropControllerProvider) as CropLoaded).crops,
      hasLength(1),
    );
  });

  test('loads an empty crop list', () async {
    final container = ProviderContainer(
      overrides: [
        cropRepositoryProvider.overrideWithValue(_FakeCropRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(cropControllerProvider.notifier).loadCrops('farm-1');

    expect(
      (container.read(cropControllerProvider) as CropLoaded).crops,
      isEmpty,
    );
  });

  test('sets a friendly error when loading fails', () async {
    final container = ProviderContainer(
      overrides: [
        cropRepositoryProvider.overrideWithValue(
          _FakeCropRepository(shouldThrow: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(cropControllerProvider.notifier).loadCrops('farm-1');

    expect(container.read(cropControllerProvider), isA<CropError>());
  });

  test('adds a successfully created crop to loaded crops', () async {
    final container = ProviderContainer(
      overrides: [
        cropRepositoryProvider.overrideWithValue(_FakeCropRepository()),
      ],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(cropControllerProvider.notifier)
        .createCrop(
          'farm-1',
          const CropCreateRequest(cropName: 'Wheat', season: 'rabi'),
        );

    expect(success, isTrue);
    expect(
      (container.read(cropControllerProvider) as CropLoaded).crops.single.id,
      'created',
    );
  });
}
