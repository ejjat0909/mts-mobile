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
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/table_repository.dart';
import 'package:sqflite/sqflite.dart';

final tableBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(TableModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final tableLocalRepoProvider = Provider<LocalTableRepository>((ref) {
  return LocalTableRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(tableBoxProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalTableRepository] that uses local database
class LocalTableRepositoryImpl implements LocalTableRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String tableName = 'tables';
  static const String cId = 'id';
  static const String tableSectionId = 'table_section_id';
  static const String left = 'left';
  static const String top = 'top';
  static const String name = 'name';
  static const String type = 'type';
  static const String status = 'status';
  static const String staffId = 'staff_id';
  static const String customerId = 'customer_id';
  static const String saleId = 'sale_id';
  static const String predefinedOrderId = 'predefined_order_id';
  static const String outletId = 'outlet_id';
  static const String seats = 'seats';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  /// Constructor
  LocalTableRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $tableSectionId TEXT NULL,
      $left FLOAT NULL,
      $top FLOAT NULL,
      $name TEXT NULL,
      $type TEXT NULL,
      $status INTEGER NULL,
      $staffId TEXT NULL,
      $customerId TEXT NULL,
      $saleId TEXT NULL,
      $predefinedOrderId TEXT NULL,
      $outletId TEXT NULL,
      $seats INTEGER NULL,
      $createdAt DATETIME DEFAULT NULL,
      $updatedAt DATETIME DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new table
  @override
  Future<int> insert(
    TableModel tableModel, {
    required bool isInsertToPending,
  }) async {
    tableModel.id ??= IdUtils.generateUUID();
    tableModel.createdAt = DateTime.now();
    tableModel.updatedAt = DateTime.now();

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'created',
        modelName: TableModel.modelName,
        modelId: tableModel.id,
        data: jsonEncode(tableModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }
    int result = await _dbHelper.insertDb(tableName, tableModel.toJson());
    await _hiveBox.put(tableModel.id, tableModel.toJson());
    return result;
  }

  @override
  Future<int> update(
    TableModel tableModel, {
    required bool isInsertToPending,
  }) async {
    tableModel.updatedAt = DateTime.now();

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: TableModel.modelName,
        modelId: tableModel.id,
        data: jsonEncode(tableModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }
    int result = await _dbHelper.updateDb(tableName, tableModel.toJson());
    await _hiveBox.put(tableModel.id, tableModel.toJson());
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
      final model = TableModel.fromJson(results.first);

      // Delete the record
      await _hiveBox.delete(id);
      int result = await _dbHelper.deleteDb(tableName, id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: TableModel.modelName,
          modelId: model.id,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No table record found with id: $id');
      return 0;
    }
  }

  // get list tables
  @override
  Future<List<TableModel>> getTables() async {
    // Try Hive cache first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: TableModel.fromJson,
    );
    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return TableModel.fromJson(maps[index]);
    });
  }

  // get table by id
  @override
  Future<TableModel?> getTableById(String idTable) async {
    // Try Hive cache first
    final cachedItem = HiveSyncHelper.getById(
      box: _hiveBox,
      id: idTable,
      fromJson: TableModel.fromJson,
    );
    if (cachedItem != null) {
      return cachedItem;
    }

    // Fallback to SQLite
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [idTable],
    );
    if (results.isNotEmpty) {
      return TableModel.fromJson(results.first);
    } else {
      return null;
    }
  }

  @override
  Future<bool> upsertBulk(
    List<TableModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
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

      for (TableModel model in list) {
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
                modelName: TableModel.modelName,
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
                modelName: TableModel.modelName,
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
      prints('Error inserting bulk tables: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await db.delete(tableName);
      await _hiveBox.clear();

      return true;
    } catch (e) {
      prints('Error deleting all tables: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteBulk(
    List<TableModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();
    try {
      for (TableModel tm in list) {
        batch.delete(tableName, where: '$cId = ?', whereArgs: [tm.id]);

        // Insert to pending changes if required
        if (isInsertToPending) {
          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: TableModel.modelName,
            modelId: tm.id,
            data: jsonEncode(tm.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }
      await batch.commit(noResult: true);

      // Sync deletions to Hive cache
      await _hiveBox.deleteAll(
        list.where((m) => m.id != null).map((m) => m.id!).toList(),
      );

      return true;
    } catch (e) {
      prints('Error deleting bulk tables: $e');
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<TableModel> newData, {
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
