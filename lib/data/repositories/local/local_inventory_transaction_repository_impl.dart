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
import 'package:mts/data/models/inventory_transaction/inventory_transaction_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/inventory_transaction_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mts/core/storage/hive_box_manager.dart';

final inventoryTransactionBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(InventoryTransactionModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final inventoryTransactionLocalRepoProvider =
    Provider<LocalInventoryTransactionRepository>((ref) {
      return LocalInventoryTransactionRepositoryImpl(
        dbHelper: ref.read(databaseHelpersProvider),
        pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
        hiveBox: ref.read(inventoryTransactionBoxProvider),
      );
    });

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalInventoryTransactionRepository] that uses local database
class LocalInventoryTransactionRepositoryImpl
    implements LocalInventoryTransactionRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String cId = 'id';
  static const String cInventoryId = 'inventory_id';
  static const String cCompanyId = 'company_id';
  static const String cOutletId = 'outlet_id';
  static const String cType = 'type';
  static const String cReason = 'reason';
  static const String cQuantity = 'quantity';
  static const String cCountedQuantity = 'counted_quantity';
  static const String cDifferenceQuantity = 'difference_quantity';
  static const String cUnitCost = 'unit_cost';
  static const String cTotalCost = 'total_cost';
  static const String cSupplierId = 'supplier_id';
  static const String cPerformedById = 'performed_by_id';
  static const String cPerformedAt = 'performed_at';
  static const String cNotes = 'notes';
  static const String cCreatedAt = 'created_at';
  static const String cUpdatedAt = 'updated_at';
  static const String cStockAfter = 'stock_after';
  static const String cName = 'name';
  static const String tableName = 'inventory_transactions';

  /// Constructor
  LocalInventoryTransactionRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the inventory_transactions table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $cInventoryId TEXT NOT NULL,
      $cCompanyId TEXT NOT NULL,
      $cOutletId TEXT NULL,
      $cType INTEGER NULL,
      $cReason TEXT NULL,
      $cQuantity FLOAT DEFAULT 0,
      $cCountedQuantity FLOAT DEFAULT 0,
      $cDifferenceQuantity FLOAT DEFAULT 0,
      $cUnitCost FLOAT DEFAULT 0,
      $cTotalCost FLOAT DEFAULT 0,
      $cSupplierId TEXT NULL,
      $cPerformedById TEXT NULL,
      $cPerformedAt TIMESTAMP NULL,
      $cNotes TEXT NULL,
      $cCreatedAt TIMESTAMP NULL,
      $cUpdatedAt TIMESTAMP NULL,
      $cStockAfter FLOAT NULL,
      $cName TEXT NULL
    ''';

    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new inventory transaction record
  @override
  Future<int> insert(
    InventoryTransactionModel inventoryTransactionModel, {
    required bool isInsertToPending,
  }) async {
    inventoryTransactionModel.id ??= IdUtils.generateUUID().toString();
    inventoryTransactionModel.updatedAt = DateTime.now();
    inventoryTransactionModel.createdAt = DateTime.now();

    try {
      // Insert to SQLite
      int result = await _dbHelper.insertDb(
        tableName,
        inventoryTransactionModel.toJson(),
      );

      // Insert to Hive
      await _hiveBox.put(
        inventoryTransactionModel.id!,
        inventoryTransactionModel.toJson(),
      );

      if (isInsertToPending) {
        await _insertPending(inventoryTransactionModel, 'created');
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error inserting discount', e);
      rethrow;
    }
  }

  /// Update an existing inventory transaction record
  @override
  Future<int> update(
    InventoryTransactionModel inventoryTransactionModel, {
    required bool isInsertToPending,
  }) async {
    inventoryTransactionModel.updatedAt = DateTime.now();

    try {
      // Update SQLite
      int result = await _dbHelper.updateDb(
        tableName,
        inventoryTransactionModel.toJson(),
      );

      // Update Hive
      await _hiveBox.put(
        inventoryTransactionModel.id!,
        inventoryTransactionModel.toJson(),
      );

      if (isInsertToPending) {
        await _insertPending(inventoryTransactionModel, 'updated');
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error updating inventory transaction', e);
      rethrow;
    }
  }

  /// Delete an inventory transaction record by ID
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
      final model = InventoryTransactionModel.fromJson(results.first);

      // Delete the record
      await _hiveBox.delete(id);
      int result = await _dbHelper.deleteDb(tableName, id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: InventoryTransactionModel.modelName,
          modelId: model.id!,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    }

    return 0;
  }

  /// Delete multiple inventory transaction records
  @override
  Future<bool> deleteBulk(
    List<InventoryTransactionModel> listInventoryTransaction, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();
    List<String> idModels =
        listInventoryTransaction
            .map((e) => e.id ?? '')
            .where((e) => e.isNotEmpty)
            .toList();

    if (idModels.isEmpty) {
      return false;
    }

    try {
      // If we need to insert to pending changes, we need to get the models first
      if (isInsertToPending) {
        for (InventoryTransactionModel model in listInventoryTransaction) {
          if (model.id != null) {
            final pendingChange = PendingChangesModel(
              operation: 'deleted',
              modelName: InventoryTransactionModel.modelName,
              modelId: model.id!,
              data: jsonEncode(model.toJson()),
            );
            await _pendingChangesRepository.insert(pendingChange);
          }
        }
      }

      // Remove from Hive box
      for (String id in idModels) {
        await _hiveBox.delete(id);
      }

      // Delete from database using batch
      String whereIn = idModels.map((_) => '?').join(',');
      batch.delete(tableName, where: '$cId IN ($whereIn)', whereArgs: idModels);

      await batch.commit(noResult: true);
      return true;
    } catch (e) {
      prints('Error deleting bulk inventory transaction: $e');
      return false;
    }
  }

  /// Delete all inventory transaction records
  @override
  Future<bool> deleteAll() async {
    try {
      Database db = await _dbHelper.database;

      // Clear Hive cache
      await _hiveBox.clear();

      // Delete all records from database
      await db.delete(tableName);

      return true;
    } catch (e) {
      prints('Error deleting all inventory transactions: $e');
      return false;
    }
  }

  /// Insert multiple inventory transaction records
  @override
  Future<bool> upsertBulk(
    List<InventoryTransactionModel> listInventoryTransaction, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // First, collect all existing IDs in a single query to check for creates vs updates
      final idsToInsert =
          listInventoryTransaction
              .map((m) => m.id)
              .whereType<String>()
              .toList();

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

      for (InventoryTransactionModel model in listInventoryTransaction) {
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
                modelName: InventoryTransactionModel.modelName,
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
                modelName: InventoryTransactionModel.modelName,
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
      for (var model in listInventoryTransaction) {
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
      prints('Error inserting bulk inventory transaction: $e');
      return false;
    }
  }

  /// Get all inventory transaction records
  @override
  Future<List<InventoryTransactionModel>>
  getListInventoryTransactionModel() async {
    List<InventoryTransactionModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => InventoryTransactionModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list;
    }
    try {
      Database db = await _dbHelper.database;
      List<Map<String, dynamic>> results = await db.query(tableName);

      return results
          .map((map) => InventoryTransactionModel.fromJson(map))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get an inventory transaction record by ID
  @override
  Future<InventoryTransactionModel?> getInventoryTransactionModelById(
    String inventoryTransactionId,
  ) async {
    List<InventoryTransactionModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => InventoryTransactionModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list
          .where((element) => element.id == inventoryTransactionId)
          .firstOrNull;
    }
    try {
      Database db = await _dbHelper.database;
      List<Map<String, dynamic>> results = await db.query(
        tableName,
        where: '$cId = ?',
        whereArgs: [inventoryTransactionId],
      );

      if (results.isNotEmpty) {
        return InventoryTransactionModel.fromJson(results.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Replace all data in the table with new data
  @override
  Future<bool> replaceAllData(
    List<InventoryTransactionModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      Database db = await _dbHelper.database;

      // Delete all existing records
      await db.delete(tableName);

      // Insert new records
      for (final model in newData) {
        model.id ??= IdUtils.generateUUID().toString();
        model.updatedAt = DateTime.now();
        model.createdAt = DateTime.now();
        await db.insert(tableName, model.toJson());

        // Insert to pending changes if required
        if (isInsertToPending) {
          final pendingChange = PendingChangesModel(
            operation: 'created',
            modelName: InventoryTransactionModel.modelName,
            modelId: model.id!,
            data: jsonEncode(model.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _insertPending(
    InventoryTransactionModel model,
    String operation,
  ) async {
    final pending = PendingChangesModel(
      operation: operation,
      modelName: InventoryTransactionModel.modelName,
      modelId: model.id!.toString(),
      data: jsonEncode(model.toJson()),
    );
    await _pendingChangesRepository.insert(pending);
  }

  /// Remove a single item from Hive box by ID
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
}
