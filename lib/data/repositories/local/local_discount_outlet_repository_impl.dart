import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/datasources/local/pivot_element.dart';
import 'package:mts/data/models/discount_outlet/discount_outlet_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/discount_outlet_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

final discountOutletBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(DiscountOutletModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final discountOutletLocalRepoProvider = Provider<LocalDiscountOutletRepository>(
  (ref) {
    return LocalDiscountOutletRepositoryImpl(
      dbHelper: ref.read(databaseHelpersProvider),
      pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
      hiveBox: ref.read(discountOutletBoxProvider),
    );
  },
);

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalDiscountOutletRepository] that uses local database
class LocalDiscountOutletRepositoryImpl
    implements LocalDiscountOutletRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String outletId = 'outlet_id';
  static const String discountId = 'discount_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String tableName = 'discount_outlet';

  /// Constructor
  LocalDiscountOutletRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the discount outlet table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $outletId TEXT NULL,
      $discountId TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  @override
  Future<int> upsert(
    DiscountOutletModel discountOutletModel, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;

    // Set the updated timestamp
    discountOutletModel.updatedAt = DateTime.now();

    try {
      // Check if the record exists
      List<Map<String, dynamic>> existingRecords = await db.query(
        tableName,
        where: '$discountId = ? AND $outletId = ?',
        whereArgs: [
          discountOutletModel.discountId,
          discountOutletModel.outletId,
        ],
      );

      String operation;
      int result;

      if (existingRecords.isNotEmpty) {
        // If the record exists, update it
        operation = 'updated';
        PivotElement firstElement = PivotElement(
          columnName: discountId,
          value: discountOutletModel.discountId!,
        );
        PivotElement secondElement = PivotElement(
          columnName: outletId,
          value: discountOutletModel.outletId!,
        );

        result = await _dbHelper.updatePivotDb(
          tableName,
          firstElement,
          secondElement,
          discountOutletModel.toJson(),
        );
      } else {
        // If the record doesn't exist, insert it
        operation = 'created';
        // Set the created timestamp for new records
        discountOutletModel.createdAt = DateTime.now();
        result = await _dbHelper.insertDb(
          tableName,
          discountOutletModel.toJson(),
        );
      }

      // Upsert to Hive using composite key
      final compositeKey =
          '${discountOutletModel.discountId}_${discountOutletModel.outletId}';
      await _hiveBox.put(compositeKey, discountOutletModel.toJson());

      // Insert to pending changes if required
      if (isInsertToPending) {
        Map<String, String> pivotData = {
          discountId: discountOutletModel.discountId!,
          outletId: discountOutletModel.outletId!,
        };

        final pendingChange = PendingChangesModel(
          operation: operation,
          modelName: DiscountOutletModel.modelName,
          modelId: jsonEncode(pivotData),
          data: jsonEncode(discountOutletModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error upserting discount outlet', e);
      rethrow;
    }
  }

  @override
  Future<bool> upsertBulk(
    List<DiscountOutletModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // Prepare pending changes to track after batch commit
      final List<PendingChangesModel> pendingChanges = [];
      final List<DiscountOutletModel> toInsert = [];
      final List<DiscountOutletModel> toUpdate = [];

      // Build a set of composite keys already seen in this batch
      final Set<String> seenKeys = {};

      for (DiscountOutletModel newModel in list) {
        if (newModel.discountId == null || newModel.outletId == null) {
          continue;
        }

        final compositeKey = '${newModel.discountId}_${newModel.outletId}';

        // Skip if already processed in this batch
        if (seenKeys.contains(compositeKey)) continue;
        seenKeys.add(compositeKey);

        // Query records that need updating (existing and older)
        final List<Map<String, dynamic>> recordsToUpdate = await db.query(
          tableName,
          where: '$discountId = ? AND $outletId = ? AND $updatedAt < ?',
          whereArgs: [
            newModel.discountId,
            newModel.outletId,
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
            where: '$discountId = ? AND $outletId = ?',
            whereArgs: [newModel.discountId, newModel.outletId],
          );

          if (existingRecords.isEmpty) {
            // Record doesn't exist, add to insert list
            toInsert.add(newModel);
          }
        }
      }

      // Use a single batch for all operations (atomic)
      Batch batch = db.batch();

      // Batch insert new records
      for (DiscountOutletModel model in toInsert) {
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
              modelName: DiscountOutletModel.modelName,
              modelId: '${model.discountId}_${model.outletId}',
              data: jsonEncode(modelJson),
            ),
          );
        }
      }

      // Batch update existing records
      for (DiscountOutletModel model in toUpdate) {
        model.updatedAt = DateTime.now();
        final modelJson = model.toJson();
        final keys = modelJson.keys.toList();
        final placeholders = keys.map((key) => '$key=?').join(',');

        batch.rawUpdate(
          '''UPDATE $tableName SET $placeholders 
             WHERE $discountId = ? AND $outletId = ?''',
          [...modelJson.values, model.discountId, model.outletId],
        );

        if (isInsertToPending) {
          pendingChanges.add(
            PendingChangesModel(
              operation: 'updated',
              modelName: DiscountOutletModel.modelName,
              modelId: '${model.discountId}_${model.outletId}',
              data: jsonEncode(modelJson),
            ),
          );
        }
      }

      // Commit batch atomically
      await batch.commit(noResult: true);

      // Bulk insert to Hive
      final dataMap = <dynamic, Map<dynamic, dynamic>>{};
      for (var model in [...toInsert, ...toUpdate]) {
        if (model.discountId != null && model.outletId != null) {
          final compositeKey = '${model.discountId}_${model.outletId}';
          dataMap[compositeKey] = model.toJson();
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
      prints('Error inserting bulk discount outlet: $e');
      return false;
    }
  }

  // delete pivot
  // usage:
  // DiscountOutletModel DiscountItem = DiscountOutletModel(discountId: '1', outletId: '2');
  // int result = await deletePivot(DiscountItem, true);
  @override
  Future<int> deletePivot(
    DiscountOutletModel discountOutletModel, {
    required bool isInsertToPending,
  }) async {
    // Validate required fields
    if (discountOutletModel.discountId == null ||
        discountOutletModel.outletId == null) {
      prints('Cannot delete discount outlet: discountId or outletId is null');
      return 0;
    }

    // Create pivot elements from the model
    PivotElement firstElement = PivotElement(
      columnName: discountId,
      value: discountOutletModel.discountId!,
    );
    PivotElement secondElement = PivotElement(
      columnName: outletId,
      value: discountOutletModel.outletId!,
    );

    // Get the model before deleting it
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$discountId = ? AND $outletId = ?',
      whereArgs: [discountOutletModel.discountId, discountOutletModel.outletId],
    );

    if (results.isNotEmpty) {
      final model = DiscountOutletModel.fromJson(results.first);

      // Delete the record
      int result = await _dbHelper.deletePivotDb(
        tableName,
        firstElement,
        secondElement,
      );

      // Delete from Hive
      final compositeKey = '${model.discountId}_${model.outletId}';
      await _hiveBox.delete(compositeKey);

      // Insert to pending changes if required
      if (isInsertToPending) {
        Map<String, String> pivotData = {
          discountId: model.discountId!,
          outletId: model.outletId!,
        };

        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: DiscountOutletModel.modelName,
          modelId: jsonEncode(pivotData),
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints(
        'No discount outlet record found with discountId=${discountOutletModel.discountId} and outletId=${discountOutletModel.outletId}',
      );
      return 0;
    }
  }

  // delete bulk pivot
  @override
  Future<bool> deleteBulk(
    List<DiscountOutletModel> listDiscountOutlet, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    try {
      for (DiscountOutletModel cd in listDiscountOutlet) {
        // Skip outlets with null IDs
        if (cd.discountId == null || cd.outletId == null) {
          continue;
        }

        // If we need to insert to pending changes, get the model first
        if (isInsertToPending) {
          List<Map<String, dynamic>> results = await db.query(
            tableName,
            where: '$discountId = ? AND $outletId = ?',
            whereArgs: [cd.discountId, cd.outletId],
          );

          if (results.isNotEmpty) {
            final model = DiscountOutletModel.fromJson(results.first);

            // Insert to pending changes
            Map<String, String> pivotData = {
              discountId: model.discountId!,
              outletId: model.outletId!,
            };

            final pendingChange = PendingChangesModel(
              operation: 'deleted',
              modelName: DiscountOutletModel.modelName,
              modelId: jsonEncode(pivotData),
              data: jsonEncode(model.toJson()),
            );
            await _pendingChangesRepository.insert(pendingChange);
          }
        }

        // Delete the record using the batch operation
        batch.delete(
          tableName,
          where: '$discountId = ? AND $outletId = ?',
          whereArgs: [cd.discountId, cd.outletId],
        );
      }

      // Execute all delete operations in a single batch
      await batch.commit(noResult: true);

      // Delete from Hive
      for (DiscountOutletModel cd in listDiscountOutlet) {
        if (cd.discountId != null && cd.outletId != null) {
          final compositeKey = '${cd.discountId}_${cd.outletId}';
          await _hiveBox.delete(compositeKey);
        }
      }

      return true;
    } catch (e) {
      prints('Error deleting bulk discount outlet: $e');
      return false;
    }
  }

  // delete all
  @override
  Future<bool> deleteAll() async {
    try {
      Database db = await _dbHelper.database;
      await db.delete(tableName);

      // Clear Hive
      await _hiveBox.clear();

      return true;
    } catch (e) {
      await LogUtils.error('Error deleting all discount outlet', e);
      return false;
    }
  }

  @override
  Future<List<DiscountOutletModel>> getListDiscountOutlet() async {
    // Try Hive cache first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => DiscountOutletModel.fromJson(json),
    );
    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return DiscountOutletModel.fromJson(maps[index]);
    });
  }

  @override
  Future<bool> replaceAllData(
    List<DiscountOutletModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      // Step 1: Delete all existing data from SQLite
      Database db = await _dbHelper.database;
      await db.delete(tableName);

      // Step 2: Clear Hive
      await _hiveBox.clear();

      // Step 3: Insert new data using existing insertBulk method
      if (newData.isNotEmpty) {
        bool insertResult = await upsertBulk(
          newData,
          isInsertToPending: isInsertToPending,
        );
        if (!insertResult) {
          await LogUtils.error(
            'Failed to insert bulk data in $tableName',
            null,
          );
          return false;
        }
      }

      return true;
    } catch (e) {
      await LogUtils.error('Error replacing all data in $tableName', e);
      return false;
    }
  }

  // ==================== Other Operations ====================

  @override
  Future<int> deleteByColumnName(
    String columnName,
    dynamic value, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      List<Map<String, dynamic>> results = await db.query(
        tableName,
        where: '$columnName = ?',
        whereArgs: [value],
      );

      int result = await db.delete(
        tableName,
        where: '$columnName = ?',
        whereArgs: [value],
      );

      // Delete from Hive and optionally track pending changes
      for (var record in results) {
        final model = DiscountOutletModel.fromJson(record);

        // Delete from Hive
        if (model.discountId != null && model.outletId != null) {
          final compositeKey = '${model.discountId}_${model.outletId}';
          await _hiveBox.delete(compositeKey);
        }

        // Track pending changes if required
        if (isInsertToPending) {
          Map<String, String> pivotData = {
            discountId: model.discountId ?? '',
            outletId: model.outletId ?? '',
          };

          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: DiscountOutletModel.modelName,
            modelId: jsonEncode(pivotData),
            data: jsonEncode(model.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error deleting discount outlet by column name', e);
      return 0;
    }
  }
}
