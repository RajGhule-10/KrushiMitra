import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/crop_health/data/models/crop_health_analysis.dart';

void main() {
  test('parses the real analysis response with decimal strings', () {
    final result = CropHealthAnalysis.fromJson({
      'crop_id': 'crop-1',
      'observation': {
        'observation_date': '2026-10-05',
        'data_source': 'sentinel-2',
        'cloud_percentage': '0.77',
      },
      'health': {'metric': 'ndvi_mean', 'value': '0.700445', 'status': 'Great'},
      'advisory': {
        'id': 'advisory-1',
        'title': 'Crop health looks good',
        'message': 'Continue monitoring.',
        'severity': 'Great',
        'priority': 'low',
        'category': 'crop_health',
      },
    });

    expect(result.cropId, 'crop-1');
    expect(result.observationDate, DateTime(2026, 10, 5));
    expect(result.cloudPercentage, 0.77);
    expect(result.ndviValue, 0.700445);
    expect(result.healthStatus, 'Great');
    expect(result.advisory?.id, 'advisory-1');
  });

  test('allows a nullable cloud percentage and advisory', () {
    final result = CropHealthAnalysis.fromJson({
      'crop_id': 'crop-1',
      'observation': {
        'observation_date': '2026-10-05',
        'data_source': 'sentinel-2',
        'cloud_percentage': null,
      },
      'health': {'metric': 'ndvi_mean', 'value': 0.7, 'status': 'Great'},
      'advisory': null,
    });

    expect(result.cloudPercentage, isNull);
    expect(result.advisory, isNull);
  });
}
