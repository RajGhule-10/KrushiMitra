import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import 'advisory_api.dart';
import 'advisory_repository.dart';
import 'advisory_repository_contract.dart';

final advisoryApiProvider = Provider<AdvisoryApi>((ref) {
  return AdvisoryApi(ref.read(apiClientProvider));
});

final advisoryRepositoryProvider = Provider<AdvisoryRepositoryContract>((ref) {
  return AdvisoryRepository(ref.read(advisoryApiProvider));
});
