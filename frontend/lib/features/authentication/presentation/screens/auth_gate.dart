import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/auth_controller.dart';
import '../state/auth_state.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import 'login_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(authControllerProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    switch (authState) {
      case AuthInitial():
      case AuthLoading():
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case AuthAuthenticated():
        return const DashboardScreen();

      case AuthUnauthenticated():
        return const LoginScreen();

      case AuthError():
        return Scaffold(body: Center(child: Text(authState.message)));
    }
  }
}
