import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/data/datasources/remote/pusher_datasource.dart';
import 'package:mts/providers/app/app_providers.dart';

/// Provider for PusherDatasource with internet state callback
/// This creates a PusherDatasource instance that automatically updates
/// the app's internet connectivity state through Riverpod
final pusherDatasourceProvider = Provider<PusherDatasource>((ref) {
  return PusherDatasource(
    ref: ref, // Pass Ref for accessing other providers
    secureStorage: ref.read(secureStorageApiProvider),
    onInternetStateChanged: (hasInternet) {
      // Update the app provider when internet state changes
      ref.read(appProvider.notifier).setEverDontHaveInternet(!hasInternet);
    },
  );
});
