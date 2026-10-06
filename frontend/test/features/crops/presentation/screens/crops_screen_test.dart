import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/crops/data/crop_providers.dart';
import 'package:frontend/features/crops/data/crop_repository_contract.dart';
import 'package:frontend/features/crops/data/models/crop.dart';
import 'package:frontend/features/crops/data/models/crop_create_request.dart';
import 'package:frontend/features/crops/data/models/crop_update_request.dart';
import 'package:frontend/features/crops/presentation/screens/crops_screen.dart';

class _FakeCropRepository implements CropRepositoryContract {
  _FakeCropRepository(this.crops);

  final List<Crop> crops;

  @override
  Future<List<Crop>> getCrops(String farmId) async => crops;

  @override
  Future<Crop> createCrop(String farmId, CropCreateRequest request) =>
      throw UnimplementedError();

  @override
  Future<Crop> getCrop(String cropId) => throw UnimplementedError();

  @override
  Future<Crop> updateCrop(String cropId, CropUpdateRequest request) =>
      throw UnimplementedError();
}

Crop crop() => Crop(
  id: 'crop-1',
  farmId: 'farm-1',
  cropName: 'Wheat',
  variety: 'Lokwan',
  sowingDate: DateTime.utc(2026, 6, 15),
  season: 'kharif',
  status: 'active',
  createdAt: DateTime.utc(2026, 6, 1),
  updatedAt: DateTime.utc(2026, 6, 1),
);

Widget buildScreen(List<Crop> crops) {
  return ProviderScope(
    overrides: [
      cropRepositoryProvider.overrideWithValue(_FakeCropRepository(crops)),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const CropsScreen(farmId: 'farm-1'),
    ),
  );
}

void main() {
  testWidgets('shows empty crop state', (tester) async {
    await tester.pumpWidget(buildScreen([]));
    await tester.pumpAndSettle();

    expect(find.text('No crops added yet'), findsOneWidget);
    expect(find.text('Add crop'), findsOneWidget);
  });

  testWidgets('shows loaded crop information', (tester) async {
    await tester.pumpWidget(buildScreen([crop()]));
    await tester.pumpAndSettle();

    expect(find.text('Wheat'), findsOneWidget);
    expect(find.text('Lokwan'), findsOneWidget);
    expect(find.text('kharif · active'), findsOneWidget);
    expect(find.text('Sown 15/6/2026'), findsOneWidget);
  });
}
