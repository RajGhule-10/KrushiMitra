import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/farms/data/farm_boundary_providers.dart';
import 'package:frontend/features/farms/data/farm_boundary_repository_contract.dart';
import 'package:frontend/features/farms/data/models/farm_boundary.dart';
import 'package:frontend/features/farms/data/models/farm.dart';
import 'package:frontend/features/farms/presentation/screens/farm_details_screen.dart';
import 'package:frontend/features/farms/presentation/screens/farm_boundary_screen.dart';
import 'package:frontend/features/farms/presentation/state/farm_controller.dart';
import 'package:frontend/features/farms/presentation/state/farm_state.dart';
import 'package:frontend/features/farms/presentation/widgets/farm_card.dart';
import 'package:frontend/features/crops/data/crop_providers.dart';
import 'package:frontend/features/crops/data/crop_repository_contract.dart';
import 'package:frontend/features/crops/data/models/crop.dart';
import 'package:frontend/features/crops/data/models/crop_create_request.dart';
import 'package:frontend/features/crops/data/models/crop_update_request.dart';
import 'package:go_router/go_router.dart';

class _EmptyBoundaryRepository implements FarmBoundaryRepositoryContract {
  @override
  Future<FarmBoundary> getBoundary(String farmId) async {
    throw StateError('no boundary');
  }

  @override
  Future<FarmBoundary> saveBoundary(
    String farmId,
    Map<String, dynamic> geometry,
  ) async {
    return FarmBoundary(
      farmId: farmId,
      geometry: GeoJsonGeometry(
        type: geometry['type'] as String,
        coordinates: geometry['coordinates'] as List<dynamic>,
      ),
    );
  }
}

class _EmptyCropRepository implements CropRepositoryContract {
  @override
  Future<List<Crop>> getCrops(String farmId) async => [];

  @override
  Future<Crop> getCrop(String cropId) => throw UnimplementedError();

  @override
  Future<Crop> createCrop(String farmId, CropCreateRequest request) =>
      throw UnimplementedError();

  @override
  Future<Crop> updateCrop(String cropId, CropUpdateRequest request) =>
      throw UnimplementedError();
}

Farm createFarm({
  String id = 'farm-1',
  String name = 'Green Acres',
  String? gatNumber = 'GAT-12',
  double? areaHectares = 2.5,
  String? village = 'Loni',
  String? district = 'Pune',
  String? state = 'Maharashtra',
}) {
  return Farm(
    id: id,
    name: name,
    gatNumber: gatNumber,
    areaHectares: areaHectares,
    village: village,
    district: district,
    state: state,
    createdAt: DateTime.utc(2026, 9, 29),
    updatedAt: DateTime.utc(2026, 9, 29),
  );
}

Widget buildDetails(FarmState state, {String farmId = 'farm-1'}) {
  return ProviderScope(
    overrides: [
      farmControllerProvider.overrideWith(() => _FakeFarmController(state)),
      cropRepositoryProvider.overrideWithValue(_EmptyCropRepository()),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: FarmDetailsScreen(farmId: farmId),
    ),
  );
}

class _FakeFarmController extends FarmController {
  _FakeFarmController(this.initialState);

  final FarmState initialState;

  @override
  FarmState build() => initialState;
}

void main() {
  testWidgets('farm details renders the farm name', (tester) async {
    await tester.pumpWidget(buildDetails(FarmLoaded([createFarm()])));

    expect(find.text('Green Acres'), findsOneWidget);
  });

  testWidgets('farm details renders farm information', (tester) async {
    await tester.pumpWidget(buildDetails(FarmLoaded([createFarm()])));

    expect(find.text('2.50 hectares'), findsOneWidget);
    expect(find.text('GAT-12'), findsOneWidget);
    expect(find.text('Loni'), findsOneWidget);
    expect(find.text('Pune'), findsOneWidget);
    expect(find.text('Maharashtra'), findsOneWidget);
    expect(find.text('No boundary added yet'), findsOneWidget);
    expect(find.text('Add Farm Boundary'), findsOneWidget);
  });

  testWidgets('missing optional fields do not produce broken UI', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildDetails(
        FarmLoaded([
          createFarm(
            gatNumber: null,
            areaHectares: null,
            village: null,
            district: null,
            state: null,
          ),
        ]),
      ),
    );

    expect(find.text('Green Acres'), findsOneWidget);
    expect(find.text('Area not added'), findsOneWidget);
    expect(find.text('No boundary added yet'), findsOneWidget);
    expect(find.text('GAT-12'), findsNothing);
    expect(find.text('Loni'), findsNothing);
  });

  testWidgets('farm card tap navigates to the correct details route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/farms',
      routes: [
        GoRoute(
          path: '/farms',
          builder: (context, state) =>
              Scaffold(body: FarmCard(farm: createFarm())),
        ),
        GoRoute(
          path: '/farms/:farmId',
          builder: (context, state) =>
              FarmDetailsScreen(farmId: state.pathParameters['farmId']!),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          farmControllerProvider.overrideWith(
            () => _FakeFarmController(FarmLoaded([createFarm()])),
          ),
          farmBoundaryRepositoryProvider.overrideWithValue(
            _EmptyBoundaryRepository(),
          ),
          cropRepositoryProvider.overrideWithValue(_EmptyCropRepository()),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Green Acres'));
    await tester.pumpAndSettle();

    expect(find.text('Farm details'), findsOneWidget);
    expect(find.text('Green Acres'), findsOneWidget);
  });

  testWidgets('farm-not-found state is farmer-friendly', (tester) async {
    await tester.pumpWidget(
      buildDetails(FarmLoaded([]), farmId: 'missing-farm'),
    );

    expect(find.text('Farm not found'), findsOneWidget);
    expect(
      find.text('This farm is not currently available in your farm list.'),
      findsOneWidget,
    );
  });

  testWidgets('Add Farm Boundary navigates to the farm boundary route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/farms/farm-1',
      routes: [
        GoRoute(
          path: '/farms/:farmId',
          builder: (context, state) =>
              FarmDetailsScreen(farmId: state.pathParameters['farmId']!),
        ),
        GoRoute(
          path: '/farms/:farmId/boundary',
          builder: (context, state) =>
              FarmBoundaryScreen(farmId: state.pathParameters['farmId']!),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          farmControllerProvider.overrideWith(
            () => _FakeFarmController(FarmLoaded([createFarm()])),
          ),
          cropRepositoryProvider.overrideWithValue(_EmptyCropRepository()),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pump();

    final addBoundaryButton = find.ancestor(
      of: find.text('Add Farm Boundary'),
      matching: find.byType(FilledButton),
    );
    await tester.ensureVisible(addBoundaryButton);
    await tester.tap(addBoundaryButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Mark farm boundary'), findsOneWidget);
  });
}
