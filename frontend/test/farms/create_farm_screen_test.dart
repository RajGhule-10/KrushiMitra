import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/farms/data/farm_providers.dart';
import 'package:frontend/features/farms/data/farm_repository_contract.dart';
import 'package:frontend/features/farms/data/models/farm.dart';
import 'package:frontend/features/farms/data/models/farm_create_request.dart';
import 'package:frontend/features/farms/data/models/farm_update_request.dart';
import 'package:frontend/features/farms/presentation/screens/create_farm_screen.dart';

class _FakeFarmRepository implements FarmRepositoryContract {
  _FakeFarmRepository({this.createCompleter});

  final Completer<Farm>? createCompleter;
  FarmCreateRequest? lastCreateRequest;
  int createCalls = 0;
  Object? createError;

  @override
  Future<List<Farm>> getFarms() async => [];

  @override
  Future<Farm> getFarm(String farmId) async => throw UnimplementedError();

  @override
  Future<Farm> createFarm(FarmCreateRequest request) {
    createCalls++;
    lastCreateRequest = request;
    if (createError != null) {
      return Future<Farm>.error(createError!);
    }
    if (createCompleter != null) {
      return createCompleter!.future;
    }
    return Future.value(_farmFromRequest(request));
  }

  @override
  Future<Farm> updateFarm(String farmId, FarmUpdateRequest request) async =>
      throw UnimplementedError();

  Farm _farmFromRequest(FarmCreateRequest request) {
    return Farm(
      id: 'farm-1',
      name: request.name,
      gatNumber: request.gatNumber,
      areaHectares: request.areaHectares,
      village: request.village,
      district: request.district,
      state: request.state,
      createdAt: DateTime.utc(2026, 9, 29),
      updatedAt: DateTime.utc(2026, 9, 29),
    );
  }
}

Widget _buildScreen(_FakeFarmRepository repository) {
  return ProviderScope(
    overrides: [farmRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const CreateFarmScreen(),
    ),
  );
}

Future<void> _scrollToSubmit(WidgetTester tester) {
  return tester.dragUntilVisible(
    find.byType(FilledButton),
    find.byType(ListView),
    const Offset(0, -300),
  );
}

void main() {
  testWidgets('renders the farm creation form', (tester) async {
    await tester.pumpWidget(_buildScreen(_FakeFarmRepository()));

    expect(find.text('Add farm'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Farm name *'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Gat number'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Area (hectares)'),
      findsOneWidget,
    );
    expect(find.text('Village'), findsOneWidget);
    expect(find.text('District'), findsOneWidget);
    expect(find.text('State'), findsOneWidget);
    await _scrollToSubmit(tester);
    expect(find.text('Create farm'), findsOneWidget);
  });

  testWidgets('validates a required farm name', (tester) async {
    await tester.pumpWidget(_buildScreen(_FakeFarmRepository()));

    await _scrollToSubmit(tester);
    await tester.tap(find.text('Create farm'));
    await tester.pump();

    expect(find.text('Enter a farm name'), findsOneWidget);
  });

  testWidgets('validates that area is positive', (tester) async {
    await tester.pumpWidget(_buildScreen(_FakeFarmRepository()));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Farm name *'),
      'Green Acres',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Area (hectares)'),
      '0',
    );
    await _scrollToSubmit(tester);
    await tester.tap(find.text('Create farm'));
    await tester.pump();

    expect(find.text('Enter a positive area'), findsOneWidget);
  });

  testWidgets('submits a valid request without farmer id', (tester) async {
    final repository = _FakeFarmRepository();
    await tester.pumpWidget(_buildScreen(repository));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Farm name *'),
      'Green Acres',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Gat number'),
      'GAT-12',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Area (hectares)'),
      '2.5',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Village'),
      'Loni',
    );
    await _scrollToSubmit(tester);
    await tester.tap(find.text('Create farm'));
    await tester.pumpAndSettle();

    expect(repository.lastCreateRequest?.name, 'Green Acres');
    expect(repository.lastCreateRequest?.areaHectares, 2.5);
    expect(repository.lastCreateRequest?.village, 'Loni');
    expect(repository.lastCreateRequest?.toJson(), {
      'name': 'Green Acres',
      'gat_number': 'GAT-12',
      'area_hectares': 2.5,
      'village': 'Loni',
    });
    expect(find.text('Farm created successfully.'), findsOneWidget);
    expect(repository.createCalls, 1);
  });

  testWidgets('prevents duplicate submission across rebuilds', (tester) async {
    final completer = Completer<Farm>();
    final repository = _FakeFarmRepository(createCompleter: completer);
    await tester.pumpWidget(_buildScreen(repository));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Farm name *'),
      'Green Acres',
    );
    await _scrollToSubmit(tester);
    await tester.tap(find.text('Create farm'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Creating farm...'));
    await tester.pump();

    expect(repository.createCalls, 1);
    expect(repository.lastCreateRequest?.name, 'Green Acres');
    expect(find.text('Creating farm...'), findsOneWidget);
  });

  testWidgets('shows the friendly message when creation fails', (tester) async {
    final repository = _FakeFarmRepository()
      ..createError = StateError('request failed');
    await tester.pumpWidget(_buildScreen(repository));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Farm name *'),
      'Green Acres',
    );
    await _scrollToSubmit(tester);
    await tester.tap(find.text('Create farm'));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(
      find.text('Unable to create your farm. Please try again.'),
      findsOneWidget,
    );
  });
}
