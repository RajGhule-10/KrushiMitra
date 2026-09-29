import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/farms/data/farm_boundary_providers.dart';
import 'package:frontend/features/farms/data/farm_boundary_repository_contract.dart';
import 'package:frontend/features/farms/data/models/farm_boundary.dart';
import 'package:frontend/features/farms/presentation/state/farm_boundary_controller.dart';
import 'package:frontend/features/farms/presentation/state/farm_boundary_state.dart';

class _FakeFarmBoundaryRepository implements FarmBoundaryRepositoryContract {
  _FakeFarmBoundaryRepository({
    this.saveCompleter,
    this.loadError,
    this.saveError,
  });

  final Completer<FarmBoundary>? saveCompleter;
  final Object? loadError;
  final Object? saveError;

  String? loadedFarmId;
  String? savedFarmId;
  Map<String, dynamic>? savedGeometry;

  @override
  Future<FarmBoundary> getBoundary(String farmId) {
    loadedFarmId = farmId;
    if (loadError != null) {
      return Future<FarmBoundary>.error(loadError!);
    }
    return Future.value(_createBoundary(farmId));
  }

  @override
  Future<FarmBoundary> saveBoundary(
    String farmId,
    Map<String, dynamic> geometry,
  ) {
    savedFarmId = farmId;
    savedGeometry = geometry;
    if (saveError != null) {
      return Future<FarmBoundary>.error(saveError!);
    }
    if (saveCompleter != null) {
      return saveCompleter!.future;
    }
    return Future.value(_createBoundary(farmId, geometry: geometry));
  }

  FarmBoundary _createBoundary(
    String farmId, {
    Map<String, dynamic>? geometry,
  }) {
    final value = geometry ?? _geometry;
    return FarmBoundary(
      farmId: farmId,
      geometry: GeoJsonGeometry(
        type: value['type'] as String,
        coordinates: value['coordinates'] as List<dynamic>,
      ),
    );
  }
}

const _geometry = {
  'type': 'MultiPolygon',
  'coordinates': [
    [
      [
        [73.8, 18.5],
        [73.81, 18.5],
        [73.81, 18.51],
        [73.8, 18.5],
      ],
    ],
  ],
};

FarmBoundary _loadedBoundary() {
  return const FarmBoundary(
    farmId: 'farm-1',
    geometry: GeoJsonGeometry(type: 'MultiPolygon', coordinates: []),
  );
}

ProviderContainer _createContainer(_FakeFarmBoundaryRepository repository) {
  return ProviderContainer(
    overrides: [farmBoundaryRepositoryProvider.overrideWithValue(repository)],
  );
}

void main() {
  test('starts in the initial state', () {
    final container = _createContainer(_FakeFarmBoundaryRepository());
    addTearDown(container.dispose);

    expect(
      container.read(farmBoundaryControllerProvider),
      isA<FarmBoundaryInitial>(),
    );
  });

  test('loads a boundary successfully and passes the farm ID', () async {
    final repository = _FakeFarmBoundaryRepository();
    final container = _createContainer(repository);
    addTearDown(container.dispose);
    final controller = container.read(farmBoundaryControllerProvider.notifier);

    final load = controller.loadBoundary('farm-123');

    expect(
      container.read(farmBoundaryControllerProvider),
      isA<FarmBoundaryLoading>(),
    );
    await load;

    final state = container.read(farmBoundaryControllerProvider);
    expect(state, isA<FarmBoundaryLoaded>());
    expect(repository.loadedFarmId, 'farm-123');
  });

  test('reports a friendly error when loading fails', () async {
    final repository = _FakeFarmBoundaryRepository(
      loadError: StateError('load failed'),
    );
    final container = _createContainer(repository);
    addTearDown(container.dispose);

    await container
        .read(farmBoundaryControllerProvider.notifier)
        .loadBoundary('farm-123');

    final state = container.read(farmBoundaryControllerProvider);
    expect(state, isA<FarmBoundaryError>());
    expect(
      (state as FarmBoundaryError).message,
      'Unable to load the farm boundary. Please try again.',
    );
  });

  test('treats a not-found boundary as an empty state', () async {
    final repository = _FakeFarmBoundaryRepository(
      loadError: DioException(
        requestOptions: RequestOptions(path: '/farms/farm-123/boundary'),
        response: Response(
          requestOptions: RequestOptions(path: '/farms/farm-123/boundary'),
          statusCode: 404,
        ),
      ),
    );
    final container = _createContainer(repository);
    addTearDown(container.dispose);

    await container
        .read(farmBoundaryControllerProvider.notifier)
        .loadBoundary('farm-123');

    expect(
      container.read(farmBoundaryControllerProvider),
      isA<FarmBoundaryEmpty>(),
    );
  });

  test('saves a boundary successfully with the farm ID and geometry', () async {
    final repository = _FakeFarmBoundaryRepository();
    final container = _createContainer(repository);
    addTearDown(container.dispose);
    final controller = container.read(farmBoundaryControllerProvider.notifier);

    final save = controller.saveBoundary('farm-123', _geometry);

    expect(
      container.read(farmBoundaryControllerProvider),
      isA<FarmBoundarySaving>(),
    );
    await save;

    final state = container.read(farmBoundaryControllerProvider);
    expect(state, isA<FarmBoundaryLoaded>());
    expect(repository.savedFarmId, 'farm-123');
    expect(repository.savedGeometry, same(_geometry));
  });

  test('preserves the loaded boundary while saving', () async {
    final completer = Completer<FarmBoundary>();
    final repository = _FakeFarmBoundaryRepository(saveCompleter: completer);
    final container = _createContainer(repository);
    addTearDown(container.dispose);
    final controller = container.read(farmBoundaryControllerProvider.notifier);
    final existingBoundary = _loadedBoundary();

    container.read(farmBoundaryControllerProvider.notifier);
    container.read(farmBoundaryControllerProvider.notifier).state =
        FarmBoundaryLoaded(existingBoundary);

    final save = controller.saveBoundary('farm-1', _geometry);

    final savingState =
        container.read(farmBoundaryControllerProvider) as FarmBoundarySaving;
    expect(savingState.boundary, same(existingBoundary));

    completer.complete(existingBoundary);
    await save;
  });

  test(
    'reports a friendly error and preserves the boundary when saving fails',
    () async {
      final repository = _FakeFarmBoundaryRepository(
        saveError: StateError('save failed'),
      );
      final container = _createContainer(repository);
      addTearDown(container.dispose);
      final controller = container.read(
        farmBoundaryControllerProvider.notifier,
      );
      final existingBoundary = _loadedBoundary();

      container.read(farmBoundaryControllerProvider.notifier).state =
          FarmBoundaryLoaded(existingBoundary);

      await controller.saveBoundary('farm-1', _geometry);

      final state =
          container.read(farmBoundaryControllerProvider) as FarmBoundaryError;
      expect(
        state.message,
        'Unable to save the farm boundary. Please try again.',
      );
      expect(state.boundary, same(existingBoundary));
    },
  );
}
