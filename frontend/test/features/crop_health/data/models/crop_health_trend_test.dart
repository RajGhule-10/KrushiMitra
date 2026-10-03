import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/crop_health/data/models/crop_health_trend.dart';

void main() {
  group('CropHealthTrend.fromJson', () {
    test('flattens crop_id and the nested trend object', () {
      final trend = CropHealthTrend.fromJson({
        'crop_id': 'crop-123',
        'trend': {
          'direction': 'Improving',
          'first_ndvi': 0.20,
          'latest_ndvi': 0.80,
          'change': 0.60,
          'observation_count': 2,
        },
      });

      expect(trend.cropId, 'crop-123');
      expect(trend.direction, 'Improving');
      expect(trend.firstNdvi, 0.20);
      expect(trend.latestNdvi, 0.80);
      expect(trend.change, 0.60);
      expect(trend.observationCount, 2);
    });
  });
}
