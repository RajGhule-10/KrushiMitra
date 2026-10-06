import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import 'crop_api.dart';
import 'crop_repository.dart';
import 'crop_repository_contract.dart';

final cropApiProvider = Provider<CropApi>((ref) {
  return CropApi(ref.read(apiClientProvider));
});

final cropRepositoryProvider = Provider<CropRepositoryContract>((ref) {
  return CropRepository(ref.read(cropApiProvider));
});
