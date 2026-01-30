import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/data/repositories/local/local_tax_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/datasources/local/pivot_element.dart';
import 'package:mts/data/models/item_tax/item_tax_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/domain/repositories/local/item_tax_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/tax_repository.dart';
import 'package:sqflite/sqflite.dart';

final itemTaxBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(ItemTaxModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final itemTaxLocalRepoProvider = Provider<LocalItemTaxRepository>((ref) {
  return LocalItemTaxRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    hiveBox: ref.read(itemTaxBoxProvider),
    localTaxRepository: ref.read(taxLocalRepoProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalItemTaxRepository] that uses local database
class LocalItemTaxRepositoryImpl implements LocalItemTaxRepository {
  final IDatabaseHelpers _dbHelper;
  final Box<Map> _hiveBox;
  final LocalTaxRepository _localTaxRepository;
  final LocalPendingChangesRepository _pendingChangesRepository;

  /// Database table and column names
  static const String itemId = 'item_id';
  static const String taxId = 'tax_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String tableName = 'item_tax';

  // Tax table constants
  static const String taxTableName = 'taxes';

  /// Constructor
  LocalItemTaxRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalTaxRepository localTaxRepository,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _hiveBox = hiveBox,
       _localTaxRepository = localTaxRepository,
       _pendingChangesRepository = pendingChangesRepository;

  /// Create the item tax table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $itemId TEXT NULL,
      $taxId TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert or update an item tax
  /// If the item exists (based on itemId and taxId), it will be updated
  /// If the item doesn't exist, it will be inserted
  @override
  Future<int> upsert(
    ItemTaxModel itemTaxModel, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;

    // Set the updated timestamp
    itemTaxModel.updatedAt = DateTime.now();

    try {
      // Check if the record exists
      List<Map<String, dynamic>> existingRecords = await db.query(
        tableName,
        where: '$itemId = ? AND $taxId = ?',
        whereArgs: [itemTaxModel.itemId, itemTaxModel.taxId],
      );

      String operation;
      int result;

      if (existingRecords.isNotEmpty) {
        // If the record exists, update it
        operation = 'updated';
        PivotElement firstElement = PivotElement(
          columnName: itemId,
          value: itemTaxModel.itemId!,
        );
        PivotElement secondElement = PivotElement(
          columnName: taxId,
          value: itemTaxModel.taxId!,
        );

        result = await _dbHelper.updatePivotDb(
          tableName,
          firstElement,
          secondElement,
          itemTaxModel.toJson(),
        );
      } else {
        // If the record doesn't exist, insert it
        operation = 'created';
        // Set the created timestamp for new records
        itemTaxModel.createdAt = DateTime.now();
        result = await _dbHelper.insertDb(tableName, itemTaxModel.toJson());
      }

      // Upsert to Hive using composite key
      final compositeKey = '${itemTaxModel.itemId}_${itemTaxModel.taxId}';
      await _hiveBox.put(compositeKey, itemTaxModel.toJson());

      // Insert to pending changes if required
      if (isInsertToPending) {
        Map<String, String> pivotData = {
          itemId: itemTaxModel.itemId!,
          taxId: itemTaxModel.taxId!,
        };

        final pendingChange = PendingChangesModel(
          operation: operation,
          modelName: ItemTaxModel.modelName,
          modelId: jsonEncode(pivotData),
          data: jsonEncode(itemTaxModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error upserting item tax', e);
      rethrow;
    }
  }

  @override
  Future<bool> upsertBulk(
    List<ItemTaxModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // Prepare pending changes to track after batch commit
      final List<PendingChangesModel> pendingChanges = [];
      final List<ItemTaxModel> toInsert = [];
      final List<ItemTaxModel> toUpdate = [];

      // Build a set of composite keys already seen in this batch
      final Set<String> seenKeys = {};

      for (ItemTaxModel newModel in list) {
        if (newModel.itemId == null || newModel.taxId == null) {
          continue;
        }

        final compositeKey = '${newModel.itemId}_${newModel.taxId}';

        // Skip if already processed in this batch
        if (seenKeys.contains(compositeKey)) continue;
        seenKeys.add(compositeKey);

        // Query records that need updating (existing and older)
        final List<Map<String, dynamic>> recordsToUpdate = await db.query(
          tableName,
          where: '$itemId = ? AND $taxId = ? AND $updatedAt < ?',
          whereArgs: [
            newModel.itemId,
            newModel.taxId,
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
            where: '$itemId = ? AND $taxId = ?',
            whereArgs: [newModel.itemId, newModel.taxId],
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
      for (ItemTaxModel model in toInsert) {
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
              modelName: ItemTaxModel.modelName,
              modelId: '${model.itemId}_${model.taxId}',
              data: jsonEncode(modelJson),
            ),
          );
        }
      }

      // Batch update existing records
      for (ItemTaxModel model in toUpdate) {
        model.updatedAt = DateTime.now();
        final modelJson = model.toJson();
        final keys = modelJson.keys.toList();
        final placeholders = keys.map((key) => '$key=?').join(',');

        batch.rawUpdate(
          '''UPDATE $tableName SET $placeholders 
             WHERE $itemId = ? AND $taxId = ?''',
          [...modelJson.values, model.itemId, model.taxId],
        );

        if (isInsertToPending) {
          pendingChanges.add(
            PendingChangesModel(
              operation: 'updated',
              modelName: ItemTaxModel.modelName,
              modelId: '${model.itemId}_${model.taxId}',
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
        if (model.itemId != null && model.taxId != null) {
          final compositeKey = '${model.itemId}_${model.taxId}';
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
      prints('Error inserting bulk item tax: $e');
      return false;
    }
  }

  // delete pivot
  // usage:
  // ItemTaxModel itemTax = ItemTaxModel(itemId: '1', taxId: '2');
  // int result = await deletePivot(itemTax, true);
  @override
  Future<int> deletePivot(
    ItemTaxModel itemTaxModel, {
    required bool isInsertToPending,
  }) async {
    // Validate required fields
    if (itemTaxModel.itemId == null || itemTaxModel.taxId == null) {
      prints('Cannot delete item tax: itemId or taxId is null');
      return 0;
    }

    // Create pivot elements from the model
    PivotElement firstElement = PivotElement(
      columnName: itemId,
      value: itemTaxModel.itemId!,
    );
    PivotElement secondElement = PivotElement(
      columnName: taxId,
      value: itemTaxModel.taxId!,
    );

    // Get the model before deleting it
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$itemId = ? AND $taxId = ?',
      whereArgs: [itemTaxModel.itemId, itemTaxModel.taxId],
    );

    if (results.isNotEmpty) {
      final model = ItemTaxModel.fromJson(results.first);

      // Delete the record
      int result = await _dbHelper.deletePivotDb(
        tableName,
        firstElement,
        secondElement,
      );

      // Delete from Hive
      final compositeKey = '${model.itemId}_${model.taxId}';
      await _hiveBox.delete(compositeKey);

      // Insert to pending changes if required
      if (isInsertToPending) {
        Map<String, String> pivotData = {
          itemId: model.itemId!,
          taxId: model.taxId!,
        };

        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: ItemTaxModel.modelName,
          modelId: jsonEncode(pivotData),
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints(
        'No item tax record found with itemId=${itemTaxModel.itemId} and taxId=${itemTaxModel.taxId}',
      );
      return 0;
    }
  }

  // delete bulk pivot
  @override
  Future<bool> deleteBulk(
    List<ItemTaxModel> listItemTax, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    try {
      for (ItemTaxModel cd in listItemTax) {
        // Skip items with null IDs
        if (cd.itemId == null || cd.taxId == null) {
          continue;
        }

        // If we need to insert to pending changes, get the model first
        if (isInsertToPending) {
          List<Map<String, dynamic>> results = await db.query(
            tableName,
            where: '$itemId = ? AND $taxId = ?',
            whereArgs: [cd.itemId, cd.taxId],
          );

          if (results.isNotEmpty) {
            final model = ItemTaxModel.fromJson(results.first);

            // Insert to pending changes
            Map<String, String> pivotData = {
              itemId: model.itemId!,
              taxId: model.taxId!,
            };

            final pendingChange = PendingChangesModel(
              operation: 'deleted',
              modelName: ItemTaxModel.modelName,
              modelId: jsonEncode(pivotData),
              data: jsonEncode(model.toJson()),
            );
            await _pendingChangesRepository.insert(pendingChange);
          }
        }

        // Delete the record using the batch operation
        batch.delete(
          tableName,
          where: '$itemId = ? AND $taxId = ?',
          whereArgs: [cd.itemId, cd.taxId],
        );
      }

      // Execute all delete operations in a single batch
      await batch.commit(noResult: true);

      // Delete from Hive
      for (ItemTaxModel cd in listItemTax) {
        if (cd.itemId != null && cd.taxId != null) {
          final compositeKey = '${cd.itemId}_${cd.taxId}';
          await _hiveBox.delete(compositeKey);
        }
      }

      return true;
    } catch (e) {
      prints('Error deleting bulk item tax: $e');
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
      await LogUtils.error('Error deleting all item tax', e);
      return false;
    }
  }

  // getListItemTax
  @override
  Future<List<ItemTaxModel>> getListItemTax() async {
    // Try Hive cache first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => ItemTaxModel.fromJson(json),
    );
    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return ItemTaxModel.fromJson(maps[index]);
    });
  }

  @override
  Future<List<TaxModel>> getTaxModelsByItemId(String idItem) async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$itemId = ?',
      whereArgs: [idItem],
    );

    // Extract tax IDs from the result
    List<String> taxIds = maps.map((map) => map['tax_id'] as String).toList();

    return await _localTaxRepository.getTaxModelsByTaxIds(taxIds);
  }

  @override
  Future<bool> replaceAllData(
    List<ItemTaxModel> newData, {
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
        final model = ItemTaxModel.fromJson(record);

        // Delete from Hive
        if (model.itemId != null && model.taxId != null) {
          final compositeKey = '${model.itemId}_${model.taxId}';
          await _hiveBox.delete(compositeKey);
        }

        // Track pending changes if required
        if (isInsertToPending) {
          Map<String, String> pivotData = {
            itemId: model.itemId ?? '',
            taxId: model.taxId ?? '',
          };

          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: ItemTaxModel.modelName,
            modelId: jsonEncode(pivotData),
            data: jsonEncode(model.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error deleting item tax by column name', e);
      return 0;
    }
  }
}
