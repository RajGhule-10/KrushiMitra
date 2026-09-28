import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/farmer_profile/data/models/farmer_profile.dart';
import 'package:frontend/features/farmer_profile/data/models/farmer_profile_update_request.dart';

void main() {
  test('creates FarmerProfile from backend JSON', () {
    final profile = FarmerProfile.fromJson({
      'id': '855fa682-94a9-4341-98d4-e334ae006416',
      'full_name': 'Raj Test',
      'village': null,
      'district': null,
      'state': null,
      'preferred_language': 'mr',
    });

    expect(profile.id, '855fa682-94a9-4341-98d4-e334ae006416');
    expect(profile.fullName, 'Raj Test');
    expect(profile.village, isNull);
    expect(profile.district, isNull);
    expect(profile.state, isNull);
    expect(profile.preferredLanguage, 'mr');
  });

  test('serializes FarmerProfile to JSON', () {
    const profile = FarmerProfile(
      id: 'test-id',
      fullName: 'Raj Test',
      village: 'Loni',
      district: 'Ghaziabad',
      state: 'Uttar Pradesh',
      preferredLanguage: 'hi',
    );

    expect(profile.toJson(), {
      'id': 'test-id',
      'full_name': 'Raj Test',
      'village': 'Loni',
      'district': 'Ghaziabad',
      'state': 'Uttar Pradesh',
      'preferred_language': 'hi',
    });
  });

  test('serializes only provided profile update fields', () {
    const request = FarmerProfileUpdateRequest(
      village: 'Loni',
      preferredLanguage: 'hi',
    );

    expect(request.toJson(), {'village': 'Loni', 'preferred_language': 'hi'});
  });
}
