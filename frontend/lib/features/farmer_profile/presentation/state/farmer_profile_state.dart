import '../../data/models/farmer_profile.dart';

sealed class FarmerProfileState {
  const FarmerProfileState();
}

class FarmerProfileInitial extends FarmerProfileState {
  const FarmerProfileInitial();
}

class FarmerProfileLoading extends FarmerProfileState {
  const FarmerProfileLoading();
}

class FarmerProfileLoaded extends FarmerProfileState {
  const FarmerProfileLoaded(this.profile);

  final FarmerProfile profile;
}

class FarmerProfileError extends FarmerProfileState {
  const FarmerProfileError(this.message);

  final String message;
}

class FarmerProfileUpdating extends FarmerProfileState {
  const FarmerProfileUpdating(this.profile);

  final FarmerProfile profile;
}
