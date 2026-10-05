import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/advisory/data/advisory_providers.dart';
import 'package:frontend/features/advisory/data/advisory_repository_contract.dart';
import 'package:frontend/features/advisory/data/models/crop_advisory.dart';
import 'package:frontend/features/advisory/presentation/screens/crop_advisory_screen.dart';

class _FakeAdvisoryRepository implements AdvisoryRepositoryContract {
  _FakeAdvisoryRepository({
    this.result,
    this.shouldThrow = false,
    this.pending = false,
  });

  final CropAdvisory? result;
  final bool shouldThrow;
  final bool pending;

  @override
  Future<CropAdvisory> getCropAdvisory(String cropId) async {
    if (pending) {
      return Completer<CropAdvisory>().future;
    }

    if (shouldThrow) {
      throw Exception('boom');
    }

    return result!;
  }
}

void main() {
  final advisoryPresent = CropAdvisory(
    cropId: 'crop-1',
    advisory: AdvisoryItem(
      id: 'advisory-1',
      cropId: 'crop-1',
      observationId: 'obs-1',
      title: 'Irrigation recommended',
      message: 'Soil moisture indicators suggest irrigation soon.',
      severity: 'Medium',
      priority: 'High',
      category: 'Irrigation',
      isRead: false,
      createdAt: DateTime(2026, 9, 20),
    ),
  );

  const advisoryEmpty = CropAdvisory(cropId: 'crop-1');

  Widget buildScreen(AdvisoryRepositoryContract repository) {
    return ProviderScope(
      overrides: [advisoryRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: CropAdvisoryScreen(cropId: 'crop-1')),
    );
  }

  testWidgets('shows the advisory title, message, severity and priority', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildScreen(_FakeAdvisoryRepository(result: advisoryPresent)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Crop Advisory'), findsOneWidget);
    expect(find.text('Irrigation recommended'), findsOneWidget);
    expect(
      find.text('Soil moisture indicators suggest irrigation soon.'),
      findsOneWidget,
    );
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('Irrigation'), findsOneWidget);
  });

  testWidgets('shows the friendly empty state when advisory is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildScreen(_FakeAdvisoryRepository(result: advisoryEmpty)),
    );
    await tester.pumpAndSettle();

    expect(find.text('No advisory available yet'), findsOneWidget);
    expect(
      find.text(
        "We don't have enough recent crop-health information "
        'to provide an advisory.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows a loading indicator while the request is in flight', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildScreen(
        _FakeAdvisoryRepository(result: advisoryPresent, pending: true),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows a friendly error and a working retry button', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildScreen(_FakeAdvisoryRepository(shouldThrow: true)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to load the crop advisory. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to load the crop advisory. Please try again.'),
      findsOneWidget,
    );
  });
}
