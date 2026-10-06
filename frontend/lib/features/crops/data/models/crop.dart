class Crop {
  const Crop({
    required this.id,
    required this.farmId,
    required this.cropName,
    this.variety,
    this.sowingDate,
    this.expectedHarvestDate,
    required this.season,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String farmId;
  final String cropName;
  final String? variety;
  final DateTime? sowingDate;
  final DateTime? expectedHarvestDate;
  final String season;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      cropName: json['crop_name'] as String,
      variety: json['variety'] as String?,
      sowingDate: _parseDate(json['sowing_date']),
      expectedHarvestDate: _parseDate(json['expected_harvest_date']),
      season: json['season'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'farm_id': farmId,
    'crop_name': cropName,
    'variety': variety,
    'sowing_date': sowingDate?.toIso8601String().split('T').first,
    'expected_harvest_date': expectedHarvestDate
        ?.toIso8601String()
        .split('T')
        .first,
    'season': season,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
