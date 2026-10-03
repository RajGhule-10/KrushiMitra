import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/crop_health/data/models/crop_health.dart';

void main() {
  group('LatestCropHealthObservation.fromJson', () {
    test('parses a full observation correctly', () {
      final observation = LatestCropHealthObservation.fromJson({
        'observation_date': '2026-09-20',
        'data_source': 'sentinel-2',
        'cloud_percentage': 8.25,
        'ndvi_mean': 0.65,
      });

      expect(observation.observationDate, DateTime(2026, 9, 20));
      expect(observation.dataSource, 'sentinel-2');
      expect(observation.cloudPercentage, 8.25);
      expect(observation.ndviMean, 0.65);
    });

    test('parses a null cloud_percentage', () {
      final observation = LatestCropHealthObservation.fromJson({
        'observation_date': '2026-09-20',
        'data_source': 'sentinel-2',
        'cloud_percentage': null,
        'ndvi_mean': 0.65,
      });

      expect(observation.cloudPercentage, isNull);
    });
  });

  group('CropHealth.fromJson', () {
    test('maps snake_case fields to camelCase', () {
      final cropHealth = CropHealth.fromJson({
        'crop_id': 'crop-123',
        'crop_name': 'Wheat',
        'latest_observation': {
          'observation_date': '2026-09-20',
          'data_source': 'sentinel-2',
          'cloud_percentage': 8.25,
          'ndvi_mean': 0.65,
        },
      });

      expect(cropHealth.cropId, 'crop-123');
      expect(cropHealth.cropName, 'Wheat');
      expect(cropHealth.latestObservation, isNotNull);
      expect(cropHealth.latestObservation!.ndviMean, 0.65);
    });

    test('allows a null latest_observation', () {
      final cropHealth = CropHealth.fromJson({
        'crop_id': 'crop-123',
        'crop_name': 'Wheat',
        'latest_observation': null,
      });

      expect(cropHealth.latestObservation, isNull);
    });
  });
}
