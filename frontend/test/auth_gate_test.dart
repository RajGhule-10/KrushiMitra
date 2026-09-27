import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/authentication/data/auth_repository_contract.dart';
import 'package:frontend/features/authentication/data/auth_repository_provider.dart';
import 'package:frontend/features/authentication/data/models/login_request.dart';
import 'package:frontend/features/authentication/data/models/register_request.dart';
import 'package:frontend/features/authentication/data/models/user.dart';
import 'package:frontend/features/authentication/presentation/screens/auth_gate.dart';
import 'package:frontend/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:frontend/features/authentication/presentation/screens/login_screen.dart';

class FakeUnauthenticatedRepository implements AuthRepositoryContract {
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

class FakeAuthenticatedRepository implements AuthRepositoryContract {
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
    return const User(
      id: 'test-user-id',
      phoneNumber: '9876543210',
      role: 'farmer',
      isActive: true,
    );
  }

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('shows login screen when no session exists', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeUnauthenticatedRepository(),
          ),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('shows dashboard when session is restored', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthenticatedRepository(),
          ),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.textContaining('Raj'), findsOneWidget);
  });
}
