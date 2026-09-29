import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/farms/data/farm_boundary_providers.dart';
import 'package:frontend/features/farms/data/farm_boundary_repository_contract.dart';
import 'package:frontend/features/farms/data/models/farm_boundary.dart';
import 'package:frontend/features/farms/presentation/screens/farm_boundary_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class _FakeFarmBoundaryRepository implements FarmBoundaryRepositoryContract {
  _FakeFarmBoundaryRepository({
    this.failSaves = 0,
    this.saveCompleter,
    this.boundary,
    this.loadError,
  });

  int failSaves;
  final Completer<FarmBoundary>? saveCompleter;
  final FarmBoundary? boundary;
  final Object? loadError;
  int saveCalls = 0;
  String? savedFarmId;
  Map<String, dynamic>? savedGeometry;

  @override
  Future<FarmBoundary> getBoundary(String farmId) {
    if (loadError != null) {
      return Future<FarmBoundary>.error(loadError!);
    }
    if (boundary != null) {
      return Future.value(boundary);
    }
    return Future<FarmBoundary>.error(
      DioException(
        requestOptions: RequestOptions(path: '/farms/$farmId/boundary'),
        response: Response(
          requestOptions: RequestOptions(path: '/farms/$farmId/boundary'),
          statusCode: 404,
        ),
      ),
    );
  }

  @override
  Future<FarmBoundary> saveBoundary(
    String farmId,
    Map<String, dynamic> geometry,
  ) async {
    saveCalls++;
    savedFarmId = farmId;
    savedGeometry = geometry;
    if (failSaves > 0) {
      failSaves--;
      throw StateError('save failed');
    }

    final boundary = FarmBoundary(
      farmId: farmId,
      geometry: GeoJsonGeometry(
        type: geometry['type'] as String,
        coordinates: geometry['coordinates'] as List<dynamic>,
      ),
    );
    if (saveCompleter != null) {
      return saveCompleter!.future;
    }
    return boundary;
  }
}

Widget buildBoundaryScreen({FarmBoundaryRepositoryContract? repository}) {
  final farmRepository = repository ?? _FakeFarmBoundaryRepository();
  return ProviderScope(
    overrides: [
      farmBoundaryRepositoryProvider.overrideWithValue(farmRepository),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const FarmBoundaryScreen(farmId: 'farm-1'),
    ),
  );
}

