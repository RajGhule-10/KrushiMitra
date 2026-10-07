import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/features/advisory/data/advisory_providers.dart';
import 'package:frontend/features/advisory/data/advisory_repository_contract.dart';
import 'package:frontend/features/advisory/data/models/crop_advisory.dart';
import 'package:frontend/features/advisory/presentation/screens/crop_advisory_screen.dart';
import 'package:frontend/features/crop_health/data/crop_health_repository_contract.dart';
import 'package:frontend/features/crop_health/data/crop_health_providers.dart';
import 'package:frontend/features/crop_health/data/models/crop_health.dart';
import 'package:frontend/features/crop_health/data/models/crop_health_analysis.dart';
import 'package:frontend/features/crop_health/data/models/crop_health_history_item.dart';
import 'package:frontend/features/crop_health/data/models/crop_health_map.dart';
import 'package:frontend/features/crop_health/data/models/crop_health_trend.dart';
import 'package:frontend/features/crop_health/presentation/screens/crop_health_screen.dart';

class _FakeCropHealthRepository implements CropHealthRepositoryContract {
  _FakeCropHealthRepository();

  @override
  Future<CropHealthAnalysis> analyzeCropHealth(String cropId) {
    throw UnimplementedError('Not needed for this test.');
  }

  @override
  Future<CropHealth> getCropHealth(String cropId) async {
    return CropHealth(
      cropId: cropId,
      cropName: 'Wheat',
      latestObservation: LatestCropHealthObservation(
        observationDate: DateTime(2026, 10, 1),
        dataSource: 'sentinel-2',
        cloudPercentage: 8.25,
        ndviMean: 0.65,
      ),
    );
  }

  @override
  Future<List<CropHealthHistoryItem>> getCropHealthHistory(
    String cropId,
  ) async {
    return const [];
  }

  @override
  Future<CropHealthTrend> getCropHealthTrend(String cropId) async {
    return const CropHealthTrend(
      cropId: 'crop-1',
      direction: 'Stable',
      firstNdvi: 0.5,
      latestNdvi: 0.5,
      change: 0.0,
      observationCount: 1,
    );
  }

  @override
  Future<CropHealthMap> getCropHealthMap(String cropId) {
    throw UnimplementedError('Not needed for this test.');
  }
}

class _FakeAdvisoryRepository implements AdvisoryRepositoryContract {
  @override
  Future<CropAdvisory> getCropAdvisory(String cropId) async {
    return CropAdvisory(cropId: cropId);
  }
}

void main() {
  testWidgets('tapping View Crop Advisory navigates to the advisory screen', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/crops/crop-1/health',
      routes: [
        GoRoute(
          path: '/crops/:cropId/health',
          builder: (context, state) =>
              CropHealthScreen(cropId: state.pathParameters['cropId']!),
        ),
        GoRoute(
          path: '/crops/:cropId/advisory',
          builder: (context, state) =>
              CropAdvisoryScreen(cropId: state.pathParameters['cropId']!),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cropHealthRepositoryProvider.overrideWithValue(
            _FakeCropHealthRepository(),
          ),
          advisoryRepositoryProvider.overrideWithValue(
            _FakeAdvisoryRepository(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('View Crop Advisory'), findsOneWidget);

    await tester.tap(find.text('View Crop Advisory'));
    await tester.pumpAndSettle();

    expect(find.text('Crop Advisory'), findsOneWidget);
    expect(find.text('No advisory available yet'), findsOneWidget);
  });
}
