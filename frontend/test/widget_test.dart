import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:frontend/features/farms/presentation/screens/farm_map_screen.dart';

void main() {
  // The dashboard hero loads a network image. In the test environment
  // that request never resolves, so pumpAndSettle() would hang
  // indefinitely waiting for it. A couple of bounded pumps is enough
  // to let all text/layout render without depending on the image.
  Future<void> pumpDashboard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1176, 2400); // ~392x800 @3x
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DashboardScreen())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('Dashboard (root screen)', () {
    testWidgets('loads and shows the greeting', (tester) async {
      await pumpDashboard(tester);

      expect(find.textContaining('Raj'), findsOneWidget);
    });

    testWidgets('shows the health score', (tester) async {
      await pumpDashboard(tester);

      expect(find.text('82'), findsWidgets);
    });

    testWidgets('shows the farm selector', (tester) async {
      await pumpDashboard(tester);

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Farm A'), findsWidgets);
      expect(find.text('Farm B'), findsWidgets);
      expect(find.text('Farm C'), findsWidgets);
    });

    testWidgets('shows the attention section', (tester) async {
      await pumpDashboard(tester);

      await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
      await tester.pump();

      expect(find.text('ATTENTION NEEDED'), findsOneWidget);
      expect(find.textContaining('changed since'), findsWidgets);
    });

    testWidgets('shows the custom bottom navigation', (tester) async {
      await pumpDashboard(tester);

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Farms'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
    });

    testWidgets('bottom navigation Map destination reaches Farm Map', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1176, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/farm-map',
            builder: (context, state) => const FarmMapScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      expect(find.text('Farm Map'), findsOneWidget);
    });
  });

  group('Farm Map screen', () {
    testWidgets('shows the map card and Add Farm Boundary action', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: FarmMapScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Farm Map'), findsOneWidget);
      expect(find.text('No farm boundary yet'), findsOneWidget);
      expect(find.text('Add Farm Boundary'), findsOneWidget);
    });

    testWidgets('tapping Add Farm Boundary shows placeholder message', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: FarmMapScreen())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Farm Boundary'));
      await tester.pump();

      expect(
        find.text('Farm boundary setup will be available next.'),
        findsOneWidget,
      );
    });
  });
}
