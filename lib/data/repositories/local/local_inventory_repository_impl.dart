import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/inventory/inventory_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/inventory_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mts/core/storage/hive_box_manager.dart';

final inventoryBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(InventoryModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final inventoryLocalRepoProvider = Provider<LocalInventoryRepository>((ref) {
  return LocalInventoryRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    hiveBox: ref.read(inventoryBoxProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalInventoryRepository] that uses local database
class LocalInventoryRepositoryImpl implements LocalInventoryRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String cName = 'name';
  static const String cId = 'id';
  static const String cCompanyId = 'company_id';
  static const String cCurrentQuantity = 'current_quantity';
  static const String cAverageCost = 'average_cost';
  static const String cSellingPrice = 'selling_price';
  static const String cLastCost = 'last_cost';
  static const String cCreatedById = 'created_by_id';
  static const String cUpdatedById = 'updated_by_id';
  static const String cCreatedAt = 'created_at';
  static const String cUpdatedAt = 'updated_at';
  static const String cCategoryId = 'category_id';
  static const String cIsEnabled = 'is_enabled';
  static const String tableName = 'inventories';

  /// Constructor
  LocalInventoryRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _hiveBox = hiveBox,
       _pendingChangesRepository = pendingChangesRepository;

  /// Create the inventory table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cName TEXT NULL,
      $cId TEXT PRIMARY KEY,
      $cCompanyId TEXT NOT NULL,
      $cCurrentQuantity FLOAT DEFAULT 0,
      $cAverageCost FLOAT DEFAULT 0,
      $cSellingPrice FLOAT DEFAULT 0,
      $cLastCost FLOAT DEFAULT 0,
      $cCreatedById TEXT NULL,
      $cUpdatedById TEXT NULL,
      $cCreatedAt TIMESTAMP NULL,
      $cUpdatedAt TIMESTAMP NULL,
      $cCategoryId TEXT NULL,
      $cIsEnabled INTEGER DEFAULT 1
    ''';

    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new inventory record
  @override
  Future<int> insert(
    InventoryModel inventoryModel, {
    required bool isInsertToPending,
  }) async {
    inventoryModel.id ??= IdUtils.generateUUID().toString();
    inventoryModel.updatedAt = DateTime.now();
    inventoryModel.createdAt = DateTime.now();

    try {
      // Insert to SQLite
      int result = await _dbHelper.insertDb(tableName, inventoryModel.toJson());

      // Insert to Hive
      await _hiveBox.put(inventoryModel.id!, inventoryModel.toJson());

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'created',
          modelName: InventoryModel.modelName,
          modelId: inventoryModel.id!,
          data: jsonEncode(inventoryModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error inserting inventory', e);
      rethrow;
    }
  }

  /// Update an existing inventory record
  @override
  Future<int> update(
    InventoryModel inventoryModel, {
    required bool isInsertToPending,
  }) async {
    inventoryModel.updatedAt = DateTime.now();

    try {
      // Update SQLite
      int result = await _dbHelper.updateDb(tableName, inventoryModel.toJson());

      // Update Hive
      await _hiveBox.put(inventoryModel.id!, inventoryModel.toJson());
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'updated',
          modelName: InventoryModel.modelName,
          modelId: inventoryModel.id,
          data: jsonEncode(inventoryModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error updating inventory', e);
      rethrow;
    }
  }

  /// Delete an inventory record by ID
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
      final model = InventoryModel.fromJson(results.first);

      // Delete the record
      await removeFromHiveBox(id);
      int result = await _dbHelper.deleteDb(tableName, id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: InventoryModel.modelName,
          modelId: model.id!,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No inventory record found with id: $id');
      return 0;
    }
  }

  /// Delete multiple inventory records
  @override
  Future<bool> deleteBulk(
    List<InventoryModel> listInventory, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();
    List<String> idModels =
        listInventory
            .map((e) => e.id ?? '')
            .where((e) => e.isNotEmpty)
            .toList();

    if (idModels.isEmpty) {
      return false;
    }

    try {
      // If we need to insert to pending changes, we need to get the models first
      if (isInsertToPending) {
        for (InventoryModel model in listInventory) {
          if (model.id != null) {
            final pendingChange = PendingChangesModel(
              operation: 'deleted',
              modelName: InventoryModel.modelName,
              modelId: model.id!,
              data: jsonEncode(model.toJson()),
            );
            await _pendingChangesRepository.insert(pendingChange);
          }
        }
      }

      // Remove from Hive box
      await Future.wait(idModels.map((id) => removeFromHiveBox(id)));

      // Delete from database using batch
      String whereIn = idModels.map((_) => '?').join(',');
      batch.delete(tableName, where: '$cId IN ($whereIn)', whereArgs: idModels);

      await batch.commit(noResult: true);
      return true;
    } catch (e) {
      prints('Error deleting bulk inventory: $e');
      return false;
    }
  }

  /// Delete all inventory records
  @override
  Future<bool> deleteAll() async {
    try {
      Database db = await _dbHelper.database;
      await db.delete(tableName);

      // Clear Hive box
      await _hiveBox.clear();

      return true;
    } catch (e) {
      prints('Error deleting all inventories: $e');
      return false;
    }
  }

  /// Get all inventory records
  @override
  Future<List<InventoryModel>> getListInventoryModel() async {
    List<InventoryModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => InventoryModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list;
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return InventoryModel.fromJson(maps[index]);
    });
  }

  /// Get an inventory record by ID
  @override
  Future<InventoryModel?> getInventoryModelById(String inventoryId) async {
    List<InventoryModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => InventoryModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list.where((i) => i.id == inventoryId).firstOrNull;
    }
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [inventoryId],
    );

    if (results.isNotEmpty) {
      return InventoryModel.fromJson(results.first);
    }
    return null;
  }

  /// Insert multiple inventory records
  @override
  Future<bool> upsertBulk(
    List<InventoryModel> listInventory, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // First, collect all existing IDs in a single query to check for creates vs updates
      final idsToInsert =
          listInventory.map((m) => m.id).whereType<String>().toList();

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
      Batch batch = db.batch();

      for (InventoryModel model in listInventory) {
        // Set timestamps if not already set
        model.id ??= IdUtils.generateUUID().toString();
        model.createdAt ??= DateTime.now();
        model.updatedAt ??= DateTime.now();

        if (model.id == null) continue;

        final isExisting = existingIds.contains(model.id);
        final modelJson = model.toJson();

        if (isExisting) {
          // Only update if new item is newer than existing one
          batch.update(
            tableName,
            modelJson,
            where: '$cId = ? AND ($cUpdatedAt IS NULL OR $cUpdatedAt <= ?)',
            whereArgs: [
              model.id,
              DateTimeUtils.getDateTimeFormat(model.updatedAt),
            ],
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'updated',
                modelName: InventoryModel.modelName,
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
                modelName: InventoryModel.modelName,
                modelId: model.id!,
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
      for (var model in listInventory) {
        if (model.id != null) {
          dataMap[model.id!] = model.toJson();
        }
      }
      await _hiveBox.putAll(dataMap);

      // Track pending changes AFTER successful batch commit
      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      prints('Error inserting bulk inventory: $e');
      return false;
    }
  }

  /// Replace all data in the table with new data
  @override
  Future<bool> replaceAllData(
    List<InventoryModel> newData, {
    bool isInsertToPending = false,
  }) async {
    Database db = await _dbHelper.database;
    await db.delete(tableName);

    for (var inventory in newData) {
      await insert(inventory, isInsertToPending: isInsertToPending);
    }
    return true;
  }

  /// Synchronize local data with server data

  /// Refresh bulk Hive box: replaces all items with provided list, deletes items not in the new list
  ///
  /// This method synchronizes the Hive cache with a new list of inventories. It:
  /// 1. Creates a map of new items to cache
  /// 2. Identifies items to delete (present in cache but not in new list)
  /// 3. Deletes items not in the new list
  /// 4. Batch puts all new items to Hive box
  /// 5. Queues all items for sync with HiveSyncHelper
  ///
  /// Parameters:
  /// - [list]: List of InventoryModel to refresh in Hive box
  /// - [isInsertToPending]: Whether to track changes in pending changes (default: true)
  ///
  /// Returns: true if successful, false otherwise

  /// Remove a single item from Hive box by ID
  ///
  /// This method deletes a specific inventory from the Hive cache.
  ///
  /// Parameters:
  /// - [idModel]: The ID of the inventory to remove from Hive box
  ///
  /// Returns: true if successful, false otherwise
  Future<bool> removeFromHiveBox(String idModel) async {
    try {
      if (_hiveBox.containsKey(idModel)) {
        await _hiveBox.delete(idModel);
        await LogUtils.info('Item $idModel removed from Hive box');
        return true;
      } else {
        await LogUtils.info('Item $idModel not found in Hive box');
        return false;
      }
    } catch (e) {
      await LogUtils.error('Error removing item $idModel from Hive box', e);
      return false;
    }
  }

  @override
  Future<List<InventoryModel>> getListInventoryModelByInvIds(
    List<String?> invIds,
  ) async {
    final validIds = invIds.whereType<String>().toList();
    if (validIds.isEmpty) {
      return [];
    }

    List<InventoryModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => InventoryModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list.where((i) => validIds.contains(i.id)).toList();
    }
    Database db = await _dbHelper.database;

    final placeholders = List.filled(validIds.length, '?').join(',');

    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$cId IN ($placeholders)',
      whereArgs: validIds,
    );

    return List.generate(results.length, (index) {
      return InventoryModel.fromJson(results[index]);
    });
  }
}
