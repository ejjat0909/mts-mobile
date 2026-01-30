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
import 'package:mts/data/models/table_section/table_section_model.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/table_section_repository.dart';
import 'package:sqflite/sqflite.dart';

final tableSectionBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(TableSectionModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final tableSectionLocalRepoProvider = Provider<LocalTableSectionRepository>((
  ref,
) {
  return LocalTableSectionRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(tableSectionBoxProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalTableSectionRepository] that uses local database
class LocalTableSectionRepositoryImpl implements LocalTableSectionRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String tableName = 'table_sections';
  static const String cId = 'id';
  static const String name = 'name';
  static const String outletId = 'outlet_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  /// Constructor
  LocalTableSectionRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the table section table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $name TEXT NULL,
      $outletId TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new table section
  @override
  Future<int> insert(
    TableSectionModel sectionModel, {
    required bool isInsertToPending,
  }) async {
    sectionModel.id ??= IdUtils.generateUUID();
    sectionModel.createdAt = DateTime.now();
    sectionModel.updatedAt = DateTime.now();

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'created',
        modelName: TableSectionModel.modelName,
        modelId: sectionModel.id,
        data: jsonEncode(sectionModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }
    int result = await _dbHelper.insertDb(tableName, sectionModel.toJson());
    await _hiveBox.put(sectionModel.id, sectionModel.toJson());
    return result;
  }

  @override
  Future<int> update(
    TableSectionModel sectionModel, {
    required bool isInsertToPending,
  }) async {
    sectionModel.updatedAt = DateTime.now();

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: TableSectionModel.modelName,
        modelId: sectionModel.id,
        data: jsonEncode(sectionModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }
    int result = await _dbHelper.updateDb(tableName, sectionModel.toJson());
    await _hiveBox.put(sectionModel.id, sectionModel.toJson());

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
      final model = TableSectionModel.fromJson(results.first);

      // Delete the record
      int result = await _dbHelper.deleteDb(tableName, id);
      await _hiveBox.delete(id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: TableSectionModel.modelName,
          modelId: model.id,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No table section record found with id: $id');
      return 0;
    }
  }

  // get list tables
  @override
  Future<List<TableSectionModel>> getTableSections() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return TableSectionModel.fromJson(maps[index]);
    });
  }

  // get table by id
  @override
  Future<TableSectionModel?> getTableSectionById(String idTable) async {
    // Try Hive cache first
    final cachedItem = HiveSyncHelper.getById(
      box: _hiveBox,
      id: idTable,
      fromJson: TableSectionModel.fromJson,
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
      return TableSectionModel.fromJson(results.first);
    } else {
      return null;
    }
  }

  @override
  Future<bool> upsertBulk(
    List<TableSectionModel> list, {
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

      for (TableSectionModel model in list) {
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
                modelName: TableSectionModel.modelName,
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
                modelName: TableSectionModel.modelName,
                modelId: model.id!,
                data: jsonEncode(modelJson),
              ),
            );
          }
        }
      }

      // Commit batch atomically
      await batch.commit(noResult: true);

      // Sync to Hive cache after successful SQLite commit
      final hiveDataMap = <dynamic, Map<dynamic, dynamic>>{};
      for (final model in list) {
        if (model.id != null) {
          hiveDataMap[model.id!] = model.toJson();
        }
      }
      if (hiveDataMap.isNotEmpty) {
        await _hiveBox.putAll(hiveDataMap);
      }

      // Track pending changes AFTER successful batch commit
      // This ensures we only track changes that actually succeeded
      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      prints('Error inserting bulk table sections: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteBulk(
    List<TableSectionModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();
    try {
      for (TableSectionModel model in list) {
        batch.delete(tableName, where: '$cId = ?', whereArgs: [model.id]);
        _hiveBox.delete(model.id);
        // Insert to pending changes if required
        if (isInsertToPending) {
          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: TableSectionModel.modelName,
            modelId: model.id,
            data: jsonEncode(model.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }
      await batch.commit(noResult: true);
      return true;
    } catch (e) {
      prints('Error deleting bulk table sections: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    int result = await db.delete(tableName);
    return result > 0;
  }

  @override
  Future<bool> replaceAllData(
    List<TableSectionModel> newData, {
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
