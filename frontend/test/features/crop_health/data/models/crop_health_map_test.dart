import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/crop_health/data/models/crop_health_map.dart';

void main() {
  test('parses the nested map visualization response', () {
    final result = CropHealthMap.fromJson({
      'crop_id': 'crop-1',
      'farm_id': 'farm-1',
      'observation_date': '2026-10-01',
      'data_source': 'sentinel-2',
      'visualization': {
        'type': 'ndvi',
        'min': -1,
        'max': 1.0,
        'palette': ['#8B0000', '#1B7837'],
      },
      'tile_url_template': '/api/v1/crops/crop-1/health/map/tiles/{z}/{x}/{y}',
    });

    expect(result.cropId, 'crop-1');
    expect(result.farmId, 'farm-1');
    expect(result.observationDate, DateTime(2026, 10, 1));
    expect(result.visualization.min, -1.0);
    expect(result.visualization.palette, ['#8B0000', '#1B7837']);
    expect(result.tileUrlTemplate, contains('{z}/{x}/{y}'));
  });

  test('rejects malformed required visualization values', () {
    expect(
      () => NdviVisualization.fromJson({
        'type': 'ndvi',
        'min': '-1',
        'max': 1,
        'palette': [],
      }),
      throwsFormatException,
    );
  });
}
