import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/farms/data/models/farm.dart';
import 'package:frontend/features/farms/data/models/farm_create_request.dart';
import 'package:frontend/features/farms/data/models/farm_update_request.dart';

void main() {
  group('Farm', () {
    test('parses farm response correctly', () {
      final farm = Farm.fromJson({
        'id': 'farm-123',
        'name': 'Farm A',
        'gat_number': 'GAT-42',
        'area_hectares': 2.4,
        'village': 'Loni',
        'district': 'Pune',
        'state': 'Maharashtra',
        'created_at': '2026-09-29T10:00:00Z',
        'updated_at': '2026-09-29T11:00:00Z',
      });

      expect(farm.id, 'farm-123');
      expect(farm.name, 'Farm A');
      expect(farm.gatNumber, 'GAT-42');
      expect(farm.areaHectares, 2.4);
      expect(farm.village, 'Loni');
      expect(farm.district, 'Pune');
      expect(farm.state, 'Maharashtra');
    });

    test('handles nullable farm fields', () {
      final farm = Farm.fromJson({
        'id': 'farm-123',
        'name': 'Farm A',
        'gat_number': null,
        'area_hectares': null,
        'village': null,
        'district': null,
        'state': null,
        'created_at': '2026-09-29T10:00:00Z',
        'updated_at': '2026-09-29T11:00:00Z',
      });

      expect(farm.gatNumber, isNull);
      expect(farm.areaHectares, isNull);
      expect(farm.village, isNull);
      expect(farm.district, isNull);
      expect(farm.state, isNull);
    });

    test('parses backend decimal area strings', () {
      final farm = Farm.fromJson({
        'id': 'farm-123',
        'name': 'Farm A',
        'gat_number': null,
        'area_hectares': '2.4500',
        'village': null,
        'district': null,
        'state': null,
        'created_at': '2026-09-29T10:00:00Z',
        'updated_at': '2026-09-29T11:00:00Z',
      });

      expect(farm.areaHectares, 2.45);
    });
  });

  group('FarmCreateRequest', () {
    test('creates payload without farmer id', () {
      const request = FarmCreateRequest(
        name: 'Farm A',
        gatNumber: 'GAT-42',
        areaHectares: 2.4,
        village: 'Loni',
        district: 'Pune',
        state: 'Maharashtra',
      );

      final json = request.toJson();

      expect(json['name'], 'Farm A');
      expect(json['gat_number'], 'GAT-42');
      expect(json['area_hectares'], 2.4);
      expect(json.containsKey('farmer_id'), isFalse);
    });

    test('omits optional null fields', () {
      const request = FarmCreateRequest(name: 'Farm A');

      expect(request.toJson(), {'name': 'Farm A'});
    });
  });

  group('FarmUpdateRequest', () {
    test('includes only fields being updated', () {
      const request = FarmUpdateRequest(
        name: 'Updated Farm',
        areaHectares: 3.5,
      );

      expect(request.toJson(), {'name': 'Updated Farm', 'area_hectares': 3.5});
    });
  });
}
