class CropHealthAnalysis {
  const CropHealthAnalysis({
    required this.cropId,
    required this.observationDate,
    required this.dataSource,
    required this.cloudPercentage,
    required this.metric,
    required this.ndviValue,
    required this.healthStatus,
    this.advisory,
  });

  final String cropId;
  final DateTime observationDate;
  final String dataSource;
  final double? cloudPercentage;
  final String metric;
  final double ndviValue;
  final String healthStatus;
  final CropHealthAnalysisAdvisory? advisory;

  factory CropHealthAnalysis.fromJson(Map<String, dynamic> json) {
    final observation = json['observation'] as Map<String, dynamic>;
    final health = json['health'] as Map<String, dynamic>;
    final advisoryJson = json['advisory'] as Map<String, dynamic>?;

    return CropHealthAnalysis(
      cropId: json['crop_id'] as String,
      observationDate: DateTime.parse(
        observation['observation_date'] as String,
      ),
      dataSource: observation['data_source'] as String,
      cloudPercentage: _parseNullableDecimal(observation['cloud_percentage']),
      metric: health['metric'] as String,
      ndviValue: _parseRequiredDecimal(health['value']),
      healthStatus: health['status'] as String,
      advisory: advisoryJson == null
          ? null
          : CropHealthAnalysisAdvisory.fromJson(advisoryJson),
    );
  }

  static double? _parseNullableDecimal(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
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

class CropHealthAnalysisAdvisory {
  const CropHealthAnalysisAdvisory({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.priority,
    required this.category,
  });

  final String id;
  final String title;
  final String message;
  final String severity;
  final String priority;
  final String category;

  factory CropHealthAnalysisAdvisory.fromJson(Map<String, dynamic> json) {
    return CropHealthAnalysisAdvisory(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      severity: json['severity'] as String,
      priority: json['priority'] as String,
      category: json['category'] as String,
    );
  }
}
