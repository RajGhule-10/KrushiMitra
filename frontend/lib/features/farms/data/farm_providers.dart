import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import 'farm_api.dart';
import 'farm_repository.dart';
import 'farm_repository_contract.dart';

final farmApiProvider = Provider<FarmApi>((ref) {
  return FarmApi(ref.read(apiClientProvider));
});

final farmRepositoryProvider = Provider<FarmRepositoryContract>((ref) {
  return FarmRepository(ref.read(farmApiProvider));
});
