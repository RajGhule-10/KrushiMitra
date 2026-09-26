import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/dashboard_mock_data.dart';

/// The primary dashboard visual: a large rounded agricultural-imagery
/// hero with a dark gradient overlay carrying health/status
/// information, in the style of Reference 2.
class FarmHero extends StatelessWidget {
  const FarmHero({super.key, required this.farm});

  final MockFarm farm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = farm.status;

    return ClipRRect(
      borderRadius: AppRadius.lgRadius,
      child: SizedBox(
        height: 240,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              farm.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: AppColors.olive.withValues(alpha: 0.35),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.primaryGreenDark,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.eco,
                  size: 44,
                  color: AppColors.softAmber,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.charcoal.withValues(alpha: 0.05),
                    AppColors.charcoal.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              farm.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppColors.textOnDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              farm.crop,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textOnDarkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (farm.healthScore != null)
                        _HealthBadge(
                          score: farm.healthScore!,
                          color: status.color,
                        ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: status.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        status.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.textOnDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Last observation · ${farm.lastObservationLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textOnDarkSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.charcoal.withValues(alpha: 0.5),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        '$score',
        style: theme.textTheme.titleMedium?.copyWith(
          color: AppColors.textOnDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
