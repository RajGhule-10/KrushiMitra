import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.name,
    required this.notificationCount,
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  final String name;
  final int notificationCount;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onProfileTap,
          borderRadius: AppRadius.mdRadius,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.12),
              borderRadius: AppRadius.mdRadius,
            ),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()}, $name',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                "Here's what needs your attention today.",
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _NotificationButton(
          count: notificationCount,
          onTap: onNotificationsTap,
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smRadius,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: AppColors.charcoal.withValues(alpha: 0.08),
                ),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
            if (count > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.attentionCoral,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
