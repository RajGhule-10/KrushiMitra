import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

/// Custom translucent bottom navigation, floating over the dashboard
/// content rather than the default Material BottomNavigationBar.
class DashboardBottomNavigation extends StatelessWidget {
  const DashboardBottomNavigation({
    super.key,
    required this.notificationCount,
    required this.onFarmsTap,
    required this.onMapTap,
    required this.onAlertsTap,
  });

  final int notificationCount;
  final VoidCallback onFarmsTap;
  final VoidCallback onMapTap;
  final VoidCallback onAlertsTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.xlRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.charcoal.withValues(alpha: 0.9),
            borderRadius: AppRadius.xlRadius,
          ),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: true,
                  onTap: () {},
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.agriculture_outlined,
                  label: 'Farms',
                  selected: false,
                  onTap: onFarmsTap,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.map_outlined,
                  label: 'Map',
                  selected: false,
                  onTap: onMapTap,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.notifications_outlined,
                  label: 'Alerts',
                  selected: false,
                  onTap: onAlertsTap,
                  badgeCount: notificationCount,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? AppColors.textOnDark
        : AppColors.textOnDarkSecondary;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 22, color: color),
              if (badgeCount > 0)
                Positioned(
                  top: -3,
                  right: -5,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.attentionCoral,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
