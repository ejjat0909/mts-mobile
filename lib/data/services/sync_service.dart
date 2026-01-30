import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/core/storage/secured_storage_key.dart';
import 'package:mts/data/models/meta_model.dart';

/// A generic type for models that can be synced
typedef SyncableModel = dynamic;

/// A generic type for response models
typedef ResponseModel = dynamic;

/// A generic type for request models
typedef RequestModel = dynamic;

class SyncService {
  /// Default chunk size for processing data in batches
  static const int defaultChunkSize = 100;

  static final SecureStorageApi _secureStorageApi =
      ServiceLocator.get<SecureStorageApi>();

  /// Helper method to get last sync time from storage
  static Future<DateTime> getLastSyncTime(String storageKey) async {
    Map<String, dynamic>? metaJson = await _secureStorageApi.readObject(
      storageKey,
    );
    MetaModel? metaModel =
        metaJson == null ? null : MetaModel.fromJson(metaJson);
    return metaModel?.lastSync ?? DateTime.parse("2000-01-01");
  }

  static Future<void> resetLastSyncTime(String storageKey) async {
    MetaModel metaModel = MetaModel(lastSync: DateTime.parse("2000-01-01"));
    await saveMetaData(storageKey, metaModel.toJson());
  }

  /// Helper method to save meta data to storage (save lastt sync at)
  static Future<void> saveMetaData(String storageKey, dynamic meta) async {
    await _secureStorageApi.saveObject(storageKey, meta);
  }

  static Future<void> deleteAllMetadata() async {
    for (String key in SSKey.allKeys) {
      await _secureStorageApi.delete(key: key);
    }
  }
}
