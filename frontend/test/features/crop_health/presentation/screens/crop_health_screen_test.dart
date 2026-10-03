import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/crop_health/data/crop_health_providers.dart';
import 'package:frontend/features/crop_health/data/crop_health_repository_contract.dart';
import 'package:frontend/features/crop_health/data/models/crop_health.dart';
import 'package:frontend/features/crop_health/data/models/crop_health_history_item.dart';
import 'package:frontend/features/crop_health/data/models/crop_health_trend.dart';
import 'package:frontend/features/crop_health/presentation/screens/crop_health_screen.dart';

class _FakeCropHealthRepository implements CropHealthRepositoryContract {
  _FakeCropHealthRepository({
    this.cropHealthResult,
    this.historyResult,
    this.trendResult,
    this.shouldThrow = false,
    this.delay,
  });

  final CropHealth? cropHealthResult;
  final List<CropHealthHistoryItem>? historyResult;
  final CropHealthTrend? trendResult;
  final bool shouldThrow;
  final Duration? delay;

  @override
  Future<CropHealth> getCropHealth(String cropId) async {
    if (delay != null) {
      await Future<void>.delayed(delay!);
    }
    if (shouldThrow) {
      throw Exception('boom');
    }
    return cropHealthResult!;
  }

  @override
  Future<List<CropHealthHistoryItem>> getCropHealthHistory(
    String cropId,
  ) async {
    if (delay != null) {
      await Future<void>.delayed(delay!);
    }
    if (shouldThrow) {
      throw Exception('boom');
    }
    return historyResult!;
  }

  @override
  Future<CropHealthTrend> getCropHealthTrend(String cropId) async {
    if (delay != null) {
      await Future<void>.delayed(delay!);
    }
    if (shouldThrow) {
      throw Exception('boom');
    }
    return trendResult!;
  }
}

void main() {
  final cropHealth = CropHealth(
    cropId: 'crop-1',
    cropName: 'Wheat',
    latestObservation: LatestCropHealthObservation(
      observationDate: DateTime(2026, 9, 20),
      dataSource: 'sentinel-2',
      cloudPercentage: 8.25,
      ndviMean: 0.65,
    ),
  );

  final cropHealthNoObservation = CropHealth(
    cropId: 'crop-1',
    cropName: 'Wheat',
  );

  // Distinct NDVI values from `cropHealth` above so assertions on
  // exact text like "NDVI 0.65" aren't accidentally matched twice.
  final historyItems = [
    CropHealthHistoryItem(
      observationDate: DateTime(2026, 9, 20),
      dataSource: 'sentinel-2',
      cloudPercentage: 8.25,
      ndviMean: 0.70,
      healthStatus: 'Good',
    ),
    CropHealthHistoryItem(
      observationDate: DateTime(2026, 9, 13),
      dataSource: 'sentinel-2',
      cloudPercentage: null,
      ndviMean: 0.40,
      healthStatus: 'Needs attention',
    ),
  ];

  final trend = CropHealthTrend(
    cropId: 'crop-1',
    direction: 'Improving',
    firstNdvi: 0.20,
    latestNdvi: 0.80,
    change: 0.60,
    observationCount: 2,
  );

  Widget buildScreen(CropHealthRepositoryContract repository) {
    return ProviderScope(
      overrides: [cropHealthRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: CropHealthScreen(cropId: 'crop-1')),
    );
  }

  testWidgets('shows the matching backend health status', (
    tester,
  ) async {
    final repository = _FakeCropHealthRepository(
      cropHealthResult: cropHealth,
      historyResult: historyItems,
      trendResult: trend,
    );

    await tester.pumpWidget(buildScreen(repository));
    await tester.pumpAndSettle();

    expect(find.text('Wheat'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('NDVI 0.65'), findsOneWidget);
  });

  testWidgets('does not fabricate a status without a matching history item', (
    tester,
  ) async {
    final repository = _FakeCropHealthRepository(
      cropHealthResult: cropHealth,
      historyResult: [
        CropHealthHistoryItem(
          observationDate: DateTime(2026, 9, 19),
          dataSource: 'sentinel-2',
          cloudPercentage: 8.25,
          ndviMean: 0.70,
          healthStatus: 'Good',
        ),
      ],
      trendResult: trend,
    );

    await tester.pumpWidget(buildScreen(repository));
    await tester.pumpAndSettle();

    expect(find.text('Status unavailable'), findsOneWidget);
    expect(find.text('Poor'), findsNothing);
    expect(find.text('Needs attention'), findsNothing);
  });

  testWidgets('shows a loading indicator while requests are in flight', (
    tester,
  ) async {
    final repository = _FakeCropHealthRepository(
      cropHealthResult: cropHealth,
      historyResult: historyItems,
      trendResult: trend,
      delay: const Duration(milliseconds: 100),
    );

    await tester.pumpWidget(buildScreen(repository));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('shows a friendly error message and a working retry button', (
    tester,
  ) async {
    final repository = _FakeCropHealthRepository(shouldThrow: true);

    await tester.pumpWidget(buildScreen(repository));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to load crop health. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to load crop health. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('shows an empty state when there is no latest observation', (
    tester,
  ) async {
    final repository = _FakeCropHealthRepository(
      cropHealthResult: cropHealthNoObservation,
      historyResult: const [],
      trendResult: trend,
    );

    await tester.pumpWidget(buildScreen(repository));
    await tester.pumpAndSettle();

    expect(find.text('No recent crop health data yet.'), findsOneWidget);
  });

  testWidgets('renders recent observation history', (tester) async {
    final repository = _FakeCropHealthRepository(
      cropHealthResult: cropHealth,
      historyResult: historyItems,
      trendResult: trend,
    );

    await tester.pumpWidget(buildScreen(repository));
    await tester.pumpAndSettle();

    expect(find.text('NDVI 0.70'), findsOneWidget);
    expect(find.text('NDVI 0.40'), findsOneWidget);
    expect(find.textContaining('Needs attention'), findsOneWidget);
  });

  testWidgets('renders the health trend summary', (tester) async {
    final repository = _FakeCropHealthRepository(
      cropHealthResult: cropHealth,
      historyResult: historyItems,
      trendResult: trend,
    );

    await tester.pumpWidget(buildScreen(repository));
    await tester.pumpAndSettle();

    expect(find.text('Improving'), findsOneWidget);
    expect(find.text('2 observations'), findsOneWidget);
  });
}
