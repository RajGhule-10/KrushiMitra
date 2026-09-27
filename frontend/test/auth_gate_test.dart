import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/authentication/data/auth_repository_contract.dart';
import 'package:frontend/features/authentication/data/auth_repository_provider.dart';
import 'package:frontend/features/authentication/data/models/login_request.dart';
import 'package:frontend/features/authentication/data/models/register_request.dart';
import 'package:frontend/features/authentication/data/models/user.dart';
import 'package:frontend/features/authentication/presentation/screens/auth_gate.dart';

class FakeAuthRepository implements AuthRepositoryContract {
  @override
  Future<User> register(RegisterRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<User> login(LoginRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<User> getCurrentUser() async {
    throw Exception('No active session');
  }

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('shows login required when no session exists', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Login required'), findsOneWidget);
  });
}
