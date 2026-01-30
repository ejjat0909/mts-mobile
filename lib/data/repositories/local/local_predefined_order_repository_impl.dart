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
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/predefined_order_repository.dart';
import 'package:sqflite/sqflite.dart';

final predefinedOrderBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(PredefinedOrderModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final predefinedOrderLocalRepoProvider =
    Provider<LocalPredefinedOrderRepository>((ref) {
      return LocalPredefinedOrderRepositoryImpl(
        dbHelper: ref.read(databaseHelpersProvider),
        pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
        hiveBox: ref.read(predefinedOrderBoxProvider),
      );
    });

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalPredefinedOrderRepository] that uses local database
class LocalPredefinedOrderRepositoryImpl
    implements LocalPredefinedOrderRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String cId = 'id';
  static const String outletId = 'outlet_id';
  static const String name = 'name';
  static const String tableId = 'table_id';
  static const String nameTable = 'table_name';
  static const String isOccupied = 'is_occupied';
  static const String isCustom = 'is_custom';
  static const String remarks = 'remarks';
  static const String orderColumn = 'order_column';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String deletedAt = 'deleted_at';
  static const String tableName = 'predefined_orders';

  /// Constructor
  LocalPredefinedOrderRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the predefined order table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $outletId TEXT NULL,
      $name TEXT NULL,
      $tableId TEXT NULL,
      $nameTable TEXT NULL,
      $isOccupied INTEGER DEFAULT 0,
      $isCustom INTEGER DEFAULT 0,
      $remarks TEXT NULL,
      $orderColumn INTEGER DEFAULT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL,
      $deletedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new predefined order
  @override
  Future<int> insert(
    PredefinedOrderModel predefinedOrderModel, {
    required bool isInsertToPending,
  }) async {
    predefinedOrderModel.id ??= IdUtils.generateUUID().toString();
    predefinedOrderModel.updatedAt = DateTime.now();
    predefinedOrderModel.createdAt = DateTime.now();
    int result = await _dbHelper.insertDb(
      tableName,
      predefinedOrderModel.toJson(),
    );
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'created',
        modelName: PredefinedOrderModel.modelName,
        modelId: predefinedOrderModel.id!,
        data: jsonEncode(predefinedOrderModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }
    await _hiveBox.put(predefinedOrderModel.id, predefinedOrderModel.toJson());

    return result;
  }

  // update
  @override
  Future<int> update(
    PredefinedOrderModel predefinedOrderModel, {
    required bool isInsertToPending,
  }) async {
    predefinedOrderModel.updatedAt = DateTime.now();
    int result = await _dbHelper.updateDb(
      tableName,
      predefinedOrderModel.toJson(),
    );
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: PredefinedOrderModel.modelName,
        modelId: predefinedOrderModel.id!,
        data: jsonEncode(predefinedOrderModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }
    // Update the cache (Hive box)

    await _hiveBox.put(predefinedOrderModel.id, predefinedOrderModel.toJson());

    return result;
  }

  // delete
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
      final model = PredefinedOrderModel.fromJson(results.first);

      // Delete the record
      await _hiveBox.delete(id);
      int result = await _dbHelper.deleteDb(tableName, id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: PredefinedOrderModel.modelName,
          modelId: model.id,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No predefined order record found with id: $id');
      return 0;
    }
  }

  @override
  Future<bool> makeIsOccupied(String idModel) async {
    List<PredefinedOrderModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: PredefinedOrderModel.fromJson,
    );
    if (list.isNotEmpty) {
      final predefinedOrder = list.firstWhere(
        (po) => po.id == idModel && po.isOccupied == false,
        orElse: () => PredefinedOrderModel(), // Default value if not found
      );
      if (predefinedOrder.id != null) {
        // Update the record
        int result = await update(
          predefinedOrder.copyWith(isOccupied: true),
          isInsertToPending: true,
        ); // Always sync occupation changes
        return result > 0;
      }
    }
    try {
      Database db = await _dbHelper.database;

      // Get the model before updating it
      List<Map<String, dynamic>> results = await db.query(
        tableName,
        where: '$cId = ?',
        whereArgs: [idModel],
      );

      if (results.isNotEmpty) {
        final model = PredefinedOrderModel.fromJson(results.first);
        // Update the record
        model.isOccupied = true;
        int result = await update(
          model,
          isInsertToPending: true,
        ); // Always sync occupation changes

        if (result > 0) {
          return true;
        }
      }
      prints('Error during making occupied: $idModel');
      return false;
    } catch (e) {
      prints('Error during making occupied: $e');
      return false; // Return false if an error occurs
    }
  }

  @override
  Future<bool> unOccupied(String idModel) async {
    List<PredefinedOrderModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: PredefinedOrderModel.fromJson,
    );
    if (list.isNotEmpty) {
      final predefinedOrder = list.firstWhere(
        (po) => po.id == idModel,
        orElse: () => PredefinedOrderModel(), // Default value if not found
      );
      if (predefinedOrder.id != null) {
        // Update the record
        int result = await update(
          predefinedOrder.copyWith(isOccupied: false),
          isInsertToPending: true,
        ); // Always sync occupation changes
        return result > 0;
      }
    }
    try {
      Database db = await _dbHelper.database;

      // Get the model before updating it
      List<Map<String, dynamic>> results = await db.query(
        tableName,
        where: '$cId = ?',
        whereArgs: [idModel],
      );

      if (results.isNotEmpty) {
        final model = PredefinedOrderModel.fromJson(results.first);
        model.isOccupied = false;
        // Update the record
        int result = await update(
          model,
          isInsertToPending: true,
        ); // Always sync occupation changes

        if (result > 0) {
          return true;
        }
      }

      return false;
    } catch (e) {
      prints('Error restoring unoccupied record: $e');
      return false; // Return false if an error occurs
    }
  }

  // get latest column order number
  @override
  Future<int> getLatestColumnOrder() async {
    List<PredefinedOrderModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: PredefinedOrderModel.fromJson,
    );
    // Filter out deleted records to match database query behavior

    if (list.isNotEmpty) {
      final maxOrderNumber =
          list
              .reduce(
                (previous, next) =>
                    previous.orderColumn! > next.orderColumn! ? previous : next,
              )
              .orderColumn!;
      return maxOrderNumber + 1;
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$deletedAt IS NULL',
      orderBy: '$orderColumn DESC',
      limit: 1,
    );
    return maps.isNotEmpty ? maps[0][orderColumn] ?? 0 : 0;
  }

  // get list predefined order
  @override
  Future<List<PredefinedOrderModel>>
  getListPredefinedOrderWhereOccupied0() async {
    List<PredefinedOrderModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: PredefinedOrderModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list
          .where((po) => po.isOccupied == false && po.isCustom == false)
          .toList();
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$isOccupied = 0 AND $isCustom = 0',
      orderBy: '$orderColumn ASC',
    );
    return List.generate(maps.length, (index) {
      return PredefinedOrderModel.fromJson(maps[index]);
    });
  }

  // get list predefined order by ids
  @override
  Future<List<PredefinedOrderModel>> getPredefinedOrderByIds(
    List<String?> listId,
  ) async {
    // Filter out null values
    final List<String> filteredIds =
        listId.where((id) => id != null).cast<String>().toList();

    if (filteredIds.isEmpty) {
      // If all IDs are null or the list is empty, return an empty list
      return [];
    }

    List<PredefinedOrderModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: PredefinedOrderModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list.where((po) => filteredIds.contains(po.id)).toList();
    }

    Database db = await _dbHelper.database;
    final String ids = filteredIds.map((id) => "'$id'").join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId IN ($ids)',
    );

    return maps.map((map) => PredefinedOrderModel.fromJson(map)).toList();
  }

  //get all PO
  @override
  Future<List<PredefinedOrderModel>> getListPredefinedOrder() async {
    List<PredefinedOrderModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: PredefinedOrderModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list..sort((a, b) => a.updatedAt!.compareTo(b.updatedAt!));
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: '$updatedAt DESC',
    );
    return List.generate(maps.length, (index) {
      return PredefinedOrderModel.fromJson(maps[index]);
    });
  }

  @override
  Future<List<PredefinedOrderModel>>
  getListPredefinedOrderWhereOccupied1() async {
    List<PredefinedOrderModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: PredefinedOrderModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list.where((po) => po.isOccupied == true).toList()
        ..sort((a, b) => (a.orderColumn ?? 0).compareTo(b.orderColumn ?? 0));
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$isOccupied = 1',
      orderBy: '$orderColumn ASC',
    );
    return List.generate(maps.length, (index) {
      return PredefinedOrderModel.fromJson(maps[index]);
    });
  }

  // insert bulk
  @override
  Future<bool> upsertBulk(
    List<PredefinedOrderModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // First, collect all existing IDs in a single query
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
      final pendingChanges = <PendingChangesModel>[];

      // Use a single batch for all operations (atomic)
      final batch = db.batch();

      for (final model in list) {
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
                modelName: PredefinedOrderModel.modelName,
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
                modelName: PredefinedOrderModel.modelName,
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
      prints('Error inserting bulk predefined order: $e');
      return false;
    }
  }

  // get predefined order by id
  @override
  Future<PredefinedOrderModel?> getPredefinedOrderById(
    String? idPredefined,
  ) async {
    List<PredefinedOrderModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: PredefinedOrderModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list.where((po) => po.id == idPredefined).firstOrNull;
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [idPredefined],
    );
    if (maps.isNotEmpty) {
      return PredefinedOrderModel.fromJson(maps.first);
    } else {
      return null;
    }
  }

  @override
  Future<List<PredefinedOrderModel>>
  getPredefinedOrderThatHaveNoTableAndOccupied() async {
    List<PredefinedOrderModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: PredefinedOrderModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list
          .where((po) => po.tableId == null && po.isOccupied == true)
          .toList();
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$tableId IS NULL AND $isOccupied = 1',
    );
    return maps.map((map) => PredefinedOrderModel.fromJson(map)).toList();
  }

  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await Future.wait([_hiveBox.clear(), db.delete(tableName)]);

      return true;
    } catch (e) {
      prints('Error deleting all predefined order: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteBulk(
    List<PredefinedOrderModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    try {
      // If we need to insert to pending changes, we need to get the models first
      if (isInsertToPending) {
        for (PredefinedOrderModel model in list) {
          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: PredefinedOrderModel.modelName,
            modelId: model.id,
            data: jsonEncode(model.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }

      for (PredefinedOrderModel model in list) {
        batch.delete(tableName, where: '$cId = ?', whereArgs: [model.id]);
      }
      await _hiveBox.clear();
      await batch.commit(noResult: true);
      return true;
    } catch (e) {
      prints('Error deleting bulk predefined order: $e');
      return false;
    }
  }

  @override
  /// Clears tableId and tableName for records matching the given tableId
  Future<bool> clearTableReferenceByTableId(String targetTableId) async {
    List<PredefinedOrderModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: PredefinedOrderModel.fromJson,
    );
    if (list.isNotEmpty) {
      final predefinedOrdersToUpdate =
          list.where((po) => po.tableId == targetTableId).toList();
      await Future.wait(
        predefinedOrdersToUpdate.map((po) {
          po.tableId = null;
          po.tableName = null;
          return update(po, isInsertToPending: true);
        }),
      );
      return true;
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
        PredefinedOrderModel model = PredefinedOrderModel.fromJson(map);

        model.tableId = null;
        model.tableName = null;

        await update(model, isInsertToPending: true);
      }

      return true;
    } catch (e) {
      prints('Error clearing tableId and tableName: $e');
      return false;
    }
  }

  @override
  Future<bool> unOccupiedAllNotCustom() async {
    List<PredefinedOrderModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: PredefinedOrderModel.fromJson,
    );
    if (list.isNotEmpty) {
      final predefinedOrdersToUpdate =
          list.where((po) => po.isCustom == false).toList();
      await Future.wait(
        predefinedOrdersToUpdate.map((po) {
          return update(
            po.copyWith(isOccupied: false),
            isInsertToPending: true,
          );
        }),
      );
      return true;
    }
    try {
      Database db = await _dbHelper.database;

      // Get the model before updating it
      List<Map<String, dynamic>> results = await db.query(
        tableName,
        where: '$isCustom = ?',
        whereArgs: [0],
      );

      for (Map<String, dynamic> map in results) {
        PredefinedOrderModel model = PredefinedOrderModel.fromJson(map);
        model.isOccupied = false;
        // Update the record
        await update(
          model,
          isInsertToPending: true,
        ); // Always sync occupation changes
      }

      return false;
    } catch (e) {
      prints('Error restoring unoccupied record: $e');
      return false; // Return false if an error occurs
    }
  }

  @override
  Future<List<PredefinedOrderModel>> getListPoByTableIds(
    List<String> tableIds,
  ) async {
    List<PredefinedOrderModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: PredefinedOrderModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list.where((po) => tableIds.contains(po.tableId)).toList();
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where:
          '$tableId IN (${List.generate(tableIds.length, (index) => '?').join(',')})',
      whereArgs: tableIds,
    );
    return maps.map((map) => PredefinedOrderModel.fromJson(map)).toList();
  }

  @override
  Future<List<PredefinedOrderModel>> getCustomPoThatHaveTable() async {
    List<PredefinedOrderModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: PredefinedOrderModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list
          .where((po) => po.isCustom == true && po.tableId != null)
          .toList();
    }
    Database db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$isCustom = ? AND $tableId IS NOT NULL',
      whereArgs: [1],
    );
    return maps.map((map) => PredefinedOrderModel.fromJson(map)).toList();
  }

  @override
  Future<bool> deleteAllCustomPO() async {
    try {
      List<PredefinedOrderModel> list = HiveSyncHelper.getListFromBox(
        box: _hiveBox,
        fromJson: PredefinedOrderModel.fromJson,
      );
      if (list.isNotEmpty) {
        final customPOs = list.where((po) => po.isCustom == true).toList();
        await Future.wait(
          customPOs.map((po) => delete(po.id!, isInsertToPending: true)),
        );
        return true;
      }

      Database db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: '$isCustom = ?',
        whereArgs: [1],
      );

      await Future.wait(
        maps.map((map) {
          final model = PredefinedOrderModel.fromJson(map);
          return delete(model.id!, isInsertToPending: true);
        }),
      );
      return true;
    } catch (e) {
      prints('Error deleting all custom predefined orders: $e');
      return false;
    }
  }

  @override
  Future<int> deleteWhereIdIsNull() async {
    // use it delete pending changes
    try {
      Database db = await _dbHelper.database;
      int result = await db.delete(tableName, where: '$cId IS NULL');
      await _hiveBox.delete('$cId IS NULL');
      prints('Deleted $result predefined order records where id is null');
      return result;
    } catch (e) {
      prints('Error deleting predefined orders where id is null: $e');
      return 0;
    }
  }

  // // get predefined order by saleid
  // Future<PredefinedOrderModel?> getPredefinedOrderBySaleId(
  //     String? idPredefined) async {
  //   Database db = await _dbHelper.database;
  //   final List<Map<String, dynamic>> maps = await db.query(
  //     tableName,
  //     where: '$sa = ?',
  //     whereArgs: [idPredefined],
  //   );
  //   if (maps.isNotEmpty) {
  //     return PredefinedOrderModel.fromJson(maps.first);
  //   } else {
  //     return null;
  //   }
  // }

  /// Refresh bulk Hive box: replaces all items with provided list, deletes items not in the new list

  @override
  Future<bool> replaceAllData(
    List<PredefinedOrderModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      await LogUtils.debug('Replacing all predefined order data');

      // Clear existing data
      await deleteAll();

      // Insert new data
      if (newData.isNotEmpty) {
        final result = await upsertBulk(
          newData,
          isInsertToPending: isInsertToPending,
        );
        return result;
      }

      return true;
    } catch (e) {
      await LogUtils.error('Error replacing all predefined order data', e);
      return false;
    }
  }
}
