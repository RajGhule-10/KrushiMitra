import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/dashboard_mock_data.dart';

class AttentionCard extends StatelessWidget {
  const AttentionCard({super.key, required this.item});

  final MockAttentionItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.attentionCoral.withValues(alpha: 0.08),
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color: AppColors.attentionCoral.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 16,
                color: AppColors.attentionCoral,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'ATTENTION NEEDED',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.attentionCoral,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(item.farmName, style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(item.message, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => context.go('/farm-map'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View insight',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: AppColors.primaryGreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
