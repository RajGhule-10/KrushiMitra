class Farm {
  const Farm({
    required this.id,
    required this.name,
    this.gatNumber,
    this.areaHectares,
    this.village,
    this.district,
    this.state,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? gatNumber;
  final double? areaHectares;
  final String? village;
  final String? district;
  final String? state;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'] as String,
      name: json['name'] as String,
      gatNumber: json['gat_number'] as String?,
      areaHectares: _parseArea(json['area_hectares']),
      village: json['village'] as String?,
      district: json['district'] as String?,
      state: json['state'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static double? _parseArea(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    throw FormatException('Invalid farm area: $value');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gat_number': gatNumber,
      'area_hectares': areaHectares,
      'village': village,
      'district': district,
      'state': state,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
