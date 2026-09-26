import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Simple health status used across the dashboard. This mirrors the
/// kind of simplified status the backend will eventually derive from
/// satellite/NDVI analysis, without exposing any technical detail.
enum FarmHealthStatus { good, needsAttention, noData }

extension FarmHealthStatusX on FarmHealthStatus {
  String get label {
    switch (this) {
      case FarmHealthStatus.good:
        return 'Good';
      case FarmHealthStatus.needsAttention:
        return 'Needs attention';
      case FarmHealthStatus.noData:
        return 'No recent data';
    }
  }

  Color get color {
    switch (this) {
      case FarmHealthStatus.good:
        return AppColors.healthyTeal;
      case FarmHealthStatus.needsAttention:
        return AppColors.attentionCoral;
      case FarmHealthStatus.noData:
        return AppColors.textSecondary;
    }
  }
}

/// Mock representation of a farm (or the "Overview" aggregate).
///
/// Structured so it can later be replaced by a model built from an
/// actual API response without changing the widgets that consume it.
class MockFarm {
  const MockFarm({
    required this.name,
    required this.crop,
    required this.areaHectares,
    required this.status,
    required this.lastObservationLabel,
    required this.imageSeed,
    this.healthScore,
  });

  final String name;
  final String crop;
  final double areaHectares;
  final FarmHealthStatus status;
  final String lastObservationLabel;
  final String imageSeed;
  final int? healthScore;

  /// Deterministic placeholder imagery. Swap for real agricultural
  /// photography assets when the design system gets production images.
  String get imageUrl => 'https://picsum.photos/seed/$imageSeed/900/650';
}

class MockAttentionItem {
  const MockAttentionItem({required this.farmName, required this.message});

  final String farmName;
  final String message;
}

class MockActivityEntry {
  const MockActivityEntry({required this.title, required this.timeAgo});

  final String title;
  final String timeAgo;
}

/// Local mock data for Stage 3. Will be replaced by backend-sourced
/// data in a later stage.
class DashboardMockData {
  DashboardMockData._();

  static const String farmerName = 'Raj';
  static const int notificationCount = 3;
  static const int soilMoisturePercent = 78;
  static const int satelliteUpdateDaysAgo = 2;
  static const double totalAreaHectares = 7.1;

  static const List<MockFarm> farms = [
    MockFarm(
      name: 'Farm A',
      crop: 'Wheat',
      areaHectares: 2.4,
      status: FarmHealthStatus.good,
      lastObservationLabel: '2 days ago',
      imageSeed: 'krushimitra-farm-a',
      healthScore: 82,
    ),
    MockFarm(
      name: 'Farm B',
      crop: 'Sugarcane',
      areaHectares: 3.1,
      status: FarmHealthStatus.needsAttention,
      lastObservationLabel: '6 days ago',
      imageSeed: 'krushimitra-farm-b',
      healthScore: 58,
    ),
    MockFarm(
      name: 'Farm C',
      crop: 'Cotton',
      areaHectares: 1.6,
      status: FarmHealthStatus.noData,
      lastObservationLabel: 'No recent data',
      imageSeed: 'krushimitra-farm-c',
    ),
  ];

  static const MockFarm overview = MockFarm(
    name: 'All Farms',
    crop: '3 farms monitored',
    areaHectares: totalAreaHectares,
    status: FarmHealthStatus.good,
    lastObservationLabel: '2 days ago',
    imageSeed: 'krushimitra-overview',
    healthScore: 82,
  );

  static const List<MockAttentionItem> attentionItems = [
    MockAttentionItem(
      farmName: 'Farm B',
      message: 'Crop health has changed since the previous observation.',
    ),
  ];

  static const List<MockActivityEntry> recentActivity = [
    MockActivityEntry(title: 'Crop health updated', timeAgo: '2 days ago'),
    MockActivityEntry(title: 'Farm boundary added', timeAgo: '5 days ago'),
    MockActivityEntry(title: 'Farm created', timeAgo: '1 week ago'),
  ];
}
