import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/crop_advisory.dart';
import '../state/crop_advisory_controller.dart';
import '../state/crop_advisory_state.dart';

/// Farmer-facing crop advisory screen for a single crop.
///
/// The backend is the sole source of truth for whether an advisory
/// exists and what it says. This screen only displays what it is
/// given; it never classifies NDVI or generates advisory text itself.
class CropAdvisoryScreen extends ConsumerStatefulWidget {
  const CropAdvisoryScreen({super.key, required this.cropId});

  final String cropId;

  @override
  ConsumerState<CropAdvisoryScreen> createState() => _CropAdvisoryScreenState();
}

class _CropAdvisoryScreenState extends ConsumerState<CropAdvisoryScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(_load);
  }

  Future<void> _load() {
    return ref
        .read(cropAdvisoryControllerProvider.notifier)
        .loadCropAdvisory(widget.cropId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cropAdvisoryControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Crop Advisory'),
      ),
      body: switch (state) {
        CropAdvisoryInitial() ||
        CropAdvisoryLoading() => const _AdvisoryLoadingView(),
        CropAdvisoryLoaded(:final data) => _AdvisoryContentView(data: data),
        CropAdvisoryError(:final message) => _AdvisoryErrorView(
          message: message,
          onRetry: _load,
        ),
      },
    );
  }
}

class _AdvisoryLoadingView extends StatelessWidget {
  const _AdvisoryLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryGreen),
    );
  }
}

class _AdvisoryErrorView extends StatelessWidget {
  const _AdvisoryErrorView({required this.message, required this.onRetry});

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

class _AdvisoryContentView extends StatelessWidget {
  const _AdvisoryContentView({required this.data});

  final CropAdvisory data;

  @override
  Widget build(BuildContext context) {
    final advisory = data.advisory;

    if (advisory == null) {
      return const _AdvisoryEmptyView();
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [_AdvisoryCard(advisory: advisory)],
    );
  }
}

class _AdvisoryEmptyView extends StatelessWidget {
  const _AdvisoryEmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.10),
                borderRadius: AppRadius.lgRadius,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.task_alt_outlined,
                color: AppColors.primaryGreen,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No advisory available yet',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "We don't have enough recent crop-health information "
              'to provide an advisory.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvisoryCard extends StatelessWidget {
  const _AdvisoryCard({required this.advisory});

  final AdvisoryItem advisory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityColor = _colorForSeverity(advisory.severity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.charcoal.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Chip(label: advisory.severity, color: severityColor),
              const SizedBox(width: AppSpacing.xs),
              _Chip(
                label: advisory.priority,
                color: _colorForPriority(advisory.priority),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(advisory.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(advisory.message, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.lg),
          _InfoRow(
            icon: Icons.category_outlined,
            label: 'Category',
            value: advisory.category,
          ),
          const SizedBox(height: AppSpacing.xs),
          _InfoRow(
            icon: Icons.event_outlined,
            label: 'Issued on',
            value: _formatDate(advisory.createdAt),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.smRadius,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
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

/// Maps the backend's own severity vocabulary to a display color.
/// This does not classify anything — it only colors whatever string
/// the backend already decided. Unrecognized values fall back to a
/// neutral color rather than throwing.
Color _colorForSeverity(String severity) {
  switch (severity.toLowerCase()) {
    case 'low':
    case 'info':
      return AppColors.waterBlue;
    case 'medium':
    case 'moderate':
      return AppColors.softAmber;
    case 'high':
    case 'critical':
    case 'severe':
      return AppColors.attentionCoral;
    default:
      return AppColors.textSecondary;
  }
}

Color _colorForPriority(String priority) {
  switch (priority.toLowerCase()) {
    case 'low':
      return AppColors.olive;
    case 'medium':
      return AppColors.softAmber;
    case 'high':
    case 'urgent':
      return AppColors.attentionCoral;
    default:
      return AppColors.textSecondary;
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
