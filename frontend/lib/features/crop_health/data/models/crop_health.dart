class LatestCropHealthObservation {
  const LatestCropHealthObservation({
    required this.observationDate,
    required this.dataSource,
    required this.cloudPercentage,
    required this.ndviMean,
  });

  final DateTime observationDate;
  final String dataSource;
  final double? cloudPercentage;
  final double ndviMean;

  factory LatestCropHealthObservation.fromJson(Map<String, dynamic> json) {
    return LatestCropHealthObservation(
      observationDate: DateTime.parse(json['observation_date'] as String),
      dataSource: json['data_source'] as String,
      cloudPercentage: _parseNullableDecimal(json['cloud_percentage']),
      ndviMean: _parseRequiredDecimal(json['ndvi_mean']),
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

class CropHealth {
  const CropHealth({
    required this.cropId,
    required this.cropName,
    this.latestObservation,
  });

  final String cropId;
  final String cropName;
  final LatestCropHealthObservation? latestObservation;

  factory CropHealth.fromJson(Map<String, dynamic> json) {
    final latestObservationJson =
        json['latest_observation'] as Map<String, dynamic>?;

    return CropHealth(
      cropId: json['crop_id'] as String,
      cropName: json['crop_name'] as String,
      latestObservation: latestObservationJson == null
          ? null
          : LatestCropHealthObservation.fromJson(latestObservationJson),
    );
  }
}
