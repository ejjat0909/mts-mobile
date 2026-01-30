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
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/repositories/local/local_predefined_order_repository_impl.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/predefined_order_repository.dart';
import 'package:mts/domain/repositories/local/sale_repository.dart';
import 'package:sqflite/sqflite.dart';

final saleBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(SaleModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final saleLocalRepoProvider = Provider<LocalSaleRepository>((ref) {
  return LocalSaleRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(saleBoxProvider),
    predefinedOrderLocalRepository: ref.read(predefinedOrderLocalRepoProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalSaleRepository] that uses local database
class LocalSaleRepositoryImpl implements LocalSaleRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;
  final LocalPredefinedOrderRepository _predefinedOrderLocalRepository;

  /// Database table and column names
  static const String cId = 'id';
  static const String staffId = 'staff_id';
  static const String tableId = 'table_id';
  static const String nameTable = 'table_name';
  static const String predefinedOrderId = 'predefined_order_id';
  static const String orderOptionId = 'order_option_id';
  static const String outletId = 'outlet_id';
  static const String name = 'name';
  static const String runningNumber = 'running_number';
  static const String saleItemCount = 'sale_item_count';
  static const String saleItemIdsToPrint = 'sale_item_ids_to_print';
  static const String saleItemIdsToPrintVoid = 'sale_item_ids_to_print_void';
  static const String remarks = 'remarks';
  static const String totalPrice = 'total_price';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String chargedAt = 'charged_at';
  static const String tableName = 'sales';

  /// Constructor
  LocalSaleRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
    required LocalPredefinedOrderRepository predefinedOrderLocalRepository,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox,
       _predefinedOrderLocalRepository = predefinedOrderLocalRepository;

  /// Create the sale table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $staffId TEXT NULL,
      $runningNumber INTEGER NULL,
      $predefinedOrderId TEXT NULL,
      $tableId TEXT NULL,
      $nameTable TEXT NULL,
      $saleItemCount INTEGER NULL,
      $saleItemIdsToPrint TEXT NULL,
      $saleItemIdsToPrintVoid TEXT NULL,
      $orderOptionId TEXT NULL,
      $outletId TEXT NULL,
      $name TEXT NULL,
      $remarks TEXT NULL,
      $totalPrice FLOAT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL,
      $chargedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new sale
  @override
  Future<int> insert(SaleModel sale, {required bool isInsertToPending}) async {
    sale.updatedAt = DateTime.now();
    sale.createdAt = DateTime.now();
    if (isInsertToPending) {
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'created',
          modelName: SaleModel.modelName,
          modelId: sale.id,
          data: jsonEncode(sale.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }
    }
    int result = await _dbHelper.insertDb(tableName, sale.toJson());
    await _hiveBox.put(sale.id, sale.toJson());
    return result;
  }

  // update using model
  @override
  Future<String> update(
    SaleModel sale, {
    required bool isInsertToPending,
  }) async {
    sale.updatedAt = DateTime.now();
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: SaleModel.modelName,
        modelId: sale.id,
        data: jsonEncode(sale.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }
    int result = await _dbHelper.updateDb(tableName, sale.toJson());
    await _hiveBox.put(sale.id, sale.toJson());

    if (result > 0) {
      return '';
    } else {
      return 'Error updating sale';
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
    await _hiveBox.delete(id);
    if (results.isNotEmpty) {
      final model = SaleModel.fromJson(results.first);

      // Delete the record

      int result = await _dbHelper.deleteDb(tableName, id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: SaleModel.modelName,
          modelId: model.id,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No sale record found with id: $id');
      return 0;
    }
  }

  // get list sale model
  @override
  Future<List<SaleModel>> getListSaleModel() async {
    List<SaleModel> list = [];

    list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => SaleModel.fromJson(json),
    );

    if (list.isNotEmpty) {
      return list;
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    list = List.generate(maps.length, (index) {
      return SaleModel.fromJson(maps[index]);
    });

    return list;
  }

  // insert bulk
  @override
  Future<bool> upsertBulk(
    List<SaleModel> list, {
    required bool isInsertToPending,
  }) async {
    try {
      Database db = await _dbHelper.database;

      // First, collect all existing IDs in a single query to check for creates vs updates
      // This eliminates the race condition: single query instead of per-item checks
      final idsToInsert = list.map((m) => m.id).whereType<String>().toList();

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

      for (SaleModel model in list) {
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
                modelName: SaleModel.modelName,
                modelId: model.id!,
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
                modelName: SaleModel.modelName,
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
      // This ensures we only track changes that actually succeeded
      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      prints('Error inserting bulk sale: $e');
      return false;
    }
  }

  @override
  Future<List<SaleModel>> getListSalesBasedOnStaffIdAndChargedAt() async {
    List<SaleModel> list = [];

    // Try to get from Hive first
    list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => SaleModel.fromJson(json),
    );

    // Filter for chargedAt IS NULL AND predefinedOrderId exists
    list =
        list
            .where(
              (model) =>
                  model.chargedAt == null && model.predefinedOrderId != null,
            )
            .toList();

    if (list.isNotEmpty) {
      // Further filter by checking predefined orders with is_occupied = 1
      try {
        final predefinedOrders =
            await _predefinedOrderLocalRepository.getListPredefinedOrder();

        list =
            list.where((sale) {
              return predefinedOrders.any(
                (po) =>
                    po.id == sale.predefinedOrderId && po.isOccupied == true,
              );
            }).toList();

        if (list.isNotEmpty) {
          // Sort by updatedAt descending
          list.sort(
            (a, b) =>
                (b.updatedAt?.compareTo(a.updatedAt ?? DateTime.now()) ?? 0),
          );
          return list;
        }
      } catch (e) {
        LogUtils.error('Error filtering predefined orders from Hive', e);
        // Continue to fallback
      }
    }

    // Fallback to database query with JOIN to include predefined_orders.is_occupied = 1
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT sales.* 
    FROM ${LocalSaleRepositoryImpl.tableName} AS sales
    INNER JOIN ${LocalPredefinedOrderRepositoryImpl.tableName} AS predefined_orders
    ON sales.$predefinedOrderId = predefined_orders.${LocalPredefinedOrderRepositoryImpl.cId}
    WHERE sales.$chargedAt IS NULL
      AND predefined_orders.${LocalPredefinedOrderRepositoryImpl.isOccupied} = 1
    ORDER BY sales.$updatedAt DESC
  ''');

    return List.generate(maps.length, (index) {
      return SaleModel.fromJson(maps[index]);
    });
  }

  // get latest running number by updated at
  @override
  Future<int> getLatestRunningNumber() async {
    List<SaleModel> list = [];
    list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => SaleModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      // Sort by updatedAt descending
      list.sort(
        (a, b) => (b.updatedAt?.compareTo(a.updatedAt ?? DateTime.now()) ?? 0),
      );
      return list.first.runningNumber ?? 0;
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$runningNumber IS NOT NULL',
      orderBy: '$updatedAt DESC',
      limit: 1,
    );
    return maps.isNotEmpty ? maps[0][runningNumber] : 0;
  }

  // get sale model from sale id
  @override
  Future<SaleModel?> getSaleModelBySaleId(String idsale) async {
    List<SaleModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => SaleModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list.where((element) => element.id == idsale).firstOrNull;
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [idsale],
    );
    return maps.isNotEmpty ? SaleModel.fromJson(maps[0]) : null;
  }

  // get sale model by predefined order id
  @override
  Future<SaleModel?> getSaleModelByPredefinedOrderId(String? poId) async {
    List<SaleModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => SaleModel.fromJson(json),
    );

    Database db = await _dbHelper.database;

    if (poId == null) {
      return null;
    }

    if (list.isNotEmpty) {
      return list
          .where((element) => element.predefinedOrderId == poId)
          .firstOrNull;
    }

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$predefinedOrderId = ?',
      whereArgs: [poId],
    );
    // amik yang last sebab po id boleh recycle
    return maps.isNotEmpty ? SaleModel.fromJson(maps.last) : null;
  }

  //update predefined order id to null by  id
  @override
  Future<int> updateChargedAt(String idSaleModel) async {
    List<SaleModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => SaleModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      SaleModel saleModel = list.firstWhere(
        (element) => element.id == idSaleModel,
        orElse: () => SaleModel(),
      );

      if (saleModel.id != null) {
        saleModel.chargedAt = DateTime.now();
        String upd = await update(saleModel, isInsertToPending: true);
        return upd.isEmpty ? 1 : 0;
      }
    }
    // Get the model before updating it
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [idSaleModel],
    );

    if (results.isNotEmpty) {
      final model = SaleModel.fromJson(results.first);
      SaleModel updatedModel = model.copyWith(chargedAt: DateTime.now());
      // Update the record
      String result = await update(updatedModel, isInsertToPending: true);

      return result.isEmpty ? 1 : 0;
    } else {
      prints('No sale record found with id: $idSaleModel');
      return 0;
    }
  }

  // delete bulk sale model
  @override
  Future<bool> deleteBulk(
    List<SaleModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();
    try {
      for (SaleModel sale in list) {
        // Insert to pending changes if required
        if (isInsertToPending) {
          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: SaleModel.modelName,
            modelId: sale.id,
            data: jsonEncode(sale.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }

        batch.delete(tableName, where: '$cId = ?', whereArgs: [sale.id]);
      }
      await batch.commit(noResult: true);
      return true;
    } catch (e) {
      prints('Error deleting bulk sale: $e');
      return false;
    }
  }

  // delete all
  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await _hiveBox.clear();
      await db.delete(tableName);

      return true;
    } catch (e) {
      prints('Error deleting all sale: $e');
      return false;
    }
  }

  @override
  /// Clears tableId and tableName for records matching the given tableId
  Future<bool> clearTableReferenceByTableId(String targetTableId) async {
    List<SaleModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => SaleModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      list = list.where((element) => element.tableId == targetTableId).toList();
      if (list.isNotEmpty) {
        for (SaleModel sale in list) {
          sale.tableId = null;
          sale.tableName = null;
          await update(sale, isInsertToPending: true);
        }
      }
    }

    try {
      Database db = await _dbHelper.database;

      // Get records with the matching tableId
      List<Map<String, dynamic>> records = await db.query(
        tableName,
        where: '$tableId = ?',
        whereArgs: [targetTableId],
      );

      if (records.isEmpty) return false;

      for (Map<String, dynamic> map in records) {
        SaleModel model = SaleModel.fromJson(map);

        model.tableId = null;
        model.tableName = null;

        // Use existing update function and always insert to pending
        await update(model, isInsertToPending: true);
      }

      return true;
    } catch (e) {
      prints('Error clearing tableId and tableName: $e');
      return false;
    }
  }

  @override
  Future<bool> unChargeSale(SaleModel saleModel) async {
    saleModel.chargedAt = null;
    try {
      await update(saleModel, isInsertToPending: true);
      return true;
    } catch (e) {
      prints('Error uncharging sale: $e');
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<SaleModel> newData, {
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

  @override
  Future<int> deleteSaleWhereStaffIdNull() async {
    List<SaleModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => SaleModel.fromJson(json),
    );

    for (SaleModel sale in list) {
      // use for debug
      await delete(sale.id!, isInsertToPending: false);
    }
    Database db = await _dbHelper.database;
    return await db.delete(tableName, where: '$staffId IS NULL');
  }

  @override
  Future<List<SaleModel>> getListSalesWhereStaffIdNull() async {
    List<SaleModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => SaleModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list.where((element) => element.staffId == null).toList();
    }
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> records = await db.query(
      tableName,
      where: '$staffId IS NULL',
    );

    return List.generate(records.length, (index) {
      return SaleModel.fromJson(records[index]);
    });
  }

  @override
  Future<List<SaleModel>> getSavedOrdersByPredefinedOrderIds(
    List<String> predefinedOrderIds,
  ) async {
    if (predefinedOrderIds.isEmpty) {
      return [];
    }

    List<SaleModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => SaleModel.fromJson(json),
    );

    if (list.isNotEmpty) {
      list =
          list
              .where(
                (model) =>
                    predefinedOrderIds.contains(model.predefinedOrderId) &&
                    model.chargedAt == null &&
                    model.tableId == null,
              )
              .toList();

      list.sort(
        (a, b) => (b.updatedAt?.compareTo(a.updatedAt ?? DateTime.now()) ?? 0),
      );

      return list;
    }

    Database db = await _dbHelper.database;
    final placeholders = List.filled(predefinedOrderIds.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where:
          '$predefinedOrderId IN ($placeholders) AND $chargedAt IS NULL AND $tableId IS NULL',
      whereArgs: predefinedOrderIds,
      orderBy: '$updatedAt DESC',
    );

    return List.generate(maps.length, (index) {
      return SaleModel.fromJson(maps[index]);
    });
  }
}
