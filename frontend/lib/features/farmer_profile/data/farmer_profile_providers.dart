import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import 'farmer_profile_api.dart';
import 'farmer_profile_repository.dart';
import 'farmer_profile_repository_contract.dart';

final farmerProfileApiProvider = Provider<FarmerProfileApi>((ref) {
  return FarmerProfileApi(ref.read(apiClientProvider));
});

final farmerProfileRepositoryProvider =
    Provider<FarmerProfileRepositoryContract>((ref) {
      return FarmerProfileRepository(ref.read(farmerProfileApiProvider));
    });
