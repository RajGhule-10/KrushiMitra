class CropHealthMap {
  const CropHealthMap({
    required this.cropId,
    required this.farmId,
    required this.observationDate,
    required this.dataSource,
    required this.visualization,
    required this.tileUrlTemplate,
  });

  final String cropId;
  final String farmId;
  final DateTime observationDate;
  final String dataSource;
  final NdviVisualization visualization;
  final String tileUrlTemplate;

  factory CropHealthMap.fromJson(Map<String, dynamic> json) {
    return CropHealthMap(
      cropId: json['crop_id'] as String,
      farmId: json['farm_id'] as String,
      observationDate: DateTime.parse(json['observation_date'] as String),
      dataSource: json['data_source'] as String,
      visualization: NdviVisualization.fromJson(
        json['visualization'] as Map<String, dynamic>,
      ),
      tileUrlTemplate: json['tile_url_template'] as String,
    );
  }
}

class NdviVisualization {
  const NdviVisualization({
    required this.type,
    required this.min,
    required this.max,
    required this.palette,
  });

  final String type;
  final double min;
  final double max;
  final List<String> palette;

  factory NdviVisualization.fromJson(Map<String, dynamic> json) {
    final palette = json['palette'] as List<dynamic>;

    return NdviVisualization(
      type: json['type'] as String,
      min: _parseNumber(json['min']),
      max: _parseNumber(json['max']),
      palette: palette.cast<String>(),
    );
  }

  static double _parseNumber(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    throw FormatException('Invalid visualization number: $value');
  }
}
