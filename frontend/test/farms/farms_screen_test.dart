import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/farms/data/farm_providers.dart';
import 'package:frontend/features/farms/data/farm_repository_contract.dart';
import 'package:frontend/features/farms/data/models/farm.dart';
import 'package:frontend/features/farms/data/models/farm_create_request.dart';
import 'package:frontend/features/farms/data/models/farm_update_request.dart';
import 'package:frontend/features/farms/presentation/screens/farms_screen.dart';
import 'package:go_router/go_router.dart';

class _FakeFarmRepository implements FarmRepositoryContract {
  @override
  Future<List<Farm>> getFarms() async => [];

  @override
  Future<Farm> getFarm(String farmId) => throw UnimplementedError();

  @override
  Future<Farm> createFarm(FarmCreateRequest request) =>
      throw UnimplementedError();

  @override
  Future<Farm> updateFarm(String farmId, FarmUpdateRequest request) =>
      throw UnimplementedError();
}

void main() {
  testWidgets('Farms has a home control that navigates to dashboard', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/farms',
      routes: [
        GoRoute(
          path: '/farms',
          builder: (context, state) => const FarmsScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) =>
              const Scaffold(body: Text('Dashboard home')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          farmRepositoryProvider.overrideWithValue(_FakeFarmRepository()),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard home'), findsOneWidget);
  });
}
