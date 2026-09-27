import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository_provider.dart';
import '../../data/models/login_request.dart';
import 'auth_state.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthInitial();
  }

  Future<void> restoreSession() async {
    state = const AuthLoading();

    try {
      final user = await ref.read(authRepositoryProvider).getCurrentUser();

      state = AuthAuthenticated(user);
    } catch (_) {
      await ref.read(authRepositoryProvider).logout();
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login({
    required String phoneNumber,
    required String password,
  }) async {
    state = const AuthLoading();

    try {
      final user = await ref
          .read(authRepositoryProvider)
          .login(LoginRequest(phoneNumber: phoneNumber, password: password));

      state = AuthAuthenticated(user);
    } catch (error) {
      state = AuthError(error.toString());
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();

    state = const AuthUnauthenticated();
  }
}
