import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/farm.dart';
import '../../../crops/data/models/crop.dart';
import '../../../crops/presentation/state/crop_controller.dart';
import '../../../crops/presentation/state/crop_state.dart';
import '../state/farm_controller.dart';
import '../state/farm_state.dart';

class FarmDetailsScreen extends ConsumerStatefulWidget {
  const FarmDetailsScreen({required this.farmId, super.key});

  final String farmId;

  @override
  ConsumerState<FarmDetailsScreen> createState() => _FarmDetailsScreenState();
}

class _FarmDetailsScreenState extends ConsumerState<FarmDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(cropControllerProvider.notifier).loadCrops(widget.farmId),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            _CropSection(
              farmId: farm.id,
              state: ref.watch(cropControllerProvider),
            ),
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
      if (farm.id == widget.farmId) {
        return farm;
      }
    }

    return null;
  }
}

class _CropSection extends StatelessWidget {
  const _CropSection({required this.farmId, required this.state});

  final String farmId;
  final CropState state;

  @override
  Widget build(BuildContext context) {
    final crops = switch (state) {
      CropLoaded(:final crops) => crops,
      CropCreating(:final crops) => crops,
      CropError(:final crops) => crops,
      CropInitial() || CropLoading() => const <Crop>[],
    };

    return _DetailsSection(
      title: 'Your Crops',
      icon: Icons.grass_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state is CropLoading || state is CropInitial)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          else if (crops.isEmpty) ...[
            const Text('No crops added yet'),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () => context.push('/farms/$farmId/crops/create'),
              icon: const Icon(Icons.add),
              label: const Text('Add Crop'),
            ),
          ] else ...[
            ...crops.map(_CropPreviewCard.new),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => context.push('/farms/$farmId/crops'),
              child: const Text('View all crops'),
            ),
          ],
          if (state is CropError)
            TextButton(
              onPressed: () => context.push('/farms/$farmId/crops'),
              child: const Text('Try again'),
            ),
        ],
      ),
    );
  }
}

class _CropPreviewCard extends StatelessWidget {
  const _CropPreviewCard(this.crop);

  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.grass, color: AppColors.primaryGreen),
      title: Text(crop.cropName),
      subtitle: Text('${crop.season} · ${crop.status}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/crops/${crop.id}/health'),
    );
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
