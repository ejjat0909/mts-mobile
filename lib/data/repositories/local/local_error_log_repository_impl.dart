import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/core/storage/secure_storage_api.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/error_log/error_log_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/domain/repositories/local/error_log_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

final errorLogBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(ErrorLogModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final errorLogLocalRepoProvider = Provider<LocalErrorLogRepository>((ref) {
  return LocalErrorLogRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(errorLogBoxProvider),
    secureStorageApi: ref.read(secureStorageApiProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalErrorLogRepository] that uses local database
class LocalErrorLogRepositoryImpl implements LocalErrorLogRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;
  final SecureStorageApi _secureStorageApi;

  /// Database table and column names
  static const String cId = 'id';
  static const String cDescription = 'description';
  static const String cDeviceId = 'pos_device_id';
  static const String cDeviceName = 'device_name';
  static const String cCurrentUserId = 'user_id';
  static const String cCurrentUserName = 'current_user_name';
  static const String cCreatedAt = 'created_at';
  static const String cUpdatedAt = 'updated_at';
  static const String tableName = 'error_logs';

  /// Constructor
  LocalErrorLogRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
    required SecureStorageApi secureStorageApi,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox,
       _secureStorageApi = secureStorageApi;

  /// Create the table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $cDescription TEXT NULL,
      $cDeviceId TEXT NULL,
      $cDeviceName TEXT NULL,
      $cCurrentUserId INTEGER NULL,
      $cCurrentUserName TEXT NULL,
      $cCreatedAt TIMESTAMP DEFAULT NULL,
      $cUpdatedAt TIMESTAMP DEFAULT NULL
    ''';

    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new error log record
  @override
  Future<int> insert(
    ErrorLogModel errorLogModel, {
    required bool isInsertToPending,
  }) async {
    errorLogModel.id ??= IdUtils.generateUUID();
    errorLogModel.createdAt = DateTime.now();
    errorLogModel.updatedAt = DateTime.now();

    try {
      // Insert to SQLite
      int result = await _dbHelper.insertDb(tableName, errorLogModel.toJson());

      // Insert to Hive
      await _hiveBox.put(errorLogModel.id!.toString(), errorLogModel.toJson());

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'created',
          modelName: ErrorLogModel.modelName,
          modelId: errorLogModel.id.toString(),
          data: jsonEncode(errorLogModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error inserting error log', e);
      rethrow;
    }
  }

  /// Update an existing error log record
  @override
  Future<int> update(
    ErrorLogModel errorLogModel, {
    required bool isInsertToPending,
  }) async {
    errorLogModel.updatedAt = DateTime.now();

    try {
      // Update SQLite
      int result = await _dbHelper.updateDb(tableName, errorLogModel.toJson());

      // Update Hive
      await _hiveBox.put(errorLogModel.id!.toString(), errorLogModel.toJson());

      return result;
    } catch (e) {
      await LogUtils.error('Error updating error log', e);
      rethrow;
    }
  }

  /// Delete multiple error log records
  @override
  Future<bool> deleteBulk(
    List<ErrorLogModel> listErrorLog, {
    required bool isInsertToPending,
  }) async {
    try {
      for (var errorLog in listErrorLog) {
        if (errorLog.id != null) {
          await delete(
            errorLog.id.toString(),
            isInsertToPending: isInsertToPending,
          );
        }
      }
      return true;
    } catch (e) {
      await LogUtils.error('Error deleting bulk error logs', e);
      return false;
    }
  }

  /// Delete an error log record by ID
  @override
  Future<int> delete(String id, {required bool isInsertToPending}) async {
    try {
      // Delete from SQLite
      int result = await _dbHelper.deleteDb(tableName, id);

      // Delete from Hive
      await _hiveBox.delete(id);

      return result;
    } catch (e) {
      await LogUtils.error('Error deleting error log', e);
      rethrow;
    }
  }

  /// Delete all error log records
  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await db.delete(tableName);

      // Clear Hive box
      await _hiveBox.clear();

      return true;
    } catch (e) {
      prints('Error deleting all error logs: $e');
      return false;
    }
  }

  /// Get all error log records
  @override
  Future<List<ErrorLogModel>> getListErrorLogModel() async {
    // ✅ Try Hive first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => ErrorLogModel.fromJson(json),
    );

    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (i) {
      return ErrorLogModel.fromJson(maps[i]);
    });
  }

  /// Insert multiple error log records
  @override
  Future<bool> upsertBulk(
    List<ErrorLogModel> listErrorLog, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // First, collect all existing IDs in a single query to check for creates vs updates
      // This eliminates the race condition: single query instead of per-item checks
      final idsToInsert =
          listErrorLog.map((m) => m.id).whereType<String>().toList();

      final existingIds = <String>{};
      if (idsToInsert.isNotEmpty) {
        final placeholders = List.filled(idsToInsert.length, '?').join(',');
        final existingRecords = await db.query(
          tableName,
          where: '$cId IN ($placeholders)',
          whereArgs: idsToInsert,
          columns: [cId],
        );
        existingIds.addAll(existingRecords.map((r) => r[cId] as String));
      }

      // Prepare pending changes to track after batch commit
      final List<PendingChangesModel> pendingChanges = [];

      // Use a single batch for all operations (atomic)
      // Key: Only ONE pre-flight check before batch, not per-item checks
      Batch batch = db.batch();

      for (ErrorLogModel model in listErrorLog) {
        if (model.id == null) continue;

        final isExisting = existingIds.contains(model.id);
        final modelJson = model.toJson();

        if (isExisting) {
          // Only update if new item is newer than existing one
          batch.update(
            tableName,
            modelJson,
            where: '$cId = ? AND ($cCreatedAt IS NULL OR $cCreatedAt <= ?)',
            whereArgs: [
              model.id,
              DateTimeUtils.getDateTimeFormat(model.createdAt),
            ],
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'updated',
                modelName: ErrorLogModel.modelName,
                modelId: model.id.toString(),
                data: jsonEncode(modelJson),
              ),
            );
          }
        } else {
          // New item - use INSERT OR IGNORE for atomic conflict resolution
          // If two workers race here, one succeeds, the other is silently ignored
          batch.rawInsert(
            '''INSERT OR IGNORE INTO $tableName (${modelJson.keys.join(',')})
               VALUES (${List.filled(modelJson.length, '?').join(',')})''',
            modelJson.values.toList(),
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'created',
                modelName: ErrorLogModel.modelName,
                modelId: model.id.toString(),
                data: jsonEncode(modelJson),
              ),
            );
          }
        }
      }

      // Commit batch atomically
      await batch.commit(noResult: true);

      // Bulk insert to Hive
      final dataMap = <dynamic, Map<dynamic, dynamic>>{};
      for (var model in listErrorLog) {
        if (model.id != null) {
          dataMap[model.id!] = model.toJson();
        }
      }
      await _hiveBox.putAll(dataMap);

      // Track pending changes AFTER successful batch commit
      // This ensures we only track changes that actually succeeded
      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      prints('Error inserting bulk error log: $e');
      return false;
    }
  }

  @override
  Future<void> createAndInsertErrorLog(String message) async {
    // Get device and user from secure storage
    final deviceJson = await _secureStorageApi.readObject('device') ?? {};
    final userJson = await _secureStorageApi.readObject('user') ?? {};
    final deviceModel = PosDeviceModel.fromJson(deviceJson);
    final userModel = UserModel.fromJson(userJson);

    ErrorLogModel errorLogModel = ErrorLogModel(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      id: IdUtils.generateUUID(),
      description: message,
      posDeviceId: deviceModel.id,
      deviceName: deviceModel.name,
      currentUserName: userModel.name,
      userId: userModel.id,
    );

    await insert(errorLogModel, isInsertToPending: true);
  }
}
