import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/farm.dart';
import '../state/farm_controller.dart';
import '../state/farm_state.dart';

class FarmDetailsScreen extends ConsumerWidget {
  const FarmDetailsScreen({required this.farmId, super.key});

  final String farmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farm = _farmFromState(ref.watch(farmControllerProvider));

    if (farm == null) {
      return const _FarmNotFoundView();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Farm details'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            _FarmHeader(farm: farm),
            const SizedBox(height: AppSpacing.lg),
            _FarmInformationCard(farm: farm),
            const SizedBox(height: AppSpacing.lg),
            _BoundaryCard(farmId: farm.id),
          ],
        ),
      ),
    );
  }

  Farm? _farmFromState(FarmState state) {
    final farms = switch (state) {
      FarmLoaded(:final farms) => farms,
      FarmCreating(:final farms) => farms,
      FarmUpdating(:final farms) => farms,
      FarmInitial() || FarmLoading() || FarmError() => const <Farm>[],
    };

    for (final farm in farms) {
      if (farm.id == farmId) {
        return farm;
      }
    }

    return null;
  }
}

class _FarmHeader extends StatelessWidget {
  const _FarmHeader({required this.farm});

  final Farm farm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: AppRadius.lgRadius,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.textOnDark.withValues(alpha: 0.14),
              borderRadius: AppRadius.mdRadius,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.agriculture_outlined,
              color: AppColors.textOnDark,
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              farm.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.textOnDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmInformationCard extends StatelessWidget {
  const _FarmInformationCard({required this.farm});

  final Farm farm;

  @override
  Widget build(BuildContext context) {
    return _DetailsSection(
      title: 'Farm information',
      icon: Icons.info_outline,
      child: Column(
        children: [
          _DetailRow(
            label: 'Area',
            value: farm.areaHectares == null
                ? 'Area not added'
                : '${farm.areaHectares!.toStringAsFixed(2)} hectares',
          ),
          if (_hasValue(farm.gatNumber))
            _DetailRow(label: 'Gat number', value: farm.gatNumber!),
          if (_hasValue(farm.village))
            _DetailRow(label: 'Village', value: farm.village!),
          if (_hasValue(farm.district))
            _DetailRow(label: 'District', value: farm.district!),
          if (_hasValue(farm.state))
            _DetailRow(label: 'State', value: farm.state!),
        ],
      ),
    );
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
}

class _BoundaryCard extends StatelessWidget {
  const _BoundaryCard({required this.farmId});

  final String farmId;

  @override
  Widget build(BuildContext context) {
    return _DetailsSection(
      title: 'Farm boundary',
      icon: Icons.crop_free,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No boundary added yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Adding a boundary will enable future satellite insights '
            'and farm monitoring for this field.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () {
              context.push('/farms/$farmId/boundary');
            },
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Add Farm Boundary'),
          ),
        ],
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.charcoal.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryGreen),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _FarmNotFoundView extends StatelessWidget {
  const _FarmNotFoundView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Farm details'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_outlined,
                color: AppColors.attentionCoral,
                size: 44,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Farm not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'This farm is not currently available in your farm list.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
