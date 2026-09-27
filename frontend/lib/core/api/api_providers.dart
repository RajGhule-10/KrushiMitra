import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_providers.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8000'
      : 'http://127.0.0.1:8000';

  return ApiClient(
    tokenStore: ref.read(tokenStorageProvider),
    baseUrl: baseUrl,
  );
});
