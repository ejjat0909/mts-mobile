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
import 'package:mts/data/models/sale_variant_option/sale_variant_option_model.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/sale_variant_option_repository.dart';
import 'package:sqflite/sqflite.dart';

final saleVariantOptionBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(SaleVariantOptionModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final saleVariantOptionLocalRepoProvider =
    Provider<LocalSaleVariantOptionRepository>((ref) {
      return LocalSaleVariantOptionRepositoryImpl(
        dbHelper: ref.read(databaseHelpersProvider),
        pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
        hiveBox: ref.read(saleVariantOptionBoxProvider),
      );
    });

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalSaleVariantOptionRepository] that uses local database
class LocalSaleVariantOptionRepositoryImpl
    implements LocalSaleVariantOptionRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String id = 'id';
  static const String variantOptionId = 'variant_option_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String tableName = 'sale_variant_options';

  /// Constructor
  LocalSaleVariantOptionRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the sale variant option table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $id TEXT PRIMARY KEY,
      $variantOptionId TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new sale variant option
  @override
  Future<int> insert(
    SaleVariantOptionModel saleVariantOptionModel, {
    required bool isInsertToPending,
  }) async {
    saleVariantOptionModel.id ??= IdUtils.generateUUID().toString();
    saleVariantOptionModel.updatedAt = DateTime.now();
    saleVariantOptionModel.createdAt = DateTime.now();

    // Insert to SQLite
    int result = await _dbHelper.insertDb(
      tableName,
      saleVariantOptionModel.toJson(),
    );

    // Sync to Hive cache
    await _hiveBox.put(
      saleVariantOptionModel.id,
      saleVariantOptionModel.toJson(),
    );

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'created',
        modelName: SaleVariantOptionModel.modelName,
        modelId: saleVariantOptionModel.id!,
        data: jsonEncode(saleVariantOptionModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    return result;
  }

  // update using model
  @override
  Future<int> update(
    SaleVariantOptionModel saleVariantOptionModel, {
    required bool isInsertToPending,
  }) async {
    saleVariantOptionModel.updatedAt = DateTime.now();

    // Update SQLite
    int result = await _dbHelper.updateDb(
      tableName,
      saleVariantOptionModel.toJson(),
    );

    // Sync to Hive cache
    await _hiveBox.put(
      saleVariantOptionModel.id,
      saleVariantOptionModel.toJson(),
    );

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: SaleVariantOptionModel.modelName,
        modelId: saleVariantOptionModel.id!,
        data: jsonEncode(saleVariantOptionModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    return result;
  }

  // delete using id
  @override
  Future<int> delete(String id, {required bool isInsertToPending}) async {
    // Get the model before deleting it
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      final model = SaleVariantOptionModel(
        id: results.first['id'],
        variantOptionId: results.first['variant_option_id'],
        createdAt:
            results.first['created_at'] != null
                ? DateTime.parse(results.first['created_at'])
                : null,
        updatedAt:
            results.first['updated_at'] != null
                ? DateTime.parse(results.first['updated_at'])
                : null,
      );

      // Delete the record
      await _hiveBox.delete(id);
      int result = await _dbHelper.deleteDb(tableName, id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: SaleVariantOptionModel.modelName,
          modelId: model.id!,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No sale variant option record found with id: $id');
      return 0;
    }
  }

  /// Delete multiple sale variant options
  @override
  Future<bool> deleteBulk(
    List<SaleVariantOptionModel> saleVariantOptions, {
    required bool isInsertToPending,
  }) async {
    try {
      for (final item in saleVariantOptions) {
        if (item.id != null) {
          await delete(item.id!, isInsertToPending: isInsertToPending);
        }
      }
      // Sync deletions to Hive cache
      await _hiveBox.deleteAll(
        saleVariantOptions
            .where((m) => m.id != null)
            .map((m) => m.id!)
            .toList(),
      );
      return true;
    } catch (e) {
      prints('Error deleting bulk sale variant options: $e');
      return false;
    }
  }

  /// Delete all sale variant options
  @override
  Future<bool> deleteAll() async {
    try {
      Database db = await _dbHelper.database;
      await db.delete(tableName);

      // Clear Hive box
      await _hiveBox.clear();

      return true;
    } catch (e) {
      prints('Error deleting all sale variant options: $e');
      return false;
    }
  }

  // get all
  @override
  Future<List<SaleVariantOptionModel>> getListSaleVariantOption() async {
    List<SaleVariantOptionModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: SaleVariantOptionModel.fromJson,
    );

    if (list.isNotEmpty) {
      return list;
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return SaleVariantOptionModel.fromJson(maps[index]);
    });
  }

  // insert bulk
  @override
  Future<bool> upsertBulk(
    List<SaleVariantOptionModel> list, {
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
          where: '$id IN ($placeholders)',
          whereArgs: idsToInsert,
          columns: [id],
        );
        existingIds.addAll(existingRecords.map((r) => r[id] as String));
      }

      // Prepare pending changes to track after batch commit
      final List<PendingChangesModel> pendingChanges = [];

      // Use a single batch for all operations (atomic)
      // Key: Only ONE pre-flight check before batch, not per-item checks
      Batch batch = db.batch();

      for (SaleVariantOptionModel model in list) {
        if (model.id == null) continue;

        final isExisting = existingIds.contains(model.id);
        final modelJson = model.toJson();

        if (isExisting) {
          // Only update if new item is newer than existing one
          batch.update(
            tableName,
            modelJson,
            where: '$id = ? AND ($updatedAt IS NULL OR $updatedAt <= ?)',
            whereArgs: [
              model.id,
              DateTimeUtils.getDateTimeFormat(model.updatedAt),
            ],
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'updated',
                modelName: SaleVariantOptionModel.modelName,
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
                modelName: SaleVariantOptionModel.modelName,
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
      prints('Error inserting bulk sale variant option: $e');
      return false;
    }
  }

  /// Replace all data in the table with new data
  @override
  Future<bool> replaceAllData(
    List<SaleVariantOptionModel> newData, {
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
