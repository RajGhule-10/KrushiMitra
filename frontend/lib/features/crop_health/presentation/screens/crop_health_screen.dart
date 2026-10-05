import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/crop_health.dart';
import '../../data/models/crop_health_history_item.dart';
import '../../data/models/crop_health_trend.dart';
import '../state/crop_health_controller.dart';
import '../state/crop_health_state.dart';

/// Farmer-facing crop health screen for a single crop.
///
/// Loads the latest health snapshot, history, and trend sequentially
/// (not concurrently) via [CropHealthController]. See the Stage 9.2
/// notes: CropHealthState is a single shared state object, and
/// sequential awaits avoid a lost-update race between the three loads.
class CropHealthScreen extends ConsumerStatefulWidget {
  const CropHealthScreen({super.key, required this.cropId});

  final String cropId;

  @override
  ConsumerState<CropHealthScreen> createState() => _CropHealthScreenState();
}

class _CropHealthScreenState extends ConsumerState<CropHealthScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(_loadAll);
  }

  Future<void> _loadAll() async {
    final notifier = ref.read(cropHealthControllerProvider.notifier);

    await notifier.loadCropHealth(widget.cropId);
    if (ref.read(cropHealthControllerProvider) is CropHealthError) return;
    await notifier.loadCropHealthHistory(widget.cropId);
    if (ref.read(cropHealthControllerProvider) is CropHealthError) return;
    await notifier.loadCropHealthTrend(widget.cropId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cropHealthControllerProvider);

    final title = state is CropHealthLoaded && state.cropHealth != null
        ? state.cropHealth!.cropName
        : 'Crop Health';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(title),
      ),
      body: switch (state) {
        CropHealthInitial() ||
        CropHealthLoading() => const _CropHealthLoadingView(),
        CropHealthLoaded(:final cropHealth, :final history, :final trend) =>
          _CropHealthContentView(
            cropHealth: cropHealth,
            history: history,
            trend: trend,
          ),
        CropHealthError(:final message) => _CropHealthErrorView(
          message: message,
          onRetry: _loadAll,
        ),
      },
    );
  }
}

class _CropHealthLoadingView extends StatelessWidget {
  const _CropHealthLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryGreen),
    );
  }
}

