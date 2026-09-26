import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/dashboard_mock_data.dart';

class FarmSummaryCard extends StatelessWidget {
  const FarmSummaryCard({super.key, required this.farm});

  final MockFarm farm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = farm.status;

    return Container(
      width: 168,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.charcoal.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppRadius.smRadius,
            child: SizedBox(
              height: 84,
              width: double.infinity,
              child: Image.network(
                farm.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Container(color: AppColors.olive.withValues(alpha: 0.25)),
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.primaryGreenDark,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.grass,
                    color: AppColors.softAmber,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            farm.name,
            style: theme.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${farm.crop} · ${farm.areaHectares.toStringAsFixed(1)} ha',
            style: theme.textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  status.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: status.color,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
