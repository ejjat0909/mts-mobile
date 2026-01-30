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
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/order_option_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

/// ================================
/// Hive Box Provider
/// ================================
final orderOptionBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(OrderOptionModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final orderOptionLocalRepoProvider = Provider<LocalOrderOptionRepository>((
  ref,
) {
  return LocalOrderOptionRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    hiveBox: ref.read(orderOptionBoxProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalOrderOptionRepository] that uses local database
class LocalOrderOptionRepositoryImpl implements LocalOrderOptionRepository {
  final IDatabaseHelpers _dbHelper;
  final Box<Map> _hiveBox;
  final LocalPendingChangesRepository _pendingChangesRepository;

  /// Database table and column names
  static const String cId = 'id';
  static const String name = 'name';
  static const String orderColumn = 'order_column';
  static const String outletId = 'outlet_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String tableName = 'order_options';

  /// Constructor
  LocalOrderOptionRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required Box<Map> hiveBox,
    required LocalPendingChangesRepository pendingChangesRepository,
  }) : _dbHelper = dbHelper,
       _hiveBox = hiveBox,
       _pendingChangesRepository = pendingChangesRepository;

  /// Create the order option table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $name TEXT NULL,
      $orderColumn INTEGER DEFAULT NULL,
      $outletId TEXT DEFAULT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new order option
  @override
  Future<int> insert(
    OrderOptionModel orderOptionModel, {
    required bool isInsertToPending,
  }) async {
    orderOptionModel.id ??= IdUtils.generateUUID().toString();
    orderOptionModel.updatedAt = DateTime.now();
    orderOptionModel.createdAt = DateTime.now();

    // Write to SQLite database
    int result = await _dbHelper.insertDb(tableName, orderOptionModel.toJson());

    // Sync to Hive
    if (result > 0) {
      await _hiveBox.put(orderOptionModel.id!, orderOptionModel.toJson());
    }

    // Insert to pending changes if required
    if (isInsertToPending && result > 0) {
      final pendingChange = PendingChangesModel(
        operation: 'created',
        modelName: OrderOptionModel.modelName,
        modelId: orderOptionModel.id,
        data: jsonEncode(orderOptionModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    return result;
  }

  /// Update an existing order option
  @override
  Future<int> update(
    OrderOptionModel orderOptionModel, {
    required bool isInsertToPending,
  }) async {
    orderOptionModel.updatedAt = DateTime.now();

    // Write to SQLite database
    int result = await _dbHelper.updateDb(tableName, orderOptionModel.toJson());

    // Sync to Hive
    if (result > 0) {
      await _hiveBox.put(orderOptionModel.id!, orderOptionModel.toJson());
    }

    // Insert to pending changes if required
    if (isInsertToPending && result > 0) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: OrderOptionModel.modelName,
        modelId: orderOptionModel.id,
        data: jsonEncode(orderOptionModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    return result;
  }

  /// Delete an order option by ID
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
      final model = OrderOptionModel.fromJson(results.first);

      // Delete the record from SQLite
      int result = await _dbHelper.deleteDb(tableName, id);

      // Delete from Hive
      if (result > 0) {
        await _hiveBox.delete(id);
      }

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: OrderOptionModel.modelName,
          modelId: model.id,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No order option record found with id: $id');
      return 0;
    }
  }

  // get list order option
  @override
  Future<List<OrderOptionModel>> getListOrderOptionModel() async {
    List<OrderOptionModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: OrderOptionModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list;
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return OrderOptionModel.fromJson(maps[index]);
    });
  }

  /// Insert multiple order options
  @override
  Future<bool> upsertBulk(
    List<OrderOptionModel> orderOptionModels, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // First, collect all existing IDs in a single query to check for creates vs updates
      // This eliminates the race condition: single query instead of per-item checks
      final idsToInsert =
          orderOptionModels.map((m) => m.id).whereType<String>().toList();

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

      for (OrderOptionModel model in orderOptionModels) {
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
                modelName: OrderOptionModel.modelName,
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
                modelName: OrderOptionModel.modelName,
                modelId: model.id!,
                data: jsonEncode(modelJson),
              ),
            );
          }
        }
      }

      // Commit batch atomically
      await batch.commit(noResult: true);

      // Sync to Hive
      final hiveDataMap = <dynamic, Map<dynamic, dynamic>>{};
      for (var model in orderOptionModels) {
        if (model.id != null) {
          hiveDataMap[model.id!] = model.toJson();
        }
      }
      if (hiveDataMap.isNotEmpty) {
        await _hiveBox.putAll(hiveDataMap);
      }

      // Track pending changes AFTER successful batch commit
      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      prints('Error inserting bulk order option: $e');
      return false;
    }
  }

  // get order option by id
  @override
  Future<OrderOptionModel?> getOrderOptionModelById(String idOO) async {
    List<OrderOptionModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: OrderOptionModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list.where((element) => element.id == idOO).firstOrNull;
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [idOO],
    );
    return maps.isNotEmpty ? OrderOptionModel.fromJson(maps[0]) : null;
  }

  /// Delete multiple order options
  @override
  Future<bool> deleteBulk(
    List<OrderOptionModel> orderOptionModels, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    List<String> ids = orderOptionModels.map((e) => e.id!).toList();

    if (ids.isEmpty) {
      return false;
    }

    // If we need to insert to pending changes, we need to get the models first
    if (isInsertToPending) {
      for (OrderOptionModel orderOption in orderOptionModels) {
        List<Map<String, dynamic>> results = await db.query(
          tableName,
          where: '$cId = ?',
          whereArgs: [orderOption.id],
        );

        if (results.isNotEmpty) {
          final model = OrderOptionModel.fromJson(results.first);

          // Insert to pending changes
          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: OrderOptionModel.modelName,
            modelId: model.id,
            data: jsonEncode(model.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }
    }

    String whereIn = ids.map((_) => '?').join(',');
    try {
      await db.delete(tableName, where: '$cId IN ($whereIn)', whereArgs: ids);

      // Delete from Hive
      await _hiveBox.deleteAll(ids);

      return true;
    } catch (e) {
      prints('Error deleting bulk order options: $e');
      return false;
    }
  }

  // delete all
  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await db.delete(tableName);

      // Clear Hive
      await _hiveBox.clear();

      return true;
    } catch (e) {
      prints('Error deleting all order options: $e');
      return false;
    }
  }

  /// Get order option name by ID
  @override
  Future<String?> getOrderOptionNameById(String id) async {
    List<OrderOptionModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: OrderOptionModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list.where((element) => element.id == id).firstOrNull?.name;
    }
    Database db = await _dbHelper.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: '$cId = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return maps.first[name] as String?;
      }
      return null;
    } catch (e) {
      prints('Error getting order option name by id: $e');
      return null;
    }
  }

  /// Replace all data in the table with new data
  @override
  Future<bool> replaceAllData(
    List<OrderOptionModel> newData, {
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

      return true;
    } catch (e) {
      prints('Error replacing all order option data: $e');
      return false;
    }
  }
}
