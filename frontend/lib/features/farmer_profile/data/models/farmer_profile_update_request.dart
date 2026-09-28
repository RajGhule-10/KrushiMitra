class FarmerProfileUpdateRequest {
  const FarmerProfileUpdateRequest({
    this.fullName,
    this.village,
    this.district,
    this.state,
    this.preferredLanguage,
  });

  final String? fullName;
  final String? village;
  final String? district;
  final String? state;
  final String? preferredLanguage;

  Map<String, dynamic> toJson() {
    return {
      if (fullName != null) 'full_name': fullName,
      if (village != null) 'village': village,
      if (district != null) 'district': district,
      if (state != null) 'state': state,
      if (preferredLanguage != null) 'preferred_language': preferredLanguage,
    };
  }
}
