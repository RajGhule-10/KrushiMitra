class FarmUpdateRequest {
  const FarmUpdateRequest({
    this.name,
    this.gatNumber,
    this.areaHectares,
    this.village,
    this.district,
    this.state,
  });

  final String? name;
  final String? gatNumber;
  final double? areaHectares;
  final String? village;
  final String? district;
  final String? state;

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (gatNumber != null) 'gat_number': gatNumber,
      if (areaHectares != null) 'area_hectares': areaHectares,
      if (village != null) 'village': village,
      if (district != null) 'district': district,
      if (state != null) 'state': state,
    };
  }
}
