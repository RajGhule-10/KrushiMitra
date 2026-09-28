class FarmerProfile {
  const FarmerProfile({
    required this.id,
    required this.fullName,
    this.village,
    this.district,
    this.state,
    required this.preferredLanguage,
  });

  final String id;
  final String fullName;
  final String? village;
  final String? district;
  final String? state;
  final String preferredLanguage;

  factory FarmerProfile.fromJson(Map<String, dynamic> json) {
    return FarmerProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      village: json['village'] as String?,
      district: json['district'] as String?,
      state: json['state'] as String?,
      preferredLanguage: json['preferred_language'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'village': village,
      'district': district,
      'state': state,
      'preferred_language': preferredLanguage,
    };
  }
}