void main() {
  testWidgets('boundary screen renders instructions and zero points', (
    tester,
  ) async {
    await tester.pumpWidget(buildBoundaryScreen());

    expect(find.text('Mark your farm'), findsOneWidget);
    expect(
      find.text('Tap around the edges of your farm to draw its boundary.'),
      findsOneWidget,
    );
    expect(find.text('0 boundary points'), findsOneWidget);
    expect(
      find.text('Add at least 3 points to mark your farm.'),
      findsOneWidget,
    );
  });

  testWidgets('tapping the map adds a boundary point', (tester) async {
    await tester.pumpWidget(buildBoundaryScreen());

    final map = find.byKey(const Key('farm-boundary-map'));
    final rect = tester.getRect(map);
    await tester.tapAt(Offset(rect.left + 100, rect.top + 100));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('1 boundary point'), findsOneWidget);
  });

  testWidgets('undo removes the most recent point', (tester) async {
    await tester.pumpWidget(buildBoundaryScreen());
    final map = find.byKey(const Key('farm-boundary-map'));
    final rect = tester.getRect(map);

    await tester.tapAt(Offset(rect.left + 100, rect.top + 100));
    await tester.tapAt(Offset(rect.left + 180, rect.top + 100));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Undo'));
    await tester.pump();

    expect(find.text('1 boundary point'), findsOneWidget);
  });

  testWidgets('clear removes all points', (tester) async {
    await tester.pumpWidget(buildBoundaryScreen());
    final map = find.byKey(const Key('farm-boundary-map'));
    final rect = tester.getRect(map);

    await tester.tapAt(Offset(rect.left + 100, rect.top + 100));
    await tester.tapAt(Offset(rect.left + 180, rect.top + 100));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Clear'));
    await tester.pump();

    expect(find.text('0 boundary points'), findsOneWidget);
  });

  testWidgets('polygon appears after three points', (tester) async {
    await tester.pumpWidget(buildBoundaryScreen());
    final map = find.byKey(const Key('farm-boundary-map'));
    final rect = tester.getRect(map);

    await tester.tapAt(Offset(rect.left + 100, rect.top + 100));
    await tester.tapAt(Offset(rect.left + 220, rect.top + 100));
    await tester.tapAt(Offset(rect.left + 160, rect.top + 220));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(PolygonLayer), findsOneWidget);
    expect(find.text('3 boundary points'), findsOneWidget);
    expect(find.text('Add at least 3 points to mark your farm.'), findsNothing);
  });

  test('point store rejects duplicates and supports drawing controls', () {
    final store = BoundaryPointStore();
    const first = LatLng(18.52, 73.85);

    expect(store.add(first), isTrue);
    expect(store.add(const LatLng(18.52001, 73.85001)), isFalse);
    expect(store.points, hasLength(1));
    expect(store.undo(), isTrue);
    expect(store.undo(), isFalse);

    store
      ..add(first)
      ..add(const LatLng(18.53, 73.86))
      ..add(const LatLng(18.54, 73.87));
    expect(store.isReady, isTrue);
    store.clear();
    expect(store.points, isEmpty);
  });

  test('converts LatLng points to a closed Polygon GeoJSON ring', () {
    final geometry = boundaryGeometryFromPoints(const [
      LatLng(18.5, 73.8),
      LatLng(18.51, 73.81),
      LatLng(18.52, 73.82),
    ]);

    expect(geometry['type'], 'Polygon');
    expect(geometry['coordinates'], [
      [
        [73.8, 18.5],
        [73.81, 18.51],
        [73.82, 18.52],
        [73.8, 18.5],
      ],
    ]);
  });

  testWidgets('save is disabled before three points and enabled after', (
    tester,
  ) async {
    await tester.pumpWidget(buildBoundaryScreen());

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    final map = find.byKey(const Key('farm-boundary-map'));
    final rect = tester.getRect(map);
    await tester.tapAt(Offset(rect.left + 100, rect.top + 100));
    await tester.tapAt(Offset(rect.left + 220, rect.top + 100));
    await tester.tapAt(Offset(rect.left + 160, rect.top + 220));
    await tester.pump(const Duration(milliseconds: 500));

    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save Boundary'),
    );
    expect(saveButton.onPressed, isNotNull);
  });

  testWidgets('saving passes farm ID and closed GeoJSON to the controller', (
    tester,
  ) async {
    final repository = _FakeFarmBoundaryRepository();
    await tester.pumpWidget(buildBoundaryScreen(repository: repository));
    final map = find.byKey(const Key('farm-boundary-map'));
    final rect = tester.getRect(map);

    await tester.tapAt(Offset(rect.left + 100, rect.top + 100));
    await tester.tapAt(Offset(rect.left + 220, rect.top + 100));
    await tester.tapAt(Offset(rect.left + 160, rect.top + 220));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Save Boundary'));
    await tester.pumpAndSettle();

    expect(repository.saveCalls, 1);
    expect(repository.savedFarmId, 'farm-1');
    expect(repository.savedGeometry?['type'], 'Polygon');
    final ring = repository.savedGeometry?['coordinates'][0] as List<dynamic>;
    expect(ring.first, ring.last);
    expect(find.text('Farm boundary saved successfully.'), findsOneWidget);
  });

  testWidgets('failed save keeps points and allows retry', (tester) async {
    final repository = _FakeFarmBoundaryRepository(failSaves: 1);
    await tester.pumpWidget(buildBoundaryScreen(repository: repository));
    final map = find.byKey(const Key('farm-boundary-map'));
    final rect = tester.getRect(map);

    await tester.tapAt(Offset(rect.left + 100, rect.top + 100));
    await tester.tapAt(Offset(rect.left + 220, rect.top + 100));
    await tester.tapAt(Offset(rect.left + 160, rect.top + 220));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Save Boundary'));
    await tester.pumpAndSettle();

    expect(repository.saveCalls, 1);
    expect(find.text('3 boundary points'), findsOneWidget);
    expect(
      find.text('Unable to save the farm boundary. Please try again.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Save Boundary'));
    await tester.pumpAndSettle();
    expect(repository.saveCalls, 2);
  });

  testWidgets('repeated save taps produce one request while saving', (
    tester,
  ) async {
    final saveCompleter = Completer<FarmBoundary>();
    final repository = _FakeFarmBoundaryRepository(
      saveCompleter: saveCompleter,
    );
    await tester.pumpWidget(buildBoundaryScreen(repository: repository));
    final map = find.byKey(const Key('farm-boundary-map'));
    final rect = tester.getRect(map);

    await tester.tapAt(Offset(rect.left + 100, rect.top + 100));
    await tester.tapAt(Offset(rect.left + 220, rect.top + 100));
    await tester.tapAt(Offset(rect.left + 160, rect.top + 220));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Save Boundary'));
    await tester.pump();
    await tester.tap(find.text('Saving boundary...'));
    await tester.pump();

    expect(repository.saveCalls, 1);
    saveCompleter.complete(
      FarmBoundary(
        farmId: 'farm-1',
        geometry: GeoJsonGeometry(type: 'Polygon', coordinates: const []),
      ),
    );
    await tester.pump();
  });

  testWidgets('loads and displays a persisted Polygon boundary', (
    tester,
  ) async {
    const boundary = FarmBoundary(
      farmId: 'farm-1',
      geometry: GeoJsonGeometry(
        type: 'Polygon',
        coordinates: [
          [
            [73.8, 18.5],
            [73.81, 18.5],
            [73.81, 18.51],
            [73.8, 18.5],
          ],
        ],
      ),
    );
    await tester.pumpWidget(
      buildBoundaryScreen(
        repository: _FakeFarmBoundaryRepository(boundary: boundary),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saved farm boundary'), findsOneWidget);
    expect(find.byType(PolygonLayer), findsOneWidget);
    expect(find.text('Edit Boundary'), findsOneWidget);
  });

  testWidgets('renders every MultiPolygon component', (tester) async {
    const boundary = FarmBoundary(
      farmId: 'farm-1',
      geometry: GeoJsonGeometry(
        type: 'MultiPolygon',
        coordinates: [
          [
            [
              [73.8, 18.5],
              [73.81, 18.5],
              [73.8, 18.51],
              [73.8, 18.5],
            ],
          ],
          [
            [
              [73.82, 18.5],
              [73.83, 18.5],
              [73.82, 18.51],
              [73.82, 18.5],
            ],
          ],
        ],
      ),
    );
    await tester.pumpWidget(
      buildBoundaryScreen(
        repository: _FakeFarmBoundaryRepository(boundary: boundary),
      ),
    );
    await tester.pumpAndSettle();

    final layer = tester.widget<PolygonLayer>(find.byType(PolygonLayer));
    expect(layer.polygons, hasLength(2));
  });

  testWidgets('not-found boundary keeps the screen ready for drawing', (
    tester,
  ) async {
    await tester.pumpWidget(buildBoundaryScreen());
    await tester.pumpAndSettle();

    expect(find.text('Mark your farm'), findsOneWidget);
    expect(find.text('Saved farm boundary'), findsNothing);
    expect(
      find.text('Add at least 3 points to mark your farm.'),
      findsOneWidget,
    );
  });

  testWidgets('load errors offer retry', (tester) async {
    final repository = _FakeFarmBoundaryRepository(
      loadError: StateError('network failed'),
    );
    await tester.pumpWidget(buildBoundaryScreen(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Try loading boundary again'), findsOneWidget);
    await tester.tap(find.text('Try loading boundary again'));
    await tester.pumpAndSettle();
    expect(find.text('Try loading boundary again'), findsOneWidget);
  });

  testWidgets('editing a loaded Polygon seeds the editable points', (
    tester,
  ) async {
    const boundary = FarmBoundary(
      farmId: 'farm-1',
      geometry: GeoJsonGeometry(
        type: 'Polygon',
        coordinates: [
          [
            [73.8, 18.5],
            [73.81, 18.5],
            [73.8, 18.51],
            [73.8, 18.5],
          ],
        ],
      ),
    );
    await tester.pumpWidget(
      buildBoundaryScreen(
        repository: _FakeFarmBoundaryRepository(boundary: boundary),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Boundary'));
    await tester.pump();

    expect(find.text('3 boundary points'), findsOneWidget);
    expect(find.text('Save Boundary'), findsOneWidget);
  });
}
