import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import 'farm_boundary_api.dart';
import 'farm_boundary_repository.dart';
import 'farm_boundary_repository_contract.dart';

final farmBoundaryApiProvider = Provider<FarmBoundaryApi>((ref) {
  return FarmBoundaryApi(ref.read(apiClientProvider));
});

final farmBoundaryRepositoryProvider = Provider<FarmBoundaryRepositoryContract>(
  (ref) {
    return FarmBoundaryRepository(ref.read(farmBoundaryApiProvider));
  },
);
