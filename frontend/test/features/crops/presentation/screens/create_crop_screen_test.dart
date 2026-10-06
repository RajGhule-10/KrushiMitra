import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/crops/data/crop_providers.dart';
import 'package:frontend/features/crops/data/crop_repository_contract.dart';
import 'package:frontend/features/crops/data/models/crop.dart';
import 'package:frontend/features/crops/data/models/crop_create_request.dart';
import 'package:frontend/features/crops/data/models/crop_update_request.dart';
import 'package:frontend/features/crops/presentation/screens/create_crop_screen.dart';

class _FakeCropRepository implements CropRepositoryContract {
  @override
  Future<List<Crop>> getCrops(String farmId) async => [];

  @override
  Future<Crop> createCrop(String farmId, CropCreateRequest request) =>
      throw UnimplementedError();

  @override
  Future<Crop> getCrop(String cropId) => throw UnimplementedError();

  @override
  Future<Crop> updateCrop(String cropId, CropUpdateRequest request) =>
      throw UnimplementedError();
}

void main() {
  testWidgets('create crop validates required fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cropRepositoryProvider.overrideWithValue(_FakeCropRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CreateCropScreen(farmId: 'farm-1'),
        ),
      ),
    );

    await tester.tap(find.text('Save crop'));
    await tester.pump();

    expect(find.text('Enter a crop name'), findsOneWidget);
    expect(find.text('Enter a season'), findsOneWidget);
  });
}
