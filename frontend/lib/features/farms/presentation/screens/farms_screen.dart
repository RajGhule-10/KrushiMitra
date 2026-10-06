import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../state/farm_controller.dart';
import '../state/farm_state.dart';
import '../widgets/farm_card.dart';
import '../../data/models/farm.dart';

class FarmsScreen extends ConsumerStatefulWidget {
  const FarmsScreen({super.key});

  @override
  ConsumerState<FarmsScreen> createState() => _FarmsScreenState();
}

class _FarmsScreenState extends ConsumerState<FarmsScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => ref.read(farmControllerProvider.notifier).loadFarms(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(farmControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Home',
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Your Farms'),
      ),
      body: switch (state) {
        FarmInitial() || FarmLoading() => const _FarmLoadingView(),
        FarmLoaded(:final farms) => _FarmListView(farms: farms),
        FarmError(:final message) => _FarmErrorView(
          message: message,
          onRetry: () {
            ref.read(farmControllerProvider.notifier).loadFarms();
          },
        ),
        FarmCreating(:final farms) => _FarmListView(farms: farms),
        FarmUpdating(:final farms) => _FarmListView(farms: farms),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/farms/create');
        },
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textOnDark,
        icon: const Icon(Icons.add),
        label: const Text('Add farm'),
      ),
    );
  }
}

class _FarmListView extends StatelessWidget {
  const _FarmListView({required this.farms});

  final List<Farm> farms;

  @override
  Widget build(BuildContext context) {
    if (farms.isEmpty) {
      return const _FarmEmptyView();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        100,
      ),
      itemCount: farms.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        return FarmCard(farm: farms[index]);
      },
    );
  }
}

class _FarmLoadingView extends StatelessWidget {
  const _FarmLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryGreen),
    );
  }
}

class _FarmEmptyView extends StatelessWidget {
  const _FarmEmptyView();

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
                Icons.agriculture_outlined,
                color: AppColors.primaryGreen,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No farms yet',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add your first farm to start tracking its '
              'location, health, and satellite insights.',
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

class _FarmErrorView extends StatelessWidget {
  const _FarmErrorView({required this.message, required this.onRetry});

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
