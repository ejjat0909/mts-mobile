import 'package:mts/core/config/constants.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/storage/secure_storage_api.dart';

/// Factory class to provide WebService instances
class WebServiceProvider {
  /// Creates and returns a WebService instance with default dependencies
  static IWebService provide() {
    return WebService(
      secureStorage: SecureStorageApi(),
      baseUrl: versionApiUrl,
      apiKey: apiKey,
    );
  }

  /// Creates and returns a WebService instance with custom dependencies
  static IWebService provideCustom({
    required SecureStorageApi secureStorage,
    required String baseUrl,
    required String apiKey,
  }) {
    return WebService(
      secureStorage: secureStorage,
      baseUrl: baseUrl,
      apiKey: apiKey,
    );
  }
}
