class CropUpdateRequest {
  const CropUpdateRequest({
    this.cropName,
    this.variety,
    this.sowingDate,
    this.expectedHarvestDate,
    this.season,
    this.status,
  });

  final String? cropName;
  final String? variety;
  final DateTime? sowingDate;
  final DateTime? expectedHarvestDate;
  final String? season;
  final String? status;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (cropName != null) json['crop_name'] = cropName;
    if (variety != null) json['variety'] = variety;
    if (sowingDate != null) {
      json['sowing_date'] = sowingDate!.toIso8601String().split('T').first;
    }
    if (expectedHarvestDate != null) {
      json['expected_harvest_date'] = expectedHarvestDate!
          .toIso8601String()
          .split('T')
          .first;
    }
    if (season != null) json['season'] = season;
    if (status != null) json['status'] = status;
    return json;
  }
}
