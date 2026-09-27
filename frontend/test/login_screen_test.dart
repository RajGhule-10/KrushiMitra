import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/authentication/presentation/screens/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/authentication/data/auth_repository_contract.dart';
import 'package:frontend/features/authentication/data/auth_repository_provider.dart';
import 'package:frontend/features/authentication/data/models/login_request.dart';
import 'package:frontend/features/authentication/data/models/register_request.dart';
import 'package:frontend/features/authentication/data/models/user.dart';
import 'package:dio/dio.dart';

class FakeSuccessfulAuthRepository implements AuthRepositoryContract {
  FakeSuccessfulAuthRepository({required this.user});

  final User user;

  @override
  Future<User> register(RegisterRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<User> login(LoginRequest request) async {
    return user;
  }

  @override
  Future<User> getCurrentUser() async {
    return user;
  }

  @override
  Future<void> logout() async {}
}

class FakeFailingAuthRepository implements AuthRepositoryContract {
  @override
  Future<User> register(RegisterRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<User> login(LoginRequest request) async {
    throw DioException(
      requestOptions: RequestOptions(path: '/api/v1/auth/login'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        statusCode: 401,
      ),
    );
  }

  @override
  Future<User> getCurrentUser() async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('shows login screen content', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    expect(find.text('KrushiMitra'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text('Sign in to continue managing your farm.'),
      findsOneWidget,
    );
    expect(find.text('Mobile number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });

  testWidgets('validates empty fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Enter your mobile number'), findsOneWidget);

    expect(find.text('Enter your password'), findsNWidgets(2));
  });

  testWidgets('validates invalid phone number', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    await tester.enterText(find.byType(TextFormField).at(0), '12345');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
  });

  testWidgets('validates short password', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    await tester.enterText(find.byType(TextFormField).at(0), '9876543210');
    await tester.enterText(find.byType(TextFormField).at(1), '1234567');

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
  });

  testWidgets('shows a friendly error when login fails', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeFailingAuthRepository()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), '9876543210');

    await tester.enterText(find.byType(TextFormField).at(1), 'password123');

    await tester.tap(find.text('Sign In'));

    await tester.pump();
    await tester.pump();

    expect(
      find.text('Mobile number or password is incorrect.'),
      findsOneWidget,
    );
  });

  testWidgets('submits valid credentials successfully', (tester) async {
    const user = User(
      id: 'test-user-id',
      phoneNumber: '9876543210',
      role: 'farmer',
      isActive: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeSuccessfulAuthRepository(user: user),
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), '9876543210');

    await tester.enterText(find.byType(TextFormField).at(1), 'password123');

    await tester.tap(find.text('Sign In'));

    await tester.pump();
    await tester.pump();

    expect(find.text('Sign In'), findsOneWidget);

    expect(find.text('Something went wrong. Please try again.'), findsNothing);
  });

  testWidgets('toggles password visibility', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    final passwordField = find.byType(TextFormField).at(1);

    await tester.enterText(passwordField, 'password123');

    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: passwordField,
              matching: find.byType(EditableText),
            ),
          )
          .obscureText,
      isTrue,
    );

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: passwordField,
              matching: find.byType(EditableText),
            ),
          )
          .obscureText,
      isFalse,
    );
  });
}
