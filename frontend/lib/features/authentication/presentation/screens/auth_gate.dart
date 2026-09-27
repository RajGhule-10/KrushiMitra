import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/auth_controller.dart';
import '../state/auth_state.dart';

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
        return const _AuthenticatedPlaceholder();

      case AuthUnauthenticated():
        return const _UnauthenticatedPlaceholder();

      case AuthError():
        return Scaffold(body: Center(child: Text(authState.message)));
    }
  }
}

class _AuthenticatedPlaceholder extends StatelessWidget {
  const _AuthenticatedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Authenticated')));
  }
}

class _UnauthenticatedPlaceholder extends StatelessWidget {
  const _UnauthenticatedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Login required')));
  }
}
