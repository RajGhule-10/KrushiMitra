class CropCreateRequest {
  const CropCreateRequest({
    required this.cropName,
    this.variety,
    this.sowingDate,
    this.expectedHarvestDate,
    required this.season,
    this.status = 'active',
  });

  final String cropName;
  final String? variety;
  final DateTime? sowingDate;
  final DateTime? expectedHarvestDate;
  final String season;
  final String status;

  Map<String, dynamic> toJson() => {
    'crop_name': cropName,
    'variety': variety,
    'sowing_date': sowingDate?.toIso8601String().split('T').first,
    'expected_harvest_date': expectedHarvestDate
        ?.toIso8601String()
        .split('T')
        .first,
    'season': season,
    'status': status,
  };
}
