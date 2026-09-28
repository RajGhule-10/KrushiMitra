import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/farmer_profile_providers.dart';
import '../../data/models/farmer_profile_update_request.dart';
import 'farmer_profile_state.dart';

final farmerProfileControllerProvider =
    NotifierProvider<FarmerProfileController, FarmerProfileState>(
      FarmerProfileController.new,
    );

class FarmerProfileController extends Notifier<FarmerProfileState> {
  @override
  FarmerProfileState build() {
    return const FarmerProfileInitial();
  }

  Future<void> loadProfile() async {
    state = const FarmerProfileLoading();

    try {
      final profile = await ref
          .read(farmerProfileRepositoryProvider)
          .getProfile();

      state = FarmerProfileLoaded(profile);
    } catch (error) {
      state = FarmerProfileError(
        'Unable to load your profile. Please try again.',
      );
    }
  }

  Future<void> updateProfile(FarmerProfileUpdateRequest request) async {
    final currentState = state;

    if (currentState is! FarmerProfileLoaded) {
      return;
    }

    state = FarmerProfileUpdating(currentState.profile);

    try {
      final profile = await ref
          .read(farmerProfileRepositoryProvider)
          .updateProfile(request);

      state = FarmerProfileLoaded(profile);
    } catch (error) {
      state = FarmerProfileError(
        'Unable to update your profile. Please try again.',
      );
    }
  }
}
