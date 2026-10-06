import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/crop.dart';
import '../state/crop_controller.dart';
import '../state/crop_state.dart';

class CropsScreen extends ConsumerStatefulWidget {
  const CropsScreen({required this.farmId, super.key});

  final String farmId;

  @override
  ConsumerState<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends ConsumerState<CropsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() {
    return ref.read(cropControllerProvider.notifier).loadCrops(widget.farmId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cropControllerProvider);
    final crops = switch (state) {
      CropLoaded(:final crops) => crops,
      CropCreating(:final crops) => crops,
      CropError(:final crops) => crops,
      CropInitial() || CropLoading() => const <Crop>[],
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Your Crops'),
      ),
      body: switch (state) {
        CropInitial() || CropLoading() => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
        CropLoaded() || CropCreating() => _CropList(crops: crops),
        CropError(:final message) => _CropError(
          message: message,
          onRetry: _load,
        ),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state is CropCreating
            ? null
            : () async {
                await context.push('/farms/${widget.farmId}/crops/create');
                if (mounted) await _load();
              },
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textOnDark,
        icon: const Icon(Icons.add),
        label: const Text('Add crop'),
      ),
    );
  }
}

class _CropList extends StatelessWidget {
  const _CropList({required this.crops});

  final List<Crop> crops;

  @override
  Widget build(BuildContext context) {
    if (crops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.grass_outlined,
                color: AppColors.primaryGreen,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No crops added yet',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Add a crop to start viewing its health and insights.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: crops.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _CropCard(crop: crops[index]),
    );
  }
}

class _CropCard extends StatelessWidget {
  const _CropCard({required this.crop});

  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/crops/${crop.id}/health'),
      borderRadius: AppRadius.lgRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppColors.charcoal.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            const Icon(Icons.grass, color: AppColors.primaryGreen, size: 32),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crop.cropName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (crop.variety?.trim().isNotEmpty ?? false)
                    Text(
                      crop.variety!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${crop.season} · ${crop.status}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (crop.sowingDate != null)
                    Text(
                      'Sown ${_date(crop.sowingDate!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _CropError extends StatelessWidget {
  const _CropError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
            Text(message, textAlign: TextAlign.center),
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
