import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('Farm Map screen loads with boundary card', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: KrushiMitraApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Farm Map'), findsOneWidget);
    expect(find.text('No farm boundary yet'), findsOneWidget);
    expect(find.text('Add Farm Boundary'), findsOneWidget);
  });

  testWidgets('Tapping Add Farm Boundary shows placeholder message',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: KrushiMitraApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Farm Boundary'));
    await tester.pump();

    expect(
      find.text('Farm boundary setup will be available next.'),
      findsOneWidget,
    );
  });
}