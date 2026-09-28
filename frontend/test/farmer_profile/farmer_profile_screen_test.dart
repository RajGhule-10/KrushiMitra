import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/farmer_profile/data/farmer_profile_providers.dart';
import 'package:frontend/features/farmer_profile/data/farmer_profile_repository_contract.dart';
import 'package:frontend/features/farmer_profile/data/models/farmer_profile.dart';
import 'package:frontend/features/farmer_profile/presentation/screens/farmer_profile_screen.dart';

class FakeFarmerProfileRepository implements FarmerProfileRepositoryContract {
  FarmerProfile profile = const FarmerProfile(
    id: 'profile-1',
    fullName: 'Raj Test',
    village: 'Loni',
    district: 'Pune',
    state: 'Maharashtra',
    preferredLanguage: 'mr',
  );

  @override
  Future<FarmerProfile> getProfile() async {
    return profile;
  }

  @override
  Future<FarmerProfile> updateProfile(request) async {
    profile = FarmerProfile(
      id: profile.id,
      fullName: request.fullName ?? profile.fullName,
      village: request.village ?? profile.village,
      district: request.district ?? profile.district,
      state: request.state ?? profile.state,
      preferredLanguage: request.preferredLanguage ?? profile.preferredLanguage,
    );

    return profile;
  }
}

void main() {
  testWidgets('renders farmer profile information', (tester) async {
    final repository = FakeFarmerProfileRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          farmerProfileRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: FarmerProfileScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Raj Test'), findsWidgets);
    expect(find.text('Personal information'), findsOneWidget);
    expect(find.text('Farm location'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(find.text('Save changes'), findsOneWidget);
  });

  testWidgets('loads profile fields from repository', (tester) async {
    final repository = FakeFarmerProfileRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          farmerProfileRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: FarmerProfileScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Raj Test'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Loni'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Pune'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Maharashtra'), findsOneWidget);
  });

  testWidgets('shows preferred language from profile', (tester) async {
    final repository = FakeFarmerProfileRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          farmerProfileRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: FarmerProfileScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Open the language dropdown.
    await tester.scrollUntilVisible(
      find.byType(DropdownButtonFormField<String>),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(find.text('मराठी'), findsOneWidget);
  });

  testWidgets('allows editing profile name', (tester) async {
    final repository = FakeFarmerProfileRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          farmerProfileRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: FarmerProfileScreen()),
      ),
    );

    await tester.pumpAndSettle();

    final nameField = find.widgetWithText(TextFormField, 'Raj Test');

    expect(nameField, findsOneWidget);

    await tester.enterText(nameField, 'Raj Ghule');

    expect(find.text('Raj Ghule'), findsOneWidget);
  });

  testWidgets('save button is available after profile loads', (tester) async {
    final repository = FakeFarmerProfileRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          farmerProfileRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: FarmerProfileScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(find.text('Save changes'), findsOneWidget);
    expect(find.byType(FilledButton), findsWidgets);
  });
}
