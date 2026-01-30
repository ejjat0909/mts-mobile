import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';
import 'package:mts/domain/repositories/local/item_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mts/core/storage/hive_box_manager.dart';

final itemBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(ItemModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final itemLocalRepoProvider = Provider<LocalItemRepository>((ref) {
  return LocalItemRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    hiveBox: ref.read(itemBoxProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalItemRepository] that uses local database
class LocalItemRepositoryImpl implements LocalItemRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  static const String tableName = 'items';

  /// Database table and column names
  static const String cId = 'id';
  static const String name = 'name';
  static const String variantOptionJson = 'variant_option_json';
  static const String categoryId = 'category_id';
  static const String barcode = 'barcode';
  static const String description = 'description';
  static const String soldBy = 'sold_by';
  static const String sku = 'sku';
  static const String requiredModifierNum = 'required_modifier_num';
  static const String price = 'price';
  static const String cost = 'cost';
  static const String itemRepresentationId = 'item_representation_id';
  static const String inventoryId = 'inventory_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  /// Constructor
  LocalItemRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required Box<Map> hiveBox,
    required LocalPendingChangesRepository pendingChangesRepository,
  }) : _dbHelper = dbHelper,
       _hiveBox = hiveBox,
       _pendingChangesRepository = pendingChangesRepository;

  /// Create the item table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $name TEXT NULL,
      $variantOptionJson TEXT NULL,
      $categoryId TEXT NULL,
      $barcode TEXT NULL,
      $description TEXT NULL,
      $soldBy TEXT NULL,
      $sku TEXT NULL,
      $price FLOAT NULL,
      $cost FLOAT NULL,
      $requiredModifierNum INTEGER DEFAULT 0,
      $itemRepresentationId TEXT NULL,
      $inventoryId TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';

    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  @override
  Future<int> insert(
    ItemModel itemModel, {
    required bool isInsertToPending,
  }) async {
    itemModel.id ??= IdUtils.generateUUID().toString();
    itemModel.updatedAt = DateTime.now();
    itemModel.createdAt = DateTime.now();

    try {
      // Insert to SQLite
      int result = await _dbHelper.insertDb(tableName, itemModel.toJson());

      // Insert to Hive
      await _hiveBox.put(itemModel.id!, itemModel.toJson());

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'created',
          modelName: ItemModel.modelName,
          modelId: itemModel.id!,
          data: jsonEncode(itemModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error inserting item', e);
      rethrow;
    }
  }

  @override
  Future<int> update(
    ItemModel itemModel, {
    required bool isInsertToPending,
  }) async {
    itemModel.updatedAt = DateTime.now();

    try {
      // Update SQLite
      int result = await _dbHelper.updateDb(tableName, itemModel.toJson());

      // Update Hive
      await _hiveBox.put(itemModel.id!, itemModel.toJson());

      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'updated',
          modelName: ItemModel.modelName,
          modelId: itemModel.id!,
          data: jsonEncode(itemModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error updating item', e);
      rethrow;
    }
  }

  // delete
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
      final model = ItemModel.fromJson(results.first);

      // Delete from Hive
      await _hiveBox.delete(id);

      // Delete the record
      int result = await _dbHelper.deleteDb(tableName, id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: ItemModel.modelName,
          modelId: model.id,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No item record found with id: $id');
      return 0;
    }
  }

  List<ItemModel> sortItemList(List<ItemModel> listItem) {
    listItem.sort((a, b) => a.name!.compareTo(b.name!));
    return listItem;
  }

  // get list item
  @override
  Future<List<ItemModel>> getListItemModel() async {
    List<ItemModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => ItemModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list;
    }
    try {
      Database db = await _dbHelper.database;
      List<Map<String, dynamic>> results = await db.query(tableName);

      return results.map((map) => ItemModel.fromJson(map)).toList();
    } catch (e) {
      return [];
    }
  }

  // insert bulk
  @override
  Future<bool> upsertBulk(
    List<ItemModel> listItem, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // First, collect all existing IDs in a single query to check for creates vs updates
      // This eliminates the race condition: single query instead of per-item checks
      final idsToInsert =
          listItem.map((m) => m.id).whereType<String>().toList();

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

      for (ItemModel model in listItem) {
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
                modelName: ItemModel.modelName,
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
                modelName: ItemModel.modelName,
                modelId: model.id!,
                data: jsonEncode(modelJson),
              ),
            );
          }
        }
      }

      // Commit batch atomically
      await batch.commit(noResult: true);

      // Bulk insert to Hive
      final dataMap = <dynamic, Map<dynamic, dynamic>>{};
      for (var model in listItem) {
        if (model.id != null) {
          dataMap[model.id!] = model.toJson();
        }
      }
      await _hiveBox.putAll(dataMap);

      // Track pending changes AFTER successful batch commit
      // This ensures we only track changes that actually succeeded
      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      prints('Error inserting bulk item: $e');
      return false;
    }
  }

  @override
  Future<ItemModel?> getItemModelById(String itemId) async {
    List<ItemModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => ItemModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list.where((element) => element.id == itemId).firstOrNull;
    }
    try {
      Database db = await _dbHelper.database;
      List<Map<String, dynamic>> results = await db.query(
        tableName,
        where: '$cId = ?',
        whereArgs: [itemId],
      );

      if (results.isNotEmpty) {
        return ItemModel.fromJson(results.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // get item models by ids

  @override
  Future<List<ItemModel>> getItemModelsByIds(List<String> itemIds) async {
    if (itemIds.isEmpty) return [];

    try {
      // Try to get from Hive first
      final List<ItemModel> hiveModels = [];
      final List<String> missingIds = [];

      for (String id in itemIds) {
        final hiveModel = HiveSyncHelper.getById(
          box: _hiveBox,
          id: id,
          fromJson: (json) => ItemModel.fromJson(json),
        );
        if (hiveModel != null) {
          hiveModels.add(hiveModel);
        } else {
          missingIds.add(id);
        }
      }

      // If all found in Hive, return them
      if (missingIds.isEmpty) {
        return hiveModels;
      }

      // Fallback to SQLite for missing IDs
      Database db = await _dbHelper.database;
      final placeholders = List.filled(missingIds.length, '?').join(',');
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: '$cId IN ($placeholders)',
        whereArgs: missingIds,
      );

      final sqliteModels = maps.map((map) => ItemModel.fromJson(map)).toList();

      // Combine results
      return [...hiveModels, ...sqliteModels];
    } catch (e) {
      await LogUtils.error('Error getting item models by IDs', e);
      return [];
    }
  }

  // get variantOptionJson by item id
  @override
  Future<String?> getVariantOptionJsonByItemId(String idItem) async {
    List<ItemModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => ItemModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list
          .where((element) => element.id == idItem)
          .firstOrNull
          ?.variantOptionJson;
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [idItem],
    );
    if (maps.isNotEmpty) {
      return maps[0][variantOptionJson];
    } else {
      return null; // Return null if no item is found
    }
  }

  // delete bulk
  @override
  Future<bool> deleteBulk(
    List<ItemModel> listItem, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();
    try {
      for (ItemModel item in listItem) {
        // If we need to insert to pending changes, we need to get the model first
        if (isInsertToPending) {
          // Get the model before deleting it
          List<Map<String, dynamic>> results = await db.query(
            tableName,
            where: '$cId = ?',
            whereArgs: [item.id],
          );

          if (results.isNotEmpty) {
            final model = ItemModel.fromJson(results.first);

            // Insert to pending changes
            final pendingChange = PendingChangesModel(
              operation: 'deleted',
              modelName: ItemModel.modelName,
              modelId: model.id,
              data: jsonEncode(model.toJson()),
            );
            await _pendingChangesRepository.insert(pendingChange);
          }
        }

        batch.delete(tableName, where: '$cId = ?', whereArgs: [item.id]);
      }
      await batch.commit(noResult: true);

      // Delete from Hive box
      for (ItemModel item in listItem) {
        if (item.id != null) {
          await _hiveBox.delete(item.id);
        }
      }

      return true;
    } catch (e) {
      prints('Error deleting bulk item: $e');
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
      prints('Error deleting all item: $e');
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<ItemModel> newData, {
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

  /// Refresh bulk Hive box: replaces all items with provided list, deletes items not in the new list
  ///
  /// This method synchronizes the Hive cache with a new list of items. It:
  /// 1. Creates a map of new items to cache
  /// 2. Identifies items to delete (present in cache but not in new list)
  /// 3. Deletes items not in the new list
  /// 4. Batch puts all new items to Hive box
  /// 5. Queues all items for sync with HiveSyncHelper
  ///
  /// Parameters:
  /// - [list]: List of ItemModel to refresh in Hive box
  /// - [isInsertToPending]: Whether to track changes in pending changes (default: true)
  ///
  /// Returns: true if successful, false otherwise

  @override
  Future<String?> getInventoryIdByItemId(
    String? idItem, {
    required String? variantOptionJson,
  }) async {
    if (idItem == null || idItem.isEmpty) {
      return null;
    }
    List<ItemModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => ItemModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      ItemModel? item =
          list.where((element) => element.id == idItem).firstOrNull;
      if (item != null && item.inventoryId != null) {
        return item.inventoryId;
      } else {
        if (variantOptionJson != null && variantOptionJson.isNotEmpty) {
          dynamic variantOptions = jsonDecode(variantOptionJson);
          VariantOptionModel varOptModel = VariantOptionModel.fromJson(
            variantOptions,
          );
          if (varOptModel.inventoryId != null) {
            return varOptModel.inventoryId;
          }
        }
      }
    }

    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [idItem],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps[0][inventoryId];
    } else {
      if (variantOptionJson != null && variantOptionJson.isNotEmpty) {
        dynamic variantOptions = jsonDecode(variantOptionJson);
        VariantOptionModel varOptModel = VariantOptionModel.fromJson(
          variantOptions,
        );
        return varOptModel.inventoryId;
      } else {
        return null;
      }
    }
  }
}