class _CropHealthErrorView extends StatelessWidget {
  const _CropHealthErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.attentionCoral,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropHealthContentView extends StatelessWidget {
  const _CropHealthContentView({
    required this.cropHealth,
    required this.history,
    required this.trend,
  });

  final CropHealth? cropHealth;
  final List<CropHealthHistoryItem>? history;
  final CropHealthTrend? trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        Text('Current Health', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        _CurrentHealthCard(cropHealth: cropHealth, history: history),
        if (cropHealth != null) ...[
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () =>
                context.push('/crops/${cropHealth!.cropId}/health/map'),
            icon: const Icon(Icons.satellite_alt_outlined),
            label: const Text('View Satellite Map'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: () =>
                context.push('/crops/${cropHealth!.cropId}/advisory'),
            icon: const Icon(Icons.task_alt_outlined),
            label: const Text('View Crop Advisory'),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text('Health Trend', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        _HealthTrendCard(trend: trend),
        const SizedBox(height: AppSpacing.xl),
        Text('Recent Observations', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        _HistorySection(history: history),
      ],
    );
  }
}

/// Shared card shell, matching the warm-surface/rounded-corner
/// convention used by FarmerProfileScreen's `_ProfileSection`.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.charcoal.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: CircularProgressIndicator(
            color: AppColors.primaryGreen,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

class _CurrentHealthCard extends StatelessWidget {
  const _CurrentHealthCard({required this.cropHealth, required this.history});

  final CropHealth? cropHealth;
  final List<CropHealthHistoryItem>? history;

  @override
  Widget build(BuildContext context) {
    final cropHealth = this.cropHealth;

    if (cropHealth == null) {
      return const _SectionLoading();
    }

    final observation = cropHealth.latestObservation;

    if (observation == null) {
      return _SectionCard(
        child: Column(
          children: [
            const Icon(
              Icons.satellite_alt_outlined,
              color: AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No recent crop health data yet.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'This will update automatically after the next '
              'satellite pass.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    final healthStatus = _healthStatusForObservation(
      history,
      observation.observationDate,
    );
    final label = healthStatus ?? 'Status unavailable';
    final color = healthStatus == null
        ? AppColors.textSecondary
        : _colorForHealthStatus(healthStatus);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(color: color),
              ),
              const Spacer(),
              Text(
                'NDVI ${observation.ndviMean.toStringAsFixed(2)}',
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            icon: Icons.event_outlined,
            label: 'Observed on',
            value: _formatDate(observation.observationDate),
          ),
          const SizedBox(height: AppSpacing.xs),
          _InfoRow(
            icon: Icons.satellite_alt_outlined,
            label: 'Source',
            value: _friendlyDataSource(observation.dataSource),
          ),
          if (observation.cloudPercentage != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _InfoRow(
              icon: Icons.cloud_outlined,
              label: 'Cloud cover',
              value: '${observation.cloudPercentage!.toStringAsFixed(0)}%',
            ),
          ],
        ],
      ),
    );
  }
}

class _HealthTrendCard extends StatelessWidget {
  const _HealthTrendCard({required this.trend});

  final CropHealthTrend? trend;

  @override
  Widget build(BuildContext context) {
    final trend = this.trend;

    if (trend == null) {
      return const _SectionLoading();
    }

    final theme = Theme.of(context);
    final directionIcon = _iconForTrendDirection(trend.direction);
    final directionColor = _colorForTrendDirection(trend.direction);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(directionIcon, color: directionColor, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                trend.direction,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: directionColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            icon: Icons.show_chart,
            label: 'NDVI change',
            value:
                '${trend.change >= 0 ? '+' : ''}'
                '${trend.change.toStringAsFixed(2)} '
                '(${trend.firstNdvi.toStringAsFixed(2)} → '
                '${trend.latestNdvi.toStringAsFixed(2)})',
          ),
          const SizedBox(height: AppSpacing.xs),
          _InfoRow(
            icon: Icons.bar_chart_outlined,
            label: 'Based on',
            value:
                '${trend.observationCount} observation'
                '${trend.observationCount == 1 ? '' : 's'}',
          ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.history});

  final List<CropHealthHistoryItem>? history;

  @override
  Widget build(BuildContext context) {
    final history = this.history;

    if (history == null) {
      return const _SectionLoading();
    }

    if (history.isEmpty) {
      return _SectionCard(
        child: Column(
          children: [
            const Icon(
              Icons.history_outlined,
              color: AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No crop health history yet.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < history.length; i++) ...[
          _HistoryRow(item: history[i]),
          if (i != history.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});

  final CropHealthHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorForHealthStatus(item.healthStatus);

    return _SectionCard(
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(item.observationDate),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.healthStatus} · '
                  '${_friendlyDataSource(item.dataSource)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            'NDVI ${item.ndviMean.toStringAsFixed(2)}',
            style: theme.textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String? _healthStatusForObservation(
  List<CropHealthHistoryItem>? history,
  DateTime observationDate,
) {
  for (final item in history ?? const <CropHealthHistoryItem>[]) {
    if (item.observationDate.year == observationDate.year &&
        item.observationDate.month == observationDate.month &&
        item.observationDate.day == observationDate.day) {
      return item.healthStatus;
    }
  }
  return null;
}

/// Maps a backend-provided health-status label from the history endpoint
/// to a status color.
/// Falls back to a neutral color for unrecognized labels rather than
/// throwing, since the backend's exact vocabulary isn't fixed here.
Color _colorForHealthStatus(String status) {
  switch (status.toLowerCase()) {
    case 'good':
    case 'great':
      return AppColors.healthyTeal;
    case 'needs attention':
    case 'moderate':
      return AppColors.softAmber;
    case 'bad':
    case 'poor':
    case 'severe':
      return AppColors.attentionCoral;
    default:
      return AppColors.textSecondary;
  }
}

IconData _iconForTrendDirection(String direction) {
  switch (direction.toLowerCase()) {
    case 'improving':
      return Icons.trending_up;
    case 'declining':
      return Icons.trending_down;
    default:
      return Icons.trending_flat;
  }
}

Color _colorForTrendDirection(String direction) {
  switch (direction.toLowerCase()) {
    case 'improving':
      return AppColors.healthyTeal;
    case 'declining':
      return AppColors.attentionCoral;
    default:
      return AppColors.textSecondary;
  }
}

String _friendlyDataSource(String dataSource) {
  switch (dataSource.toLowerCase()) {
    case 'sentinel-2':
      return 'Satellite (Sentinel-2)';
    default:
      return dataSource;
  }
}

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime date) {
  return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
}
