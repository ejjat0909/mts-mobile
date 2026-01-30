import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/datasources/local/pivot_element.dart';
import 'package:mts/data/models/item_modifier/item_modifier_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/item_modifier_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mts/core/storage/hive_box_manager.dart';

final itemModifierBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(ItemModifierModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final itemModifierLocalRepoProvider = Provider<LocalItemModifierRepository>((
  ref,
) {
  return LocalItemModifierRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    hiveBox: ref.read(itemModifierBoxProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalItemModifierRepository] that uses local database
class LocalItemModifierRepositoryImpl implements LocalItemModifierRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String itemId = 'item_id';
  static const String modifierId = 'modifier_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String tableName = 'item_modifier';

  /// Constructor
  LocalItemModifierRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required Box<Map> hiveBox,
    required LocalPendingChangesRepository pendingChangesRepository,
  }) : _dbHelper = dbHelper,
       _hiveBox = hiveBox,
       _pendingChangesRepository = pendingChangesRepository;

  /// Create the item modifier table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $itemId TEXT NULL,
      $modifierId TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';

    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert or update an item modifier
  /// If the item exists (based on itemId and modifierId), it will be updated
  /// If the item doesn't exist, it will be inserted
  @override
  Future<int> upsert(
    ItemModifierModel itemModifierModel, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;

    // Set the updated timestamp if null
    itemModifierModel.updatedAt = DateTime.now();

    // Check if the record exists
    List<Map<String, dynamic>> existingRecords = await db.query(
      tableName,
      where: '$itemId = ? AND $modifierId = ?',
      whereArgs: [itemModifierModel.itemId, itemModifierModel.modifierId],
    );

    String operation;
    int result;
    final compositeKey =
        '${itemModifierModel.itemId}_${itemModifierModel.modifierId}';

    if (existingRecords.isNotEmpty) {
      // If the record exists, update it
      operation = 'updated';
      PivotElement firstElement = PivotElement(
        columnName: itemId,
        value: itemModifierModel.itemId!,
      );
      PivotElement secondElement = PivotElement(
        columnName: modifierId,
        value: itemModifierModel.modifierId!,
      );

      result = await _dbHelper.updatePivotDb(
        tableName,
        firstElement,
        secondElement,
        itemModifierModel.toJson(),
      );
    } else {
      // If the record doesn't exist, insert it
      operation = 'created';
      // Set the created timestamp for new records
      itemModifierModel.createdAt = DateTime.now();
      result = await _dbHelper.insertDb(tableName, itemModifierModel.toJson());
    }

    // Sync to Hive
    await _hiveBox.put(compositeKey, itemModifierModel.toJson());

    // Insert to pending changes if required
    if (isInsertToPending) {
      Map<String, String> pivotData = {
        itemId: itemModifierModel.itemId!,
        modifierId: itemModifierModel.modifierId!,
      };

      final pendingChange = PendingChangesModel(
        operation: operation,
        modelName: ItemModifierModel.modelName,
        modelId: jsonEncode(pivotData),
        data: jsonEncode(itemModifierModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    return result;
  }

  // delete pivot
  // usage:
  // ItemModifierModel itemModifier = ItemModifierModel(itemId: '1', modifierId: '2');
  // int result = await deletePivot(itemModifier, true);
  @override
  Future<int> deletePivot(
    ItemModifierModel itemModifier, {
    required bool isInsertToPending,
  }) async {
    // Validate required fields
    if (itemModifier.itemId == null || itemModifier.modifierId == null) {
      prints('Cannot delete item modifier: itemId or modifierId is null');
      return 0;
    }

    // Create pivot elements from the model
    PivotElement firstElement = PivotElement(
      columnName: itemId,
      value: itemModifier.itemId!,
    );
    PivotElement secondElement = PivotElement(
      columnName: modifierId,
      value: itemModifier.modifierId!,
    );

    // Get the model before deleting it
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$itemId = ? AND $modifierId = ?',
      whereArgs: [itemModifier.itemId, itemModifier.modifierId],
    );

    if (results.isNotEmpty) {
      final model = ItemModifierModel.fromJson(results.first);
      final compositeKey = '${model.itemId}_${model.modifierId}';

      // Delete from Hive
      await _hiveBox.delete(compositeKey);

      // Delete the record
      int result = await _dbHelper.deletePivotDb(
        tableName,
        firstElement,
        secondElement,
      );

      // Insert to pending changes if required
      if (isInsertToPending) {
        Map<String, String> pivotData = {
          itemId: model.itemId!,
          modifierId: model.modifierId!,
        };

        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: ItemModifierModel.modelName,
          modelId: jsonEncode(pivotData),
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints(
        'No item modifier record found with itemId=${itemModifier.itemId} and modifierId=${itemModifier.modifierId}',
      );
      return 0;
    }
  }

  @override
  Future<bool> deleteBulk(
    List<ItemModifierModel> listItemModifier, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    try {
      for (ItemModifierModel imm in listItemModifier) {
        // Skip items with null IDs
        if (imm.itemId == null || imm.modifierId == null) {
          continue;
        }

        // If we need to insert to pending changes, get the model first
        if (isInsertToPending) {
          List<Map<String, dynamic>> results = await db.query(
            tableName,
            where: '$itemId = ? AND $modifierId = ?',
            whereArgs: [imm.itemId, imm.modifierId],
          );

          if (results.isNotEmpty) {
            final model = ItemModifierModel.fromJson(results.first);

            // Insert to pending changes
            Map<String, String> pivotData = {
              itemId: model.itemId!,
              modifierId: model.modifierId!,
            };

            final pendingChange = PendingChangesModel(
              operation: 'deleted',
              modelName: ItemModifierModel.modelName,
              modelId: jsonEncode(pivotData),
              data: jsonEncode(model.toJson()),
            );
            await _pendingChangesRepository.insert(pendingChange);
          }
        }

        // Delete the record using the batch operation
        batch.delete(
          tableName,
          where: '$itemId = ? AND $modifierId = ?',
          whereArgs: [imm.itemId, imm.modifierId],
        );
      }

      // Execute all delete operations in a single batch
      await batch.commit(noResult: true);

      // Delete from Hive box
      for (ItemModifierModel imm in listItemModifier) {
        if (imm.itemId != null && imm.modifierId != null) {
          final compositeKey = '${imm.itemId}_${imm.modifierId}';
          await _hiveBox.delete(compositeKey);
        }
      }

      return true;
    } catch (e) {
      prints('Error deleting bulk item modifier: $e');
      return false;
    }
  }

  // delete all
  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await db.delete(tableName);

      // Clear Hive box
      await _hiveBox.clear();

      return true;
    } catch (e) {
      prints('Error deleting all item modifier: $e');
      return false;
    }
  }

  // getListItemModifier
  @override
  Future<List<ItemModifierModel>> getListItemModifier() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return ItemModifierModel.fromJson(maps[index]);
    });
  }

  // insert bulk
  @override
  Future<bool> upsertBulk(
    List<ItemModifierModel> listItemModifier, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // Prepare pending changes to track after batch commit
      final List<PendingChangesModel> pendingChanges = [];

      // Use a single batch for all operations (atomic)
      Batch batch = db.batch();

      for (ItemModifierModel model in listItemModifier) {
        if (model.itemId == null || model.modifierId == null) {
          continue; // Skip items with null IDs
        }

        final modelJson = model.toJson();

        // For composite key pivot tables, use INSERT OR IGNORE then update
        batch.rawInsert(
          '''INSERT OR IGNORE INTO $tableName (${modelJson.keys.join(',')})
             VALUES (${List.filled(modelJson.length, '?').join(',')})''',
          modelJson.values.toList(),
        );

        // Also attempt update in case record exists
        batch.update(
          tableName,
          modelJson,
          where: '$itemId = ? AND $modifierId = ?',
          whereArgs: [model.itemId, model.modifierId],
        );

        if (isInsertToPending) {
          Map<String, String> pivotData = {
            itemId: model.itemId!,
            modifierId: model.modifierId!,
          };

          pendingChanges.add(
            PendingChangesModel(
              operation: 'created',
              modelName: ItemModifierModel.modelName,
              modelId: jsonEncode(pivotData),
              data: jsonEncode(modelJson),
            ),
          );
        }
      }

      // Commit batch atomically
      await batch.commit(noResult: true);

      // Bulk insert to Hive
      final dataMap = <dynamic, Map<dynamic, dynamic>>{};
      for (var model in listItemModifier) {
        if (model.itemId != null && model.modifierId != null) {
          final compositeKey = '${model.itemId}_${model.modifierId}';
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
      prints('Error inserting bulk item modifier: $e');
      return false;
    }
  }

  // Get modifier IDs by item ID
  @override
  Future<List<String?>> getModifierIdsByItemId(String id) async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: [modifierId],
      where: '$itemId = ?',
      whereArgs: [id],
    );
    return maps.map((map) => map[modifierId] as String?).toList();
  }

  @override
  Future<bool> replaceAllData(
    List<ItemModifierModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      // Step 1: Delete all existing data
      Database db = await _dbHelper.database;
      await db.delete(tableName);

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

  /// Get list of item modifiers from Hive box
  List<ItemModifierModel> getListItemModifierFromHive() {
    return HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => ItemModifierModel.fromJson(json),
    );
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

      if (isInsertToPending && results.isNotEmpty) {
        for (var record in results) {
          final model = ItemModifierModel.fromJson(record);
          Map<String, String> pivotData = {
            itemId: model.itemId ?? '',
            modifierId: model.modifierId ?? '',
          };

          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: ItemModifierModel.modelName,
            modelId: jsonEncode(pivotData),
            data: jsonEncode(model.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }

      return result;
    } catch (e) {
      prints('Error deleting item modifier by column name: $e');
      return 0;
    }
  }
}
