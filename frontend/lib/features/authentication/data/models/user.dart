class User {
  const User({
    required this.id,
    required this.phoneNumber,
    required this.role,
    required this.isActive,
  });

  final String id;
  final String phoneNumber;
  final String role;
  final bool isActive;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
    );
  }
}
