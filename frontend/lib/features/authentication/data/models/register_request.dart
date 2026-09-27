class RegisterRequest {
  const RegisterRequest({
    required this.phoneNumber,
    required this.password,
    required this.fullName,
    this.village,
    this.district,
    this.state,
    this.preferredLanguage = 'mr',
  });

  final String phoneNumber;
  final String password;
  final String fullName;
  final String? village;
  final String? district;
  final String? state;
  final String preferredLanguage;

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'password': password,
      'full_name': fullName,
      'village': village,
      'district': district,
      'state': state,
      'preferred_language': preferredLanguage,
    };
  }
}
