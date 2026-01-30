import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/user_repository.dart';
import 'package:sqflite/sqflite.dart';

final userBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(UserModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final userLocalRepoProvider = Provider<LocalUserRepository>((ref) {
  return LocalUserRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(userBoxProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalUserRepository] that uses local database
class LocalUserRepositoryImpl implements LocalUserRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String tableName = 'users';
  static const String cId = 'id';
  static const String name = 'name';
  static const String email = 'email';
  static const String phoneNo = 'phone_no';
  static const String posPermissionJson = 'pos_permissions';
  static const String accessToken = 'access_token';
  static const String password = 'password';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  /// Constructor
  LocalUserRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the user table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId INTEGER PRIMARY KEY,
      $name TEXT NULL,
      $email TEXT NULL,
      $posPermissionJson TEXT NULL,
      $phoneNo TEXT NULL,
      $accessToken TEXT NULL,
      $password TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  @override
  Future<int> insert(
    UserModel userModel, {
    required bool isInsertToPending,
  }) async {
    userModel.createdAt = DateTime.now();
    userModel.updatedAt = DateTime.now();

    try {
      // Insert to SQLite
      int result = await _dbHelper.insertDb(tableName, userModel.toJson());

      // Insert to Hive
      await _hiveBox.put(userModel.id!, userModel.toJson());

      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'created',
          modelName: UserModel.modelName,
          modelId: userModel.id.toString(),
          data: jsonEncode(userModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error inserting user', e);
      rethrow;
    }
  }

  @override
  Future<int> update(
    UserModel userModel, {
    required bool isInsertToPending,
  }) async {
    userModel.updatedAt = DateTime.now();
    try {
      // Update SQLite
      int result = await _dbHelper.updateDb(tableName, userModel.toJson());

      // Update Hive
      await _hiveBox.put(userModel.id!, userModel.toJson());

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'updated',
          modelName: UserModel.modelName,
          modelId: userModel.id.toString(),
          data: jsonEncode(userModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }
      return result;
    } catch (e) {
      await LogUtils.error('Error updating cash management', e);
      rethrow;
    }
  }

  // delete using id
  @override
  Future<int> delete(String id, {required bool isInsertToPending}) async {
    // Get the model before deleting it
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      final model = UserModel.fromJson(results.first);

      // Delete the record
      await _hiveBox.delete(id);
      int result = await _dbHelper.deleteDb(tableName, id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: UserModel.modelName,
          modelId: model.id.toString(),
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No user record found with id: $id');
      return 0;
    }
  }

  // get list users
  @override
  Future<List<UserModel>> getListUserModels() async {
    List<UserModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => UserModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list;
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return UserModel.fromJson(maps[index]);
    });
  }

  // insert bulk
  @override
  Future<bool> upsertBulk(
    List<UserModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // First, collect all existing IDs in a single query to check for creates vs updates
      // This eliminates the race condition: single query instead of per-item checks
      final idsToInsert = list.map((m) => m.id).whereType<int>().toList();

      final existingIds = <int>{};
      if (idsToInsert.isNotEmpty) {
        final placeholders = List.filled(idsToInsert.length, '?').join(',');
        final existingRecords = await db.query(
          tableName,
          where: '$cId IN ($placeholders)',
          whereArgs: idsToInsert,
          columns: [cId],
        );
        existingIds.addAll(existingRecords.map((r) => r[cId] as int));
      }

      // Prepare pending changes to track after batch commit
      final List<PendingChangesModel> pendingChanges = [];

      // Use a single batch for all operations (atomic)
      // Key: Only ONE pre-flight check before batch, not per-item checks
      Batch batch = db.batch();

      for (UserModel model in list) {
        if (model.id == null) continue;

        final isExisting = existingIds.contains(model.id);
        final modelJson = model.toJson();

        if (isExisting) {
          // Only update if new item is newer than existing one
          batch.update(
            tableName,
            modelJson,
            where: '$cId = ? AND ($updatedAt IS NULL OR $updatedAt <= ?)',
            whereArgs: [
              model.id,
              DateTimeUtils.getDateTimeFormat(model.updatedAt),
            ],
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'updated',
                modelName: UserModel.modelName,
                modelId: model.id!.toString(),
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
                modelName: UserModel.modelName,
                modelId: model.id!.toString(),
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
      for (var model in list) {
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
      prints('Error inserting bulk user: $e');
      return false;
    }
  }

  // delete bulk users
  @override
  Future<bool> deleteBulk(
    List<UserModel> users, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    try {
      // If we need to insert to pending changes, we need to get the models first
      if (isInsertToPending) {
        for (UserModel user in users) {
          List<Map<String, dynamic>> results = await db.query(
            tableName,
            where: '$cId = ?',
            whereArgs: [user.id],
          );

          if (results.isNotEmpty) {
            final model = UserModel.fromJson(results.first);

            // Insert to pending changes
            final pendingChange = PendingChangesModel(
              operation: 'deleted',
              modelName: UserModel.modelName,
              modelId: model.id!.toString(),
              data: jsonEncode(model.toJson()),
            );
            await _pendingChangesRepository.insert(pendingChange);
          }
        }
      }

      // Now delete the records
      for (UserModel user in users) {
        batch.delete(tableName, where: '$cId = ?', whereArgs: [user.id]);
      }

      await batch.commit(noResult: true);

      // Delete from Hive cache
      final idsToDelete = users.map((u) => u.id).whereType<int>().toList();
      if (idsToDelete.isNotEmpty) {
        await _hiveBox.deleteAll(idsToDelete);
      }

      return true;
    } catch (e) {
      prints('Error deleting bulk users: $e');
      return false;
    }
  }

  // delete all users
  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await db.delete(tableName);
      await _hiveBox.clear();
      return true;
    } catch (e) {
      prints('Error deleting all users: $e');
      return false;
    }
  }

  @override
  Future<UserModel?> getUserModelByIdUser(int idUser) async {
    List<UserModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => UserModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list.where((element) => element.id == idUser).firstOrNull;
    }
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [idUser],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return UserModel.fromJson(maps.first);
    } else {
      return null;
    }
  }

  @override
  Future<UserModel?> getUserModelFromStaffId(String staffId) async {
    // Try to get staff from Hive first
    final hiveModel = HiveSyncHelper.getById(
      box: _hiveBox,
      id: staffId,
      fromJson: (json) => UserModel.fromJson(json),
    );

    if (hiveModel != null) {
      return hiveModel;
    }

    // Fallback to SQLite
    final map = await _dbHelper.readDbById(tableName, staffId);
    if (map != null) {
      return UserModel.fromJson(map);
    }
    return null;
  }

  @override
  Future<bool> replaceAllData(
    List<UserModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      // Step 1: Delete all existing data
      Database db = await _dbHelper.database;
      await db.delete(tableName);
      await _hiveBox.clear();

      // Step 2: Insert new data using existing insertBulk method
      if (newData.isNotEmpty) {
        bool insertResult = await upsertBulk(
          newData,
          isInsertToPending: isInsertToPending,
        );
        if (!insertResult) {
          prints('Failed to insert bulk data in $tableName');
          return false;
        }
      }

      // Note: Pending changes for insertion are handled by insertBulk method
      // when isInsertToPending is true

      return true;
    } catch (e) {
      prints('Error replacing all data in $tableName: $e');
      return false;
    }
  }
}
