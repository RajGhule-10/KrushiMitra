import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/farmer_profile/data/farmer_profile_providers.dart';
import 'package:frontend/features/farmer_profile/data/farmer_profile_repository_contract.dart';
import 'package:frontend/features/farmer_profile/data/models/farmer_profile.dart';
import 'package:frontend/features/farmer_profile/data/models/farmer_profile_update_request.dart';
import 'package:frontend/features/farmer_profile/presentation/state/farmer_profile_controller.dart';
import 'package:frontend/features/farmer_profile/presentation/state/farmer_profile_state.dart';

class FakeFarmerProfileRepository implements FarmerProfileRepositoryContract {
  FakeFarmerProfileRepository({required this.profile});

  FarmerProfile profile;

  @override
  Future<FarmerProfile> getProfile() async {
    return profile;
  }

  @override
  Future<FarmerProfile> updateProfile(
    FarmerProfileUpdateRequest request,
  ) async {
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
  const initialProfile = FarmerProfile(
    id: 'profile-id',
    fullName: 'Raj Test',
    village: null,
    district: null,
    state: null,
    preferredLanguage: 'mr',
  );

  test('loads farmer profile successfully', () async {
    final repository = FakeFarmerProfileRepository(profile: initialProfile);

    final container = ProviderContainer(
      overrides: [
        farmerProfileRepositoryProvider.overrideWithValue(repository),
      ],
    );

    addTearDown(container.dispose);

    final controller = container.read(farmerProfileControllerProvider.notifier);

    expect(
      container.read(farmerProfileControllerProvider),
      isA<FarmerProfileInitial>(),
    );

    await controller.loadProfile();

    final state = container.read(farmerProfileControllerProvider);

    expect(state, isA<FarmerProfileLoaded>());

    final loaded = state as FarmerProfileLoaded;

    expect(loaded.profile.fullName, 'Raj Test');
    expect(loaded.profile.preferredLanguage, 'mr');
  });

  test('updates farmer profile successfully', () async {
    final repository = FakeFarmerProfileRepository(profile: initialProfile);

    final container = ProviderContainer(
      overrides: [
        farmerProfileRepositoryProvider.overrideWithValue(repository),
      ],
    );

    addTearDown(container.dispose);

    final controller = container.read(farmerProfileControllerProvider.notifier);

    await controller.loadProfile();

    await controller.updateProfile(
      const FarmerProfileUpdateRequest(fullName: 'Raj Ghule', village: 'Loni'),
    );

    final state = container.read(farmerProfileControllerProvider);

    expect(state, isA<FarmerProfileLoaded>());

    final updated = state as FarmerProfileLoaded;

    expect(updated.profile.fullName, 'Raj Ghule');
    expect(updated.profile.village, 'Loni');
    expect(updated.profile.preferredLanguage, 'mr');
  });
}
