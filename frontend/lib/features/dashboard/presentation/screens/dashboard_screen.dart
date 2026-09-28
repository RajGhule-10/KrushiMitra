import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/dashboard_mock_data.dart';
import '../widgets/attention_card.dart';
import '../widgets/dashboard_bottom_navigation.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/farm_hero.dart';
import '../widgets/farm_selector.dart';
import '../widgets/farm_summary_card.dart';
import '../widgets/quick_metrics.dart';
import '../widgets/recent_activity.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = [
      'Overview',
      ...DashboardMockData.farms.map((farm) => farm.name),
    ];
    final heroFarm = _selectedIndex == 0
        ? DashboardMockData.overview
        : DashboardMockData.farms[_selectedIndex - 1];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                120,
              ),
              children: [
                DashboardHeader(
                  name: DashboardMockData.farmerName,
                  notificationCount: DashboardMockData.notificationCount,
                  onNotificationsTap: () => _showAlertsPlaceholder(context),
                  onProfileTap: () => context.push('/profile'),
                ),
                const SizedBox(height: AppSpacing.lg),
                FarmSelector(
                  labels: labels,
                  selectedIndex: _selectedIndex,
                  onChanged: (index) => setState(() => _selectedIndex = index),
                ),
                const SizedBox(height: AppSpacing.lg),
                FarmHero(farm: heroFarm),
                const SizedBox(height: AppSpacing.xl),
                QuickMetrics(
                  cropHealthScore: DashboardMockData.overview.healthScore ?? 0,
                  soilMoisturePercent: DashboardMockData.soilMoisturePercent,
                  areaHectares: DashboardMockData.totalAreaHectares,
                  satelliteUpdateDaysAgo:
                      DashboardMockData.satelliteUpdateDaysAgo,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Your Farms', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 190,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: DashboardMockData.farms.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) =>
                        FarmSummaryCard(farm: DashboardMockData.farms[index]),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                for (final item in DashboardMockData.attentionItems) ...[
                  AttentionCard(item: item),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.md),
                Text('Recent Activity', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                RecentActivity(entries: DashboardMockData.recentActivity),
              ],
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: DashboardBottomNavigation(
              notificationCount: DashboardMockData.notificationCount,
              onFarmsTap: () => context.go('/farm-map'),
              onMapTap: () => context.go('/farm-map'),
              onAlertsTap: () => _showAlertsPlaceholder(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showAlertsPlaceholder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alerts are coming in a future update.')),
    );
  }
}
