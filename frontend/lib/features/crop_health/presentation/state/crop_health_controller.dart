import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/crop_health_providers.dart';
import '../../data/models/crop_health_trend.dart';
import 'crop_health_state.dart';

final cropHealthControllerProvider =
    NotifierProvider<CropHealthController, CropHealthState>(
      CropHealthController.new,
    );

class CropHealthController extends Notifier<CropHealthState> {
  bool _isAnalyzing = false;

  @override
  CropHealthState build() {
    return const CropHealthInitial();
  }

  CropHealthLoaded get _existing {
    final currentState = state;

    return currentState is CropHealthLoaded
        ? currentState
        : const CropHealthLoaded();
  }

  Future<void> loadCropHealth(String cropId) async {
    final existing = _existing;
    state = const CropHealthLoading();

    try {
      final cropHealth = await ref
          .read(cropHealthRepositoryProvider)
          .getCropHealth(cropId);

      state = CropHealthLoaded(
        cropHealth: cropHealth,
        history: existing.history,
        trend: existing.trend,
      );
    } catch (error) {
      state = const CropHealthError(
        'Unable to load crop health. Please try again.',
      );
    }
  }

  Future<void> loadCropHealthHistory(String cropId) async {
    final existing = _existing;
    state = const CropHealthLoading();

    try {
      final history = await ref
          .read(cropHealthRepositoryProvider)
          .getCropHealthHistory(cropId);

      state = CropHealthLoaded(
        cropHealth: existing.cropHealth,
        history: history,
        trend: existing.trend,
      );
    } catch (error) {
      state = const CropHealthError(
        'Unable to load crop health history. Please try again.',
      );
    }
  }

  Future<void> loadCropHealthTrend(String cropId) async {
    final existing = _existing;
    state = const CropHealthLoading();

    try {
      final trend = await ref
          .read(cropHealthRepositoryProvider)
          .getCropHealthTrend(cropId);

      state = CropHealthLoaded(
        cropHealth: existing.cropHealth,
        history: existing.history,
        trend: trend,
      );
    } catch (error) {
      state = CropHealthLoaded(
        cropHealth: existing.cropHealth,
        history: existing.history,
        trend: null,
      );
    }
  }

  Future<void> analyzeCropHealth(String cropId) async {
    if (_isAnalyzing) return;

    final existing = _existing;
    _isAnalyzing = true;
    state = CropHealthAnalyzing(
      cropHealth: existing.cropHealth,
      history: existing.history,
      trend: existing.trend,
    );

    try {
      await ref.read(cropHealthRepositoryProvider).analyzeCropHealth(cropId);
      final repository = ref.read(cropHealthRepositoryProvider);
      final cropHealth = await repository.getCropHealth(cropId);
      final history = await repository.getCropHealthHistory(cropId);

      CropHealthTrend? trend;
      try {
        trend = await repository.getCropHealthTrend(cropId);
      } catch (_) {
        trend = null;
      }

      state = CropHealthLoaded(
        cropHealth: cropHealth,
        history: history,
        trend: trend,
      );
    } catch (error) {
      state = CropHealthAnalysisError(
        message: 'Unable to analyze satellite data. Please try again.',
        cropHealth: existing.cropHealth,
        history: existing.history,
        trend: existing.trend,
      );
    } finally {
      _isAnalyzing = false;
    }
  }
}
