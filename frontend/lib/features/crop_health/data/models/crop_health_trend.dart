/// Flattened representation of the backend's trend response
/// (`crop_id` + nested `trend` object) into a single model, matching
/// how this feature's repository exposes trend data as one typed
/// result rather than a generic response wrapper.
class CropHealthTrend {
  const CropHealthTrend({
    required this.cropId,
    required this.direction,
    required this.firstNdvi,
    required this.latestNdvi,
    required this.change,
    required this.observationCount,
  });

  final String cropId;
  final String direction;
  final double firstNdvi;
  final double latestNdvi;
  final double change;
  final int observationCount;

  factory CropHealthTrend.fromJson(Map<String, dynamic> json) {
    final trend = json['trend'] as Map<String, dynamic>;

    return CropHealthTrend(
      cropId: json['crop_id'] as String,
      direction: trend['direction'] as String,
      firstNdvi: _parseRequiredDecimal(trend['first_ndvi']),
      latestNdvi: _parseRequiredDecimal(trend['latest_ndvi']),
      change: _parseRequiredDecimal(trend['change']),
      observationCount: trend['observation_count'] as int,
    );
  }

  static double? _parseNullableDecimal(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    throw FormatException('Invalid decimal value: $value');
  }

  static double _parseRequiredDecimal(Object? value) {
    final parsed = _parseNullableDecimal(value);

    if (parsed == null) {
      throw const FormatException('Missing required decimal value');
    }

    return parsed;
  }
}
