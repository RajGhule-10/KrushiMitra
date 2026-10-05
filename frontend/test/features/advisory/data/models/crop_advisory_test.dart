import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/advisory/data/models/crop_advisory.dart';

void main() {
  group('CropAdvisory.fromJson', () {
    test('parses a response with an advisory present', () {
      final cropAdvisory = CropAdvisory.fromJson({
        'crop_id': 'crop-1',
        'advisory': {
          'id': 'advisory-1',
          'crop_id': 'crop-1',
          'observation_id': 'obs-1',
          'title': 'Irrigation recommended',
          'message': 'Soil moisture indicators suggest irrigation soon.',
          'severity': 'Medium',
          'priority': 'High',
          'category': 'Irrigation',
          'is_read': false,
          'created_at': '2026-09-20T08:00:00Z',
          'expires_at': null,
        },
      });

      expect(cropAdvisory.cropId, 'crop-1');
      expect(cropAdvisory.advisory, isNotNull);

      final advisory = cropAdvisory.advisory!;
      expect(advisory.id, 'advisory-1');
      expect(advisory.cropId, 'crop-1');
      expect(advisory.observationId, 'obs-1');
      expect(advisory.title, 'Irrigation recommended');
      expect(
        advisory.message,
        'Soil moisture indicators suggest irrigation soon.',
      );
      expect(advisory.severity, 'Medium');
      expect(advisory.priority, 'High');
      expect(advisory.category, 'Irrigation');
      expect(advisory.isRead, isFalse);
      expect(advisory.createdAt, DateTime.parse('2026-09-20T08:00:00Z'));
      expect(advisory.expiresAt, isNull);
    });

    test('parses a response with a null advisory as an empty state', () {
      final cropAdvisory = CropAdvisory.fromJson({
        'crop_id': 'crop-1',
        'advisory': null,
      });

      expect(cropAdvisory.cropId, 'crop-1');
      expect(cropAdvisory.advisory, isNull);
    });

    test('parses a non-null expires_at when present', () {
      final cropAdvisory = CropAdvisory.fromJson({
        'crop_id': 'crop-1',
        'advisory': {
          'id': 'advisory-1',
          'crop_id': 'crop-1',
          'observation_id': 'obs-1',
          'title': 'Title',
          'message': 'Message',
          'severity': 'Low',
          'priority': 'Low',
          'category': 'General',
          'is_read': true,
          'created_at': '2026-09-20T08:00:00Z',
          'expires_at': '2026-09-27T08:00:00Z',
        },
      });

      expect(
        cropAdvisory.advisory!.expiresAt,
        DateTime.parse('2026-09-27T08:00:00Z'),
      );
      expect(cropAdvisory.advisory!.isRead, isTrue);
    });
  });
}
