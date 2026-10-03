import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import 'crop_health_api.dart';
import 'crop_health_repository.dart';
import 'crop_health_repository_contract.dart';

final cropHealthApiProvider = Provider<CropHealthApi>((ref) {
  return CropHealthApi(ref.read(apiClientProvider));
});

final cropHealthRepositoryProvider = Provider<CropHealthRepositoryContract>((
  ref,
) {
  return CropHealthRepository(ref.read(cropHealthApiProvider));
});
