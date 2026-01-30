import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/network/api_client.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/config/constants.dart';

/// ================================
/// Core Services Providers
/// ================================

/// Provider for SecureStorageApi
final secureStorageProvider = Provider<SecureStorageApi>((ref) {
  return SecureStorageApi();
});

/// Provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(secureStorage: ref.read(secureStorageProvider));
});

/// Provider for WebService (IWebService)
final webServiceProvider = Provider<IWebService>((ref) {
  return WebService(
    secureStorage: ref.read(secureStorageProvider),
    baseUrl: versionApiUrl,
    apiKey: apiKey,
  );
});
