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
import 'package:mts/data/models/supplier/supplier_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/supplier_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

final supplierBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(SupplierModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final supplierLocalRepoProvider = Provider<LocalSupplierRepository>((ref) {
  return LocalSupplierRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(supplierBoxProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalSupplierRepository] that uses local database
class LocalSupplierRepositoryImpl implements LocalSupplierRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String cId = 'id';
  static const String cName = 'name';
  static const String cEmail = 'email';
  static const String cPhoneNo = 'phone_no';
  static const String cDescription = 'description';
  static const String cCreatedAt = 'created_at';
  static const String cUpdatedAt = 'updated_at';
  static const String tableName = 'suppliers';

  /// Constructor
  LocalSupplierRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the supplier table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $cName TEXT NULL,
      $cEmail TEXT NULL,
      $cPhoneNo TEXT NULL,
      $cDescription TEXT NULL,
      $cCreatedAt TIMESTAMP DEFAULT NULL,
      $cUpdatedAt TIMESTAMP DEFAULT NULL
    ''';

    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new supplier
  @override
  Future<int> insert(
    SupplierModel supplierModel, {
    required bool isInsertToPending,
  }) async {
    supplierModel.id ??= IdUtils.generateUUID().toString();
    supplierModel.updatedAt = DateTime.now();
    supplierModel.createdAt = DateTime.now();
    int result = await _dbHelper.insertDb(tableName, supplierModel.toJson());

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'created',
        modelName: SupplierModel.modelName,
        modelId: supplierModel.id!,
        data: jsonEncode(supplierModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
      await _hiveBox.put(supplierModel.id, supplierModel.toJson());
    }

    return result;
  }

  @override
  Future<int> update(
    SupplierModel supplierModel, {
    required bool isInsertToPending,
  }) async {
    supplierModel.updatedAt = DateTime.now();
    int result = await _dbHelper.updateDb(tableName, supplierModel.toJson());

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: SupplierModel.modelName,
        modelId: supplierModel.id!,
        data: jsonEncode(supplierModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
      await _hiveBox.put(supplierModel.id, supplierModel.toJson());
    }

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
      final model = SupplierModel.fromJson(results.first);

      // Delete the record
      int result = await _dbHelper.deleteDb(tableName, id);
      await _hiveBox.delete(id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: SupplierModel.modelName,
          modelId: model.id!,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No supplier record found with id: $id');
      return 0;
    }
  }

  @override
  Future<List<SupplierModel>> getListSupplierModel() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return SupplierModel.fromJson(maps[index]);
    });
  }

  @override
  Future<SupplierModel?> getSupplierModelById(String supplierId) async {
    Database db = await _dbHelper.database;
    final hiveModel = HiveSyncHelper.getById(
      box: _hiveBox,
      id: supplierId,
      fromJson: (json) => SupplierModel.fromJson(json),
    );
    if (hiveModel != null) {
      return hiveModel;
    }

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [supplierId],
    );

    if (maps.isNotEmpty) {
      return SupplierModel.fromJson(maps[0]);
    } else {
      return null; // Return null if no item is found
    }
  }

  @override
  Future<bool> upsertBulk(
    List<SupplierModel> listSupplier, {
    required bool isInsertToPending,
  }) async {
    try {
      // First, collect all existing IDs in a single query to check for creates vs updates
      // This eliminates the race condition: single query instead of per-item checks
      Database db = await _dbHelper.database;
      final idsToInsert =
          listSupplier.map((m) => m.id).whereType<String>().toList();

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

      for (SupplierModel model in listSupplier) {
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
                modelName: SupplierModel.modelName,
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
                modelName: SupplierModel.modelName,
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
          listSupplier
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
      prints('Error inserting bulk supplier: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteBulk(
    List<SupplierModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    try {
      for (SupplierModel sm in list) {
        batch.delete(tableName, where: '$cId = ?', whereArgs: [sm.id]);

        // Insert to pending changes if required
        if (isInsertToPending) {
          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: SupplierModel.modelName,
            modelId: sm.id!,
            data: jsonEncode(sm.toJson()),
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
      prints('Error deleting bulk supplier: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteAll() async {
    try {
      Database db = await _dbHelper.database;
      await db.delete(tableName);
      // Also clear Hive box
      await _hiveBox.clear();
      return true;
    } catch (e) {
      prints('Error deleting all suppliers: $e');
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<SupplierModel> newData, {
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
      prints('Error replacing all data in $tableName: $e');
      return false;
    }
  }
}
