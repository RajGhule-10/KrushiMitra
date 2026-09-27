import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/authentication/data/auth_repository_contract.dart';
import 'package:frontend/features/authentication/data/models/login_request.dart';
import 'package:frontend/features/authentication/data/models/register_request.dart';
import 'package:frontend/features/authentication/data/models/user.dart';
import 'package:frontend/features/authentication/presentation/state/auth_controller.dart';
import 'package:frontend/features/authentication/presentation/state/auth_state.dart';
import 'package:frontend/features/authentication/data/auth_repository_provider.dart';

class FakeAuthRepository implements AuthRepositoryContract {
  FakeAuthRepository({this.user});

  final User? user;

  @override
  Future<User> register(RegisterRequest request) async {
    return user!;
  }

  @override
  Future<User> login(LoginRequest request) async {
    return user!;
  }

  @override
  Future<User> getCurrentUser() async {
    return user!;
  }

  @override
  Future<void> logout() async {}
}

void main() {
  const user = User(
    id: '123e4567-e89b-12d3-a456-426614174000',
    phoneNumber: '9876543210',
    role: 'farmer',
    isActive: true,
  );

  test('starts in initial state', () {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    expect(container.read(authControllerProvider), isA<AuthInitial>());
  });

  test('login changes state to authenticated', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: user),
        ),
      ],
    );

    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .login(phoneNumber: '9876543210', password: 'password123');

    final state = container.read(authControllerProvider);

    expect(state, isA<AuthAuthenticated>());
    expect((state as AuthAuthenticated).user.id, user.id);
  });

  test('logout changes state to unauthenticated', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: user),
        ),
      ],
    );

    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).logout();

    expect(container.read(authControllerProvider), isA<AuthUnauthenticated>());
  });
}
