import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/permission/permission_model.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/permission_repository.dart';
import 'package:sqflite/sqflite.dart';

final permissionBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(PermissionModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final permissionLocalRepoProvider = Provider<LocalPermissionRepository>((ref) {
  return LocalPermissionRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(permissionBoxProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalPermissionRepository] that uses local database
class LocalPermissionRepositoryImpl implements LocalPermissionRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String tableName = 'permissions';
  static const String cId = 'id';
  static const String name = 'name';
  static const String description = 'description';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  /// Constructor
  LocalPermissionRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the permission table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $name TEXT NULL,
      $description TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new permission
  @override
  Future<int> insert(
    PermissionModel model, {
    required bool isInsertToPending,
  }) async {
    model.id ??= IdUtils.generateUUID();
    int result = await _dbHelper.insertDb(tableName, model.toJson());

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'created',
        modelName: PermissionModel.modelName,
        modelId: model.id!,
        data: jsonEncode(model.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }
    await _hiveBox.put(model.id, model.toJson());

    return result;
  }

  @override
  Future<int> update(
    PermissionModel model, {
    required bool isInsertToPending,
  }) async {
    model.updatedAt = DateTime.now();
    int result = await _dbHelper.updateDb(tableName, model.toJson());

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: PermissionModel.modelName,
        modelId: model.id!,
        data: jsonEncode(model.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }
    await _hiveBox.put(model.id, model.toJson());

    return result;
  }

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
      final model = PermissionModel.fromJson(results.first);

      // Delete the record
      await _hiveBox.delete(id);
      int result = await _dbHelper.deleteDb(tableName, id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: PermissionModel.modelName,
          modelId: model.id!,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No permission record found with id: $id');
      return 0;
    }
  }

  @override
  Future<List<PermissionModel>> getListPermissions() async {
    List<PermissionModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: PermissionModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list;
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);

    return List.generate(maps.length, (i) {
      return PermissionModel.fromJson(maps[i]);
    });
  }

  @override
  Future<List<PermissionModel>> getListPermissionModel() =>
      getListPermissions();

  @override
  Future<PermissionModel?> getPermissionById(String idPermission) async {
    try {
      List<PermissionModel> list = HiveSyncHelper.getListFromBox(
        box: _hiveBox,
        fromJson: PermissionModel.fromJson,
      );
      final hiveModel = list.firstWhere(
        (element) => element.id == idPermission,
        orElse: () => throw Exception('Not found in Hive'),
      );
      return hiveModel;
    } catch (e) {
      Database db = await _dbHelper.database;
      List<Map<String, dynamic>> result = await db.query(
        tableName,
        where: '$cId = ?',
        whereArgs: [idPermission],
      );

      if (result.isNotEmpty) {
        return PermissionModel.fromJson(result.first);
      } else {
        return null;
      }
    }
  }

  @override
  Future<bool> upsertBulk(
    List<PermissionModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // First, collect all names to check existence (permission is unique by name)
      final namesToInsert =
          list.map((m) => m.name).whereType<String>().toList();

      final existingNames = <String>{};
      if (namesToInsert.isNotEmpty) {
        final placeholders = List.filled(namesToInsert.length, '?').join(',');
        final existingRecords = await db.query(
          tableName,
          where: '$name IN ($placeholders)',
          whereArgs: namesToInsert,
          columns: [name],
        );
        existingNames.addAll(existingRecords.map((r) => r[name] as String));
      }

      // Prepare pending changes to track after batch commit
      final pendingChanges = <PendingChangesModel>[];

      // Use a single batch for all operations (atomic)
      final batch = db.batch();

      for (final model in list) {
        if (model.name == null) continue;

        final isExisting = existingNames.contains(model.name);
        final modelJson = model.toJson();

        if (isExisting) {
          // Only update if new item is newer than existing one
          batch.update(
            tableName,
            modelJson,
            where: '$name = ? AND ($updatedAt IS NULL OR $updatedAt <= ?)',
            whereArgs: [
              model.name,
              DateTimeUtils.getDateTimeFormat(model.updatedAt),
            ],
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'updated',
                modelName: PermissionModel.modelName,
                modelId: model.id!,
                data: jsonEncode(modelJson),
              ),
            );
          }
        } else {
          // New item - use INSERT OR IGNORE for atomic conflict resolution
          batch.rawInsert(
            '''INSERT OR IGNORE INTO $tableName (${modelJson.keys.join(',')})
               VALUES (${List.filled(modelJson.length, '?').join(',')})''',
            modelJson.values.toList(),
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'created',
                modelName: PermissionModel.modelName,
                modelId: model.id!,
                data: jsonEncode(modelJson),
              ),
            );
          }
        }
      }

      // Commit batch atomically
      await batch.commit(noResult: true);

      // Sync to Hive cache after successful batch commit
      await _hiveBox.putAll(
        Map.fromEntries(
          list
              .where((m) => m.id != null)
              .map((m) => MapEntry(m.id!, m.toJson())),
        ),
      );

      // Track pending changes AFTER successful batch commit
      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      prints('Error inserting bulk permission: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await Future.wait([_hiveBox.clear(), db.delete(tableName)]);
      return true;
    } catch (e) {
      prints('Error deleting all permission: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteBulk(
    List<PermissionModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    try {
      // If we need to insert to pending changes, we need to get the models first
      if (isInsertToPending) {
        for (PermissionModel model in list) {
          List<Map<String, dynamic>> results = await db.query(
            tableName,
            where: '$cId = ?',
            whereArgs: [model.id],
          );

          if (results.isNotEmpty) {
            final existingModel = PermissionModel.fromJson(results.first);

            // Insert to pending changes
            final pendingChange = PendingChangesModel(
              operation: 'deleted',
              modelName: PermissionModel.modelName,
              modelId: existingModel.id!,
              data: jsonEncode(existingModel.toJson()),
            );
            await _pendingChangesRepository.insert(pendingChange);
          }
        }
      }

      // Now delete the records
      for (PermissionModel model in list) {
        batch.delete(tableName, where: '$cId = ?', whereArgs: [model.id]);
      }

      await batch.commit(noResult: true);
      await _hiveBox.deleteAll(list.map((m) => m.id).whereType<String>());
      return true;
    } catch (e) {
      prints('Error deleting bulk permission: $e');
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<PermissionModel> newData, {
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
