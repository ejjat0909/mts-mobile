import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/app/di/service_locator_pusher_extension.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/network/api_client.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/datasources/local/storage_datasource.dart';
import 'package:mts/data/datasources/remote/api_datasource.dart';
import 'package:mts/data/datasources/remote/auth_datasource.dart';
import 'package:mts/data/repositories/remote/sync_repository_impl.dart';
import 'package:mts/domain/repositories/remote/sync_repository.dart';

/// Service locator for dependency injection
class ServiceLocator {
  static final GetIt _getIt = GetIt.instance;

  /// Initialize service locator
  static void init() {
    // Register SecureStorageApi
    _getIt.registerLazySingleton<SecureStorageApi>(() => SecureStorageApi());

    // Register API client
    _getIt.registerLazySingleton<ApiClient>(
      () => ApiClient(secureStorage: _getIt<SecureStorageApi>()),
    );

    // Register Dio for HTTP requests

    _getIt.registerLazySingleton<Dio>(
      () => Dio(
        BaseOptions(
          baseUrl: versionApiUrl,
          connectTimeout: kDefaultTimeout,
          receiveTimeout: kDefaultTimeout,
        ),
      ),
    );

    // Register WebService
    _getIt.registerLazySingleton<IWebService>(
      () => WebService(
        secureStorage: _getIt<SecureStorageApi>(),
        baseUrl: versionApiUrl,
        apiKey: apiKey,
      ),
    );

    // Register datasources
    _getIt.registerLazySingleton<AuthDatasource>(
      () => AuthDatasource(
        apiClient: _getIt<ApiClient>(),
        secureStorage: _getIt<SecureStorageApi>(),
      ),
    );

    // Register other datasources
    _getIt.registerLazySingleton<StorageDatasource>(
      () => StorageDatasource(secureStorage: _getIt<SecureStorageApi>()),
    );

    // Register ApiDatasource
    _getIt.registerLazySingleton<ApiDatasource>(
      () => ApiDatasource(secureStorage: _getIt<SecureStorageApi>()),
    );

    // Register DatabaseHelpers
    _getIt.registerLazySingleton<IDatabaseHelpers>(() => DatabaseHelpers());

    // Note: PusherDatasource is now managed by Riverpod providers
    // See: pusher_datasource_provider.dart
    // Use ref.read(pusherDatasourceProvider) instead of ServiceLocator

    // Register SyncRepository
    _getIt.registerLazySingleton<SyncRepository>(() => SyncRepositoryImpl());

    // Note: AssetDownloadService and WebSocketService are managed by Riverpod providers
    // See: assetDownloadServiceProvider and webSocketServiceProvider
    // Use ref.read(assetDownloadServiceProvider) or ref.read(webSocketServiceProvider) instead

    // Register Pusher event handling components
    ServiceLocatorPusherExtension.registerPusherEventHandling();
  }

  /// Get a registered instance
  static T get<T extends Object>() => _getIt<T>();

  /// Check if a type is registered
  static bool isRegistered<T extends Object>() => _getIt.isRegistered<T>();

  /// Register a singleton instance
  static void registerSingleton<T extends Object>(T instance) {
    if (_getIt.isRegistered<T>()) {
      _getIt.unregister<T>();
    }
    _getIt.registerSingleton<T>(instance);
  }

  /// Unregister an instance
  static void unregister<T extends Object>() {
    if (_getIt.isRegistered<T>()) {
      _getIt.unregister<T>();
    }
  }

  /// Reset all registered instances
  static Future<void> resetAll() async {
    await _getIt.reset();
  }
}
