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
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/outlet_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

/// ================================
/// Provider for Hive Box
/// ================================
final outletBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(OutletModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final outletLocalRepoProvider = Provider<LocalOutletRepository>((ref) {
  return LocalOutletRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    hiveBox: ref.read(outletBoxProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalOutletRepository] that uses local database
class LocalOutletRepositoryImpl implements LocalOutletRepository {
  final IDatabaseHelpers _dbHelper;
  final Box<Map> _hiveBox;
  final LocalPendingChangesRepository _pendingChangesRepository;

  /// Database table and column names
  static const String tableName = 'outlets';
  static const String cId = 'id';
  static const String name = 'name';
  static const String address = 'address';
  static const String postcode = 'postcode';
  static const String phoneNo = 'phone_no';
  static const String description = 'description';
  static const String companyId = 'company_id';
  static const String nextOrderNumber = 'next_order_number';
  static const String isEnabledOpenOrder = 'is_enabled_open_order';
  static const String worldCountryId = 'world_country_id';
  static const String worldDivisionId = 'world_division_id';
  static const String worldCityId = 'world_city_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String fullAddress = 'full_address';

  /// Constructor
  LocalOutletRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required Box<Map> hiveBox,
    required LocalPendingChangesRepository pendingChangesRepository,
  }) : _dbHelper = dbHelper,
       _hiveBox = hiveBox,
       _pendingChangesRepository = pendingChangesRepository;

  /// Create the outlet table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $name TEXT NULL,
      $address TEXT NULL,
      $postcode TEXT NULL,
      $phoneNo TEXT NULL,
      $description TEXT NULL,
      $companyId TEXT NULL,
      $isEnabledOpenOrder INTEGER NULL,
      $nextOrderNumber INTEGER DEFAULT 1,
      $worldCountryId TEXT NULL,
      $worldDivisionId TEXT NULL,
      $worldCityId TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL,
      $fullAddress TEXT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Get all outlets
  @override
  Future<List<OutletModel>> getListOutletModel() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);

    return List.generate(maps.length, (i) {
      return OutletModel.fromJson(maps[i]);
    });
  }

  @override
  Future<bool> upsertBulk(
    List<OutletModel> list, {
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

      for (OutletModel model in list) {
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
                modelName: OutletModel.modelName,
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
                modelName: OutletModel.modelName,
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
      prints('Error inserting bulk outlet: $e');
      return false;
    }
  }

  @override
  Future<OutletModel> getOutletModelById(String idModifier) async {
    List<OutletModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: OutletModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list.where((element) => element.id == idModifier).first;
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [idModifier],
    );
    return OutletModel.fromJson(maps.first);
  }

  // delete bulk
  @override
  Future<bool> deleteBulk(
    List<OutletModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();
    try {
      // If we need to insert to pending changes, we need to get the models first
      if (isInsertToPending) {
        for (OutletModel outlet in list) {
          List<Map<String, dynamic>> results = await db.query(
            tableName,
            where: '$cId = ?',
            whereArgs: [outlet.id],
          );

          if (results.isNotEmpty) {
            final model = OutletModel.fromJson(results.first);

            // Insert to pending changes
            final pendingChange = PendingChangesModel(
              operation: 'deleted',
              modelName: OutletModel.modelName,
              modelId: model.id!,
              data: jsonEncode(model.toJson()),
            );
            await _pendingChangesRepository.insert(pendingChange);
          }
        }
      }

      // Now delete the records
      for (OutletModel outlet in list) {
        batch.delete(tableName, where: '$cId = ?', whereArgs: [outlet.id]);
      }

      await batch.commit(noResult: true);

      // Delete from Hive cache
      final idsToDelete = list.map((m) => m.id).whereType<String>().toList();
      if (idsToDelete.isNotEmpty) {
        await _hiveBox.deleteAll(idsToDelete);
      }

      return true;
    } catch (e) {
      prints('Error deleting bulk outlets: $e');
      return false;
    }
  }

  // delete all
  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await db.delete(tableName);
      await _hiveBox.clear();
      return true;
    } catch (e) {
      prints('Error deleting all outlets: $e');
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<OutletModel> newData, {
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
  Future<OutletModel> getLatestOutletModel() async {
    // Get all outlets and return the first one (or empty if none exist)
    final outlets = await getListOutletModel();
    if (outlets.isNotEmpty) {
      return outlets.first;
    }
    return OutletModel();
  }

  @override
  Future<int> delete(String id, {required bool isInsertToPending}) async {
    Database db = await _dbHelper.database;
    int result = await db.delete(tableName, where: '$cId = ?', whereArgs: [id]);

    // Delete from Hive cache
    if (result > 0) {
      await _hiveBox.delete(id);
    }

    return result;
  }
}
