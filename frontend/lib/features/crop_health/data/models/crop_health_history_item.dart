class CropHealthHistoryItem {
  const CropHealthHistoryItem({
    required this.observationDate,
    required this.dataSource,
    required this.cloudPercentage,
    required this.ndviMean,
    required this.healthStatus,
  });

  final DateTime observationDate;
  final String dataSource;
  final double? cloudPercentage;
  final double ndviMean;
  final String healthStatus;

  factory CropHealthHistoryItem.fromJson(Map<String, dynamic> json) {
    return CropHealthHistoryItem(
      observationDate: DateTime.parse(json['observation_date'] as String),
      dataSource: json['data_source'] as String,
      cloudPercentage: _parseNullableDecimal(json['cloud_percentage']),
      ndviMean: _parseRequiredDecimal(json['ndvi_mean']),
      healthStatus: json['health_status'] as String,
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
