import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/dashboard_mock_data.dart';

class RecentActivity extends StatelessWidget {
  const RecentActivity({super.key, required this.entries});

  final List<MockActivityEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.olive,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (i != entries.length - 1)
                    Container(
                      width: 1,
                      height: 32,
                      color: AppColors.charcoal.withValues(alpha: 0.08),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entries[i].title,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      Text(
                        entries[i].timeAgo,
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
