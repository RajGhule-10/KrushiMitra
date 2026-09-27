import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import 'auth_providers.dart';
import 'auth_repository.dart';
import 'auth_repository_contract.dart';

final authRepositoryProvider = Provider<AuthRepositoryContract>((ref) {
  return AuthRepository(
    api: ref.read(authApiProvider),
    tokenStore: ref.read(tokenStorageProvider),
  );
});
