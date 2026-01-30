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
import 'package:mts/data/models/page_item/page_item_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/page_item_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mts/core/storage/hive_box_manager.dart';

final pageItemBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(PageItemModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final pageItemLocalRepoProvider = Provider<LocalPageItemRepository>((ref) {
  return LocalPageItemRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(pageItemBoxProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalPageItemRepository] that uses local database
class LocalPageItemRepositoryImpl implements LocalPageItemRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String cId = 'id';
  static const String pageId = 'page_id';
  static const String pageItemableId = 'page_itemable_id';
  static const String pageItemableType = 'page_itemable_type';
  static const String sort = 'sort';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String tableName = 'page_items';

  /// Constructor
  LocalPageItemRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the page item table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $pageId TEXT NULL,
      $pageItemableId TEXT NULL,
      $pageItemableType TEXT NULL,
      $sort INTEGER NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  @override
  Future<int> insert(
    PageItemModel pageItemModel, {
    required bool isInsertToPending,
  }) async {
    pageItemModel.id ??= IdUtils.generateUUID().toString();
    pageItemModel.updatedAt = DateTime.now();
    pageItemModel.createdAt = DateTime.now();

    try {
      // Insert to SQLite
      int result = await _dbHelper.insertDb(tableName, pageItemModel.toJson());

      // Insert to Hive
      await _hiveBox.put(pageItemModel.id!, pageItemModel.toJson());

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'created',
          modelName: PageItemModel.modelName,
          modelId: pageItemModel.id!,
          data: jsonEncode(pageItemModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error inserting page item', e);
      rethrow;
    }
  }

  /// Delete any existing items with the same sort value and pageId
  // Future<void> _deleteItemsWithSameSortAndPageId(
  //   int? sortValue,
  //   String? pageIdValue,
  //   bool isInsertToPending,
  // ) async {
  //   if (sortValue == null || pageIdValue == null) return;

  //   Database db = await _dbHelper.database;

  //   List<Map<String, dynamic>> existingItems = await db.query(
  //     tableName,
  //     where: '$sort = ? AND $pageId = ?',
  //     whereArgs: [sortValue, pageIdValue],
  //   );

  //   // If there are existing items with the same sort and pageId, delete them
  //   if (existingItems.isNotEmpty) {
  //     for (var existingItem in existingItems) {
  //       String existingId = existingItem[cId];

  //       // Delete the existing item using the existing delete method
  //       // This will handle pending changes automatically
  //       await delete(existingId, isInsertToPending: isInsertToPending);
  //     }
  //   }
  // }

  @override
  Future<int> update(
    PageItemModel pageItemModel, {
    required bool isInsertToPending,
  }) async {
    pageItemModel.updatedAt = DateTime.now();

    try {
      // Update SQLite
      int result = await _dbHelper.updateDb(tableName, pageItemModel.toJson());

      // Update Hive
      await _hiveBox.put(pageItemModel.id!, pageItemModel.toJson());

      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'updated',
          modelName: PageItemModel.modelName,
          modelId: pageItemModel.id!,
          data: jsonEncode(pageItemModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error updating page item', e);
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
      final model = PageItemModel.fromJson(results.first);

      // Delete from Hive
      await _hiveBox.delete(id);

      // Delete the record
      int result = await _dbHelper.deleteDb(tableName, id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: PageItemModel.modelName,
          modelId: model.id,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No page item record found with id: $id');
      return 0;
    }
  }

  @override
  Future<int> deleteDbWithConditions(
    String tableName,
    Map<String, dynamic> conditions, {
    required bool isInsertToPending,
  }) async {
    // If we need to insert to pending changes, we need to get the models first

    Database db = await _dbHelper.database;

    // Build the WHERE clause and arguments
    String whereClause = conditions.keys.map((key) => '$key = ?').join(' AND ');
    List<dynamic> whereArgs = conditions.values.toList();

    // Get the records that will be deleted
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );

    // Insert pending changes for each record
    for (var record in results) {
      final model = PageItemModel.fromJson(record);
      await _hiveBox.delete(model.id!);
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: PageItemModel.modelName,
          modelId: model.id!,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }
    }

    // await removeFromHiveBoxWithCondition(conditions);
    return await _dbHelper.deleteDbWithConditions(tableName, conditions);
  }

  // get list page item with conditions
  @override
  Future<List<PageItemModel>> getListPageItemsWithConditions(
    Map<String, dynamic> conditions,
  ) async {
    final list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => PageItemModel.fromJson(json),
    );

    if (list.isNotEmpty) {
      return list.where((pi) {
        return conditions.entries.every((condition) {
          return condition.value == pi.toJson()[condition.key];
        });
      }).toList();
    }
    Database db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: conditions.keys.map((key) => '$key = ?').join(' AND '),
      whereArgs: conditions.values.toList(),
    );
    return List.generate(maps.length, (index) {
      return PageItemModel.fromJson(maps[index]);
    });
  }

  // get list
  @override
  Future<List<PageItemModel>> getListPageItemModel() async {
    List<PageItemModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => PageItemModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list;
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return PageItemModel.fromJson(maps[index]);
    });
  }

  // insert bulk
  @override
  Future<bool> upsertBulk(
    List<PageItemModel> list, {
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

      for (PageItemModel model in list) {
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
                modelName: PageItemModel.modelName,
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
                modelName: PageItemModel.modelName,
                modelId: model.id!,
                data: jsonEncode(modelJson),
              ),
            );
          }
        }
      }

      // Commit batch atomically
      await batch.commit(noResult: true);

      // Track pending changes AFTER successful batch commit
      // This ensures we only track changes that actually succeeded
      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      prints('Error inserting bulk page item: $e');
      return false;
    }
  }

  /// Remove duplicates from list based on sort and pageId, keeping the most recently updated
  // List<PageItemModel> _removeDuplicatesBySortAndPageId(
  //   List<PageItemModel> list,
  // ) {
  //   Map<String, PageItemModel> uniqueItems = {};

  //   for (PageItemModel item in list) {
  //     // Skip items with null sort or pageId
  //     if (item.sort == null || item.pageId == null) {
  //       // For items without sort or pageId, treat them as unique based on their ID
  //       String key = item.id ?? IdUtils.generateUUID().toString();
  //       uniqueItems[key] = item;
  //       continue;
  //     }

  //     // Create a key combining sort and pageId
  //     String key = '${item.sort}_${item.pageId}';

  //     // If this key doesn't exist or current item is more recently updated
  //     if (!uniqueItems.containsKey(key) ||
  //         (item.updatedAt?.isAfter(
  //               uniqueItems[key]!.updatedAt ?? DateTime.now(),
  //             ) ??
  //             false)) {
  //       uniqueItems[key] = item;
  //     }
  //   }

  //   return uniqueItems.values.toList();
  // }

  @override
  Future<bool> deleteBulk(
    List<PageItemModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    try {
      // If we need to insert to pending changes, we need to get the models first
      if (isInsertToPending) {
        for (PageItemModel item in list) {
          List<Map<String, dynamic>> results = await db.query(
            tableName,
            where: '$cId = ?',
            whereArgs: [item.id],
          );

          if (results.isNotEmpty) {
            final model = PageItemModel.fromJson(results.first);

            // Insert to pending changes
            final pendingChange = PendingChangesModel(
              operation: 'deleted',
              modelName: PageItemModel.modelName,
              modelId: model.id!,
              data: jsonEncode(model.toJson()),
            );
            await _pendingChangesRepository.insert(pendingChange);
          }
        }
      }

      // Now delete the records
      for (PageItemModel item in list) {
        batch.delete(tableName, where: '$cId = ?', whereArgs: [item.id]);
      }

      await batch.commit(noResult: true);
      return true;
    } catch (e) {
      prints('Error deleting bulk page item: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      // If we need to insert to pending changes, get all records first

      List<Map<String, dynamic>> results = await db.query(tableName);

      // Insert pending changes for each record
      for (var record in results) {
        final model = PageItemModel.fromJson(record);

        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: PageItemModel.modelName,
          modelId: model.id!,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }
      await _hiveBox.clear();
      await db.delete(tableName);

      return true;
    } catch (e) {
      prints('Error deleting all page item: $e');
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<PageItemModel> newData, {
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

  // for database clean up
  @override
  Future<List<String>> getAllPageIds() async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(tableName);
    List<String> list = [];
    for (var element in maps) {
      list.add(element[pageId]);
    }
    return list;
  }

  @override
  Future<bool> deletePageItemsByPageId(String idPage) async {
    Database db = await _dbHelper.database;

    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$pageId = ?',
      whereArgs: [idPage],
    );

    for (var element in maps) {
      final model = PageItemModel.fromJson(element);
      await _hiveBox.delete(model.id!);
      await delete(model.id!, isInsertToPending: true);
    }
    return true;
  }
}
