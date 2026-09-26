import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Compact agricultural-intelligence metrics row: one larger dark
/// "hero metric" surface plus three smaller warm tiles, so the section
/// doesn't read as four identical white cards.
class QuickMetrics extends StatelessWidget {
  const QuickMetrics({
    super.key,
    required this.cropHealthScore,
    required this.soilMoisturePercent,
    required this.areaHectares,
    required this.satelliteUpdateDaysAgo,
  });

  final int cropHealthScore;
  final int soilMoisturePercent;
  final double areaHectares;
  final int satelliteUpdateDaysAgo;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: _DarkMetricCard(
              label: 'CROP HEALTH',
              value: '$cropHealthScore',
              icon: Icons.eco_outlined,
              accent: AppColors.healthyTeal,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                _CompactMetricTile(
                  label: 'Soil Moisture',
                  value: '$soilMoisturePercent%',
                  icon: Icons.water_drop_outlined,
                  accent: AppColors.waterBlue,
                ),
                const SizedBox(height: AppSpacing.sm),
                _CompactMetricTile(
                  label: 'Area',
                  value: '${areaHectares.toStringAsFixed(1)} ha',
                  icon: Icons.crop_square_outlined,
                  accent: AppColors.olive,
                ),
                const SizedBox(height: AppSpacing.sm),
                _CompactMetricTile(
                  label: 'Satellite Update',
                  value: '${satelliteUpdateDaysAgo}d ago',
                  icon: Icons.satellite_alt_outlined,
                  accent: AppColors.accentGold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkMetricCard extends StatelessWidget {
  const _DarkMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: accent, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: AppColors.textOnDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textOnDarkSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactMetricTile extends StatelessWidget {
  const _CompactMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: AppColors.charcoal.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
