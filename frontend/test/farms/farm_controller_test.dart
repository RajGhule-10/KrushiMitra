import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/farms/data/farm_repository_contract.dart';
import 'package:frontend/features/farms/data/models/farm.dart';
import 'package:frontend/features/farms/data/models/farm_create_request.dart';
import 'package:frontend/features/farms/data/models/farm_update_request.dart';
import 'package:frontend/features/farms/presentation/state/farm_controller.dart';
import 'package:frontend/features/farms/presentation/state/farm_state.dart';
import 'package:frontend/features/farms/data/farm_providers.dart';

class FakeFarmRepository implements FarmRepositoryContract {
  FakeFarmRepository({List<Farm>? farms})
    : farms = List<Farm>.from(farms ?? []);

  List<Farm> farms;

  @override
  Future<List<Farm>> getFarms() async {
    return List<Farm>.from(farms);
  }

  @override
  Future<Farm> getFarm(String farmId) async {
    return farms.firstWhere((farm) => farm.id == farmId);
  }

  @override
  Future<Farm> createFarm(FarmCreateRequest request) async {
    final farm = Farm(
      id: 'new-farm-id',
      name: request.name,
      gatNumber: request.gatNumber,
      areaHectares: request.areaHectares,
      village: request.village,
      district: request.district,
      state: request.state,
      createdAt: DateTime.utc(2026, 9, 29),
      updatedAt: DateTime.utc(2026, 9, 29),
    );

    farms.add(farm);
    return farm;
  }

  @override
  Future<Farm> updateFarm(String farmId, FarmUpdateRequest request) async {
    final index = farms.indexWhere((farm) => farm.id == farmId);

    final existing = farms[index];

    final updatedFarm = Farm(
      id: existing.id,
      name: request.name ?? existing.name,
      gatNumber: request.gatNumber ?? existing.gatNumber,
      areaHectares: request.areaHectares ?? existing.areaHectares,
      village: request.village ?? existing.village,
      district: request.district ?? existing.district,
      state: request.state ?? existing.state,
      createdAt: existing.createdAt,
      updatedAt: DateTime.utc(2026, 9, 29),
    );

    farms[index] = updatedFarm;

    return updatedFarm;
  }
}

Farm createTestFarm({String id = 'farm-1', String name = 'Farm A'}) {
  return Farm(
    id: id,
    name: name,
    gatNumber: 'GAT-1',
    areaHectares: 2.5,
    village: 'Loni',
    district: 'Pune',
    state: 'Maharashtra',
    createdAt: DateTime.utc(2026, 9, 29),
    updatedAt: DateTime.utc(2026, 9, 29),
  );
}

void main() {
  test('loads farms successfully', () async {
    final repository = FakeFarmRepository(farms: [createTestFarm()]);

    final container = ProviderContainer(
      overrides: [farmRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(farmControllerProvider.notifier);

    await controller.loadFarms();

    final state = container.read(farmControllerProvider);

    expect(state, isA<FarmLoaded>());

    final loadedState = state as FarmLoaded;

    expect(loadedState.farms.length, 1);
    expect(loadedState.farms.first.name, 'Farm A');
  });

  test('creates a farm and adds it to the current list', () async {
    final repository = FakeFarmRepository(farms: [createTestFarm()]);

    final container = ProviderContainer(
      overrides: [farmRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(farmControllerProvider.notifier);

    await controller.loadFarms();

    await controller.createFarm(
      const FarmCreateRequest(name: 'Farm B', areaHectares: 3.2),
    );

    final state = container.read(farmControllerProvider);

    expect(state, isA<FarmLoaded>());

    final loadedState = state as FarmLoaded;

    expect(loadedState.farms.length, 2);
    expect(loadedState.farms.last.name, 'Farm B');
  });

  test('updates the correct farm', () async {
    final repository = FakeFarmRepository(
      farms: [
        createTestFarm(),
        createTestFarm(id: 'farm-2', name: 'Farm B'),
      ],
    );

    final container = ProviderContainer(
      overrides: [farmRepositoryProvider.overrideWithValue(repository)],
    );

    addTearDown(container.dispose);

    final controller = container.read(farmControllerProvider.notifier);

    await controller.loadFarms();

    await controller.updateFarm(
      'farm-2',
      const FarmUpdateRequest(name: 'Updated Farm B'),
    );

    final state = container.read(farmControllerProvider);

    expect(state, isA<FarmLoaded>());

    final loadedState = state as FarmLoaded;

    expect(loadedState.farms[0].name, 'Farm A');

    expect(loadedState.farms[1].name, 'Updated Farm B');
  });
}
