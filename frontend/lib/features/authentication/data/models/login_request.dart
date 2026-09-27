class LoginRequest {
  const LoginRequest({required this.phoneNumber, required this.password});

  final String phoneNumber;
  final String password;

  Map<String, dynamic> toJson() {
    return {'phone_number': phoneNumber, 'password': password};
  }
}
