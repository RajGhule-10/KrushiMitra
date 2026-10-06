import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/crops/data/models/crop.dart';

void main() {
  test('parses a crop response with optional fields', () {
    final crop = Crop.fromJson({
      'id': 'crop-1',
      'farm_id': 'farm-1',
      'crop_name': 'Wheat',
      'variety': null,
      'sowing_date': null,
      'expected_harvest_date': null,
      'season': 'rabi',
      'status': 'active',
      'created_at': '2026-10-01T10:00:00Z',
      'updated_at': '2026-10-01T10:00:00Z',
    });

    expect(crop.id, 'crop-1');
    expect(crop.farmId, 'farm-1');
    expect(crop.cropName, 'Wheat');
    expect(crop.variety, isNull);
    expect(crop.sowingDate, isNull);
    expect(crop.season, 'rabi');
  });

  test('serializes crop dates as backend date values', () {
    final crop = Crop(
      id: 'crop-1',
      farmId: 'farm-1',
      cropName: 'Wheat',
      sowingDate: DateTime.utc(2026, 6, 15),
      expectedHarvestDate: DateTime.utc(2026, 10, 15),
      season: 'kharif',
      status: 'active',
      createdAt: DateTime.utc(2026, 6, 1),
      updatedAt: DateTime.utc(2026, 6, 1),
    );

    expect(crop.toJson()['sowing_date'], '2026-06-15');
    expect(crop.toJson()['expected_harvest_date'], '2026-10-15');
  });
}
