import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/inventory_outlet/inventory_outlet_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/inventory_outlet_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mts/core/storage/hive_box_manager.dart';

final inventoryOutletBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(InventoryOutletModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final inventoryOutletLocalRepoProvider =
    Provider<LocalInventoryOutletRepository>((ref) {
      return LocalInventoryOutletRepositoryImpl(
        dbHelper: ref.read(databaseHelpersProvider),
        hiveBox: ref.read(inventoryOutletBoxProvider),
        pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
      );
    });

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalInventoryOutletRepository] that uses local database
class LocalInventoryOutletRepositoryImpl
    implements LocalInventoryOutletRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String tableName = 'inventory_outlets';
  static const String cId = 'id';
  static const String outletId = 'outlet_id';
  static const String inventoryId = 'inventory_id';
  static const String currentQuantity = 'current_quantity';
  static const String lowStockThreshold = 'low_stock_threshold';
  static const String lowStockNotifiedAt = 'low_stock_notified_at';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String isEnabled = 'is_enabled';

  /// Constructor
  LocalInventoryOutletRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required Box<Map> hiveBox,
    required LocalPendingChangesRepository pendingChangesRepository,
  }) : _dbHelper = dbHelper,
       _hiveBox = hiveBox,
       _pendingChangesRepository = pendingChangesRepository;

  /// Create the inventory outlet table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $outletId TEXT NULL,
      $inventoryId TEXT NULL,
      $currentQuantity REAL DEFAULT 0.0,
      $lowStockThreshold REAL DEFAULT 0.0,
      $lowStockNotifiedAt TIMESTAMP DEFAULT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL,
      $isEnabled INTEGER DEFAULT 1
    ''';

    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new inventory outlet
  @override
  Future<int> insert(
    InventoryOutletModel inventoryOutletModel, {
    required bool isInsertToPending,
  }) async {
    inventoryOutletModel.updatedAt = DateTime.now();
    inventoryOutletModel.createdAt = DateTime.now();

    try {
      // Insert to SQLite
      int result = await _dbHelper.insertDb(
        tableName,
        inventoryOutletModel.toJson(),
      );

      // Insert to Hive
      await _hiveBox.put(
        inventoryOutletModel.id!,
        inventoryOutletModel.toJson(),
      );

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'created',
          modelName: InventoryOutletModel.modelName,
          modelId: inventoryOutletModel.id.toString(),
          data: jsonEncode(inventoryOutletModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error inserting inventory outlet', e);
      rethrow;
    }
  }

  /// Update an existing inventory outlet
  @override
  Future<int> update(
    InventoryOutletModel inventoryOutletModel, {
    required bool isInsertToPending,
  }) async {
    inventoryOutletModel.updatedAt = DateTime.now();

    try {
      // Update SQLite
      int result = await _dbHelper.updateDb(
        tableName,
        inventoryOutletModel.toJson(),
      );

      // Update Hive
      await _hiveBox.put(
        inventoryOutletModel.id!,
        inventoryOutletModel.toJson(),
      );

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'updated',
          modelName: InventoryOutletModel.modelName,
          modelId: inventoryOutletModel.id.toString(),
          data: jsonEncode(inventoryOutletModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error updating inventory outlet', e);
      rethrow;
    }
  }

  /// Delete an inventory outlet by ID
  @override
  Future<int> delete(String id, {required bool isInsertToPending}) async {
    try {
      // Get the model before deleting for pending changes
      Database db = await _dbHelper.database;
      List<Map<String, dynamic>> results = await db.query(
        tableName,
        where: '$cId = ?',
        whereArgs: [id],
      );

      // Delete from SQLite
      int result = await _dbHelper.deleteDb(tableName, id);

      // Delete from Hive
      await _hiveBox.delete(id);

      // Insert to pending changes if required
      if (isInsertToPending && results.isNotEmpty) {
        final model = InventoryOutletModel.fromJson(results.first);
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: InventoryOutletModel.modelName,
          modelId: model.id.toString(),
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error deleting inventory outlet', e);
      rethrow;
    }
  }

  /// Get list of all inventory outlets
  @override
  Future<List<InventoryOutletModel>> getListInventoryOutletModel() async {
    // ✅ Try Hive first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => InventoryOutletModel.fromJson(json),
    );

    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return InventoryOutletModel.fromJson(maps[index]);
    });
  }

  /// Insert multiple inventory outlets
  @override
  Future<bool> upsertBulk(
    List<InventoryOutletModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // Prepare pending changes to track after batch commit
      final List<PendingChangesModel> pendingChanges = [];
      final List<InventoryOutletModel> toInsert = [];
      final List<InventoryOutletModel> toUpdate = [];

      // Build a set of IDs already seen in this batch
      final Set<String> seenIds = {};

      for (InventoryOutletModel newModel in list) {
        if (newModel.id == null) continue;

        // Skip if already processed in this batch
        if (seenIds.contains(newModel.id)) continue;
        seenIds.add(newModel.id!);

        // Query records that need updating (existing and older)
        final List<Map<String, dynamic>> recordsToUpdate = await db.query(
          tableName,
          where: '$cId = ? AND $updatedAt < ?',
          whereArgs: [
            newModel.id,
            DateTimeUtils.getDateTimeFormat(newModel.updatedAt),
          ],
        );

        if (recordsToUpdate.isNotEmpty) {
          // Record exists and is older, add to update list
          toUpdate.add(newModel);
        } else {
          // Check if record exists at all
          final List<Map<String, dynamic>> existingRecords = await db.query(
            tableName,
            where: '$cId = ?',
            whereArgs: [newModel.id],
          );

          if (existingRecords.isEmpty) {
            // Record doesn't exist, add to insert list
            toInsert.add(newModel);
          }
          // else: record exists but is newer or equal, skip it
        }
      }

      // Use a single batch for all operations (atomic)
      Batch batch = db.batch();

      // Batch insert new records
      for (InventoryOutletModel model in toInsert) {
        final modelJson = model.toJson();
        batch.rawInsert(
          '''INSERT INTO $tableName (${modelJson.keys.join(',')})
             VALUES (${List.filled(modelJson.length, '?').join(',')})''',
          modelJson.values.toList(),
        );

        if (isInsertToPending) {
          pendingChanges.add(
            PendingChangesModel(
              operation: 'created',
              modelName: InventoryOutletModel.modelName,
              modelId: model.id!.toString(),
              data: jsonEncode(modelJson),
            ),
          );
        }
      }

      // Batch update existing records
      for (InventoryOutletModel model in toUpdate) {
        model.updatedAt = DateTime.now();
        final modelJson = model.toJson();
        final keys = modelJson.keys.toList();
        final placeholders = keys.map((key) => '$key=?').join(',');

        batch.rawUpdate(
          '''UPDATE $tableName SET $placeholders 
             WHERE $cId = ?''',
          [...modelJson.values, model.id],
        );

        if (isInsertToPending) {
          pendingChanges.add(
            PendingChangesModel(
              operation: 'updated',
              modelName: InventoryOutletModel.modelName,
              modelId: model.id!.toString(),
              data: jsonEncode(modelJson),
            ),
          );
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
      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      prints('Error inserting bulk inventory outlet: $e');
      return false;
    }
  }

  /// Delete multiple inventory outlets
  @override
  Future<bool> deleteBulk(
    List<InventoryOutletModel> inventoryOutlets, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    try {
      // If we need to insert to pending changes, we need to get the models first
      if (isInsertToPending) {
        for (InventoryOutletModel inventoryOutlet in inventoryOutlets) {
          List<Map<String, dynamic>> results = await db.query(
            tableName,
            where: '$cId = ?',
            whereArgs: [inventoryOutlet.id],
          );

          if (results.isNotEmpty) {
            final model = InventoryOutletModel.fromJson(results.first);

            // Insert to pending changes
            final pendingChange = PendingChangesModel(
              operation: 'deleted',
              modelName: InventoryOutletModel.modelName,
              modelId: model.id!.toString(),
              data: jsonEncode(model.toJson()),
            );
            await _pendingChangesRepository.insert(pendingChange);
          }
        }
      }

      // Now delete the records
      for (InventoryOutletModel inventoryOutlet in inventoryOutlets) {
        batch.delete(
          tableName,
          where: '$cId = ?',
          whereArgs: [inventoryOutlet.id],
        );
      }

      await batch.commit(noResult: true);

      // Delete from Hive
      for (var outlet in inventoryOutlets) {
        if (outlet.id != null) {
          await _hiveBox.delete(outlet.id!);
        }
      }

      return true;
    } catch (e) {
      prints('Error deleting bulk inventory outlets: $e');
      return false;
    }
  }

  /// Delete all inventory outlets
  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await db.delete(tableName);

      // Clear Hive box
      await _hiveBox.clear();

      return true;
    } catch (e) {
      prints('Error deleting all inventory outlets: $e');
      return false;
    }
  }

  /// Replace all data with new data
  @override
  Future<bool> replaceAllData(
    List<InventoryOutletModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      // Step 1: Delete all existing data
      Database db = await _dbHelper.database;
      await db.delete(tableName);

      // Clear Hive box
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
