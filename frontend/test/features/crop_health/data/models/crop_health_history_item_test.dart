import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/crop_health/data/models/crop_health_history_item.dart';

void main() {
  group('CropHealthHistoryItem.fromJson', () {
    test('parses a history item correctly', () {
      final item = CropHealthHistoryItem.fromJson({
        'observation_date': '2026-09-20',
        'data_source': 'sentinel-2',
        'cloud_percentage': 8.25,
        'ndvi_mean': 0.65,
        'health_status': 'Good',
      });

      expect(item.observationDate, DateTime(2026, 9, 20));
      expect(item.dataSource, 'sentinel-2');
      expect(item.cloudPercentage, 8.25);
      expect(item.ndviMean, 0.65);
      expect(item.healthStatus, 'Good');
    });

    test('allows a null cloud_percentage', () {
      final item = CropHealthHistoryItem.fromJson({
        'observation_date': '2026-09-20',
        'data_source': 'sentinel-2',
        'cloud_percentage': null,
        'ndvi_mean': 0.65,
        'health_status': 'Good',
      });

      expect(item.cloudPercentage, isNull);
    });

    test('parses a full history response list', () {
      final json = {
        'crop_id': 'crop-123',
        'history': [
          {
            'observation_date': '2026-09-20',
            'data_source': 'sentinel-2',
            'cloud_percentage': 8.25,
            'ndvi_mean': 0.65,
            'health_status': 'Good',
          },
          {
            'observation_date': '2026-09-13',
            'data_source': 'sentinel-2',
            'cloud_percentage': null,
            'ndvi_mean': 0.40,
            'health_status': 'Bad',
          },
        ],
      };

      final items = (json['history'] as List<dynamic>)
          .map((e) => CropHealthHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(items, hasLength(2));
      expect(items[0].healthStatus, 'Good');
      expect(items[1].cloudPercentage, isNull);
      expect(items[1].healthStatus, 'Bad');
    });
  });
}
