import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/authentication/data/models/login_request.dart';
import 'package:frontend/features/authentication/data/models/register_request.dart';
import 'package:frontend/features/authentication/data/models/token_response.dart';
import 'package:frontend/features/authentication/data/models/user.dart';

void main() {
  group('Authentication models', () {
    test('LoginRequest serializes correctly', () {
      const request = LoginRequest(
        phoneNumber: '9876543210',
        password: 'password123',
      );

      expect(request.toJson(), {
        'phone_number': '9876543210',
        'password': 'password123',
      });
    });

    test('RegisterRequest serializes correctly', () {
      const request = RegisterRequest(
        phoneNumber: '9876543210',
        password: 'password123',
        fullName: 'Raj Ghule',
        village: 'Pune',
        district: 'Pune',
        state: 'Maharashtra',
      );

      expect(request.toJson(), {
        'phone_number': '9876543210',
        'password': 'password123',
        'full_name': 'Raj Ghule',
        'village': 'Pune',
        'district': 'Pune',
        'state': 'Maharashtra',
        'preferred_language': 'mr',
      });
    });

    test('TokenResponse parses correctly', () {
      final token = TokenResponse.fromJson({
        'access_token': 'test-token',
        'token_type': 'bearer',
      });

      expect(token.accessToken, 'test-token');
      expect(token.tokenType, 'bearer');
    });

    test('User parses correctly', () {
      final user = User.fromJson({
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'phone_number': '9876543210',
        'role': 'farmer',
        'is_active': true,
      });

      expect(user.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(user.phoneNumber, '9876543210');
      expect(user.role, 'farmer');
      expect(user.isActive, true);
    });
  });
}
