import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/datasources/local/pivot_element.dart';
import 'package:mts/data/models/discount/discount_model.dart';
import 'package:mts/data/models/discount_item/discount_item_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/repositories/local/local_discount_repository_impl.dart';
import 'package:mts/domain/repositories/local/discount_item_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

final discountItemBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(DiscountItemModel.modelBoxName);
});

/// ================================
/// Provider for Local Repositorya
/// ================================
final discountItemLocalRepoProvider = Provider<LocalDiscountItemRepository>((
  ref,
) {
  return LocalDiscountItemRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(discountItemBoxProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalDiscountItemRepository] that uses local database
class LocalDiscountItemRepositoryImpl implements LocalDiscountItemRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String itemId = 'item_id';
  static const String discountId = 'discount_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String tableName = 'discount_item';

  // Discount table constants
  static const String discountTableName = 'discounts';
  static const String validFrom = 'valid_from';
  static const String validTo = 'valid_to';

  /// Constructor
  LocalDiscountItemRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the discount item table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $itemId TEXT NULL,
      $discountId TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  @override
  Future<int> upsert(
    DiscountItemModel discountItemModel, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;

    // Set the updated timestamp
    discountItemModel.updatedAt = DateTime.now();

    try {
      // Check if the record exists
      List<Map<String, dynamic>> existingRecords = await db.query(
        tableName,
        where: '$discountId = ? AND $itemId = ?',
        whereArgs: [discountItemModel.discountId, discountItemModel.itemId],
      );

      String operation;
      int result;

      if (existingRecords.isNotEmpty) {
        // If the record exists, update it
        operation = 'updated';
        PivotElement firstElement = PivotElement(
          columnName: discountId,
          value: discountItemModel.discountId!,
        );
        PivotElement secondElement = PivotElement(
          columnName: itemId,
          value: discountItemModel.itemId!,
        );

        result = await _dbHelper.updatePivotDb(
          tableName,
          firstElement,
          secondElement,
          discountItemModel.toJson(),
        );
      } else {
        // If the record doesn't exist, insert it
        operation = 'created';
        // Set the created timestamp for new records
        discountItemModel.createdAt = DateTime.now();
        result = await _dbHelper.insertDb(
          tableName,
          discountItemModel.toJson(),
        );
      }

      // Upsert to Hive using composite key
      final compositeKey =
          '${discountItemModel.discountId}_${discountItemModel.itemId}';
      await _hiveBox.put(compositeKey, discountItemModel.toJson());

      // Insert to pending changes if required
      if (isInsertToPending) {
        Map<String, String> pivotData = {
          discountId: discountItemModel.discountId!,
          itemId: discountItemModel.itemId!,
        };

        final pendingChange = PendingChangesModel(
          operation: operation,
          modelName: DiscountItemModel.modelName,
          modelId: jsonEncode(pivotData),
          data: jsonEncode(discountItemModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error upserting discount item', e);
      rethrow;
    }
  }

  @override
  Future<bool> upsertBulk(
    List<DiscountItemModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // Prepare pending changes to track after batch commit
      final List<PendingChangesModel> pendingChanges = [];
      final List<DiscountItemModel> toInsert = [];
      final List<DiscountItemModel> toUpdate = [];

      // Build a set of composite keys already seen in this batch
      final Set<String> seenKeys = {};

      for (DiscountItemModel newModel in list) {
        if (newModel.discountId == null || newModel.itemId == null) {
          continue;
        }

        final compositeKey = '${newModel.discountId}_${newModel.itemId}';

        // Skip if already processed in this batch
        if (seenKeys.contains(compositeKey)) continue;
        seenKeys.add(compositeKey);

        // Query records that need updating (existing and older)
        final List<Map<String, dynamic>> recordsToUpdate = await db.query(
          tableName,
          where: '$discountId = ? AND $itemId = ? AND $updatedAt < ?',
          whereArgs: [
            newModel.discountId,
            newModel.itemId,
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
            where: '$discountId = ? AND $itemId = ?',
            whereArgs: [newModel.discountId, newModel.itemId],
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
      for (DiscountItemModel model in toInsert) {
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
              modelName: DiscountItemModel.modelName,
              modelId: '${model.discountId}_${model.itemId}',
              data: jsonEncode(modelJson),
            ),
          );
        }
      }

      // Batch update existing records
      for (DiscountItemModel model in toUpdate) {
        model.updatedAt = DateTime.now();
        final modelJson = model.toJson();
        final keys = modelJson.keys.toList();
        final placeholders = keys.map((key) => '$key=?').join(',');

        batch.rawUpdate(
          '''UPDATE $tableName SET $placeholders 
             WHERE $discountId = ? AND $itemId = ?''',
          [...modelJson.values, model.discountId, model.itemId],
        );

        if (isInsertToPending) {
          pendingChanges.add(
            PendingChangesModel(
              operation: 'updated',
              modelName: DiscountItemModel.modelName,
              modelId: '${model.discountId}_${model.itemId}',
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
        if (model.discountId != null && model.itemId != null) {
          final compositeKey = '${model.discountId}_${model.itemId}';
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
      prints('Error inserting bulk discount item: $e');
      return false;
    }
  }

  // delete pivot
  // usage:
  // DiscountItemModel DiscountItem = DiscountItemModel(discountId: '1', itemId: '2');
  // int result = await deletePivot(DiscountItem, true);
  @override
  Future<int> deletePivot(
    DiscountItemModel discountItemModel, {
    required bool isInsertToPending,
  }) async {
    // Validate required fields
    if (discountItemModel.discountId == null ||
        discountItemModel.itemId == null) {
      prints('Cannot delete discount item: discountId or itemId is null');
      return 0;
    }

    // Create pivot elements from the model
    PivotElement firstElement = PivotElement(
      columnName: discountId,
      value: discountItemModel.discountId!,
    );
    PivotElement secondElement = PivotElement(
      columnName: itemId,
      value: discountItemModel.itemId!,
    );

    // Get the model before deleting it
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$discountId = ? AND $itemId = ?',
      whereArgs: [discountItemModel.discountId, discountItemModel.itemId],
    );

    if (results.isNotEmpty) {
      final model = DiscountItemModel.fromJson(results.first);

      // Delete the record
      int result = await _dbHelper.deletePivotDb(
        tableName,
        firstElement,
        secondElement,
      );

      // Delete from Hive
      final compositeKey = '${model.discountId}_${model.itemId}';
      await _hiveBox.delete(compositeKey);

      // Insert to pending changes if required
      if (isInsertToPending) {
        Map<String, String> pivotData = {
          discountId: model.discountId!,
          itemId: model.itemId!,
        };

        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: DiscountItemModel.modelName,
          modelId: jsonEncode(pivotData),
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints(
        'No discount item record found with discountId=${discountItemModel.discountId} and itemId=${discountItemModel.itemId}',
      );
      return 0;
    }
  }

  // delete bulk pivot
  @override
  Future<bool> deleteBulk(
    List<DiscountItemModel> listDiscountItem, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    try {
      for (DiscountItemModel cd in listDiscountItem) {
        // Skip items with null IDs
        if (cd.discountId == null || cd.itemId == null) {
          continue;
        }

        // If we need to insert to pending changes, get the model first
        if (isInsertToPending) {
          List<Map<String, dynamic>> results = await db.query(
            tableName,
            where: '$discountId = ? AND $itemId = ?',
            whereArgs: [cd.discountId, cd.itemId],
          );

          if (results.isNotEmpty) {
            final model = DiscountItemModel.fromJson(results.first);

            // Insert to pending changes
            Map<String, String> pivotData = {
              discountId: model.discountId!,
              itemId: model.itemId!,
            };

            final pendingChange = PendingChangesModel(
              operation: 'deleted',
              modelName: DiscountItemModel.modelName,
              modelId: jsonEncode(pivotData),
              data: jsonEncode(model.toJson()),
            );
            await _pendingChangesRepository.insert(pendingChange);
          }
        }

        // Delete the record using the batch operation
        batch.delete(
          tableName,
          where: '$discountId = ? AND $itemId = ?',
          whereArgs: [cd.discountId, cd.itemId],
        );
      }

      // Execute all delete operations in a single batch
      await batch.commit(noResult: true);

      // Delete from Hive
      for (DiscountItemModel cd in listDiscountItem) {
        if (cd.discountId != null && cd.itemId != null) {
          final compositeKey = '${cd.discountId}_${cd.itemId}';
          await _hiveBox.delete(compositeKey);
        }
      }

      return true;
    } catch (e) {
      prints('Error deleting bulk discount item: $e');
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
      await LogUtils.error('Error deleting all discount item', e);
      return false;
    }
  }

  @override
  Future<List<DiscountItemModel>> getListDiscountItem() async {
    // Try Hive cache first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => DiscountItemModel.fromJson(json),
    );
    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return DiscountItemModel.fromJson(maps[index]);
    });
  }

  @override
  Future<bool> replaceAllData(
    List<DiscountItemModel> newData, {
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
        final model = DiscountItemModel.fromJson(record);

        // Delete from Hive
        if (model.discountId != null && model.itemId != null) {
          final compositeKey = '${model.discountId}_${model.itemId}';
          await _hiveBox.delete(compositeKey);
        }

        // Track pending changes if required
        if (isInsertToPending) {
          Map<String, String> pivotData = {
            discountId: model.discountId ?? '',
            itemId: model.itemId ?? '',
          };

          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: DiscountItemModel.modelName,
            modelId: jsonEncode(pivotData),
            data: jsonEncode(model.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error deleting discount item by column name', e);
      return 0;
    }
  }

  // get discount models by item id
  @override
  Future<List<DiscountModel>> getValidDiscountModelsByItemId(
    String idItem,
  ) async {
    Database db = await _dbHelper.database;

    // Get current date and time
    DateTime now = DateTime.now();

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
    SELECT d.* FROM $tableName di
    INNER JOIN ${LocalDiscountRepositoryImpl.tableName} d
    ON di.discount_id = d.id
    WHERE di.$itemId = ?
    AND (d.${LocalDiscountRepositoryImpl.validFrom} IS NULL OR d.${LocalDiscountRepositoryImpl.validFrom} <= ?)
    AND (d.${LocalDiscountRepositoryImpl.validTo} IS NULL OR d.${LocalDiscountRepositoryImpl.validTo} >= ?)
    ''',
      [idItem, now.toIso8601String(), now.toIso8601String()],
    );

    // Extract discount models from the result
    List<DiscountModel> discountModels =
        maps.map((map) => DiscountModel.fromJson(map)).toList();

    return discountModels;
  }
}
