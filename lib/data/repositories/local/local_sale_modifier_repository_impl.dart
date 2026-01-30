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
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/repositories/local/local_sale_item_repository_impl.dart';
import 'package:mts/data/repositories/local/local_sale_repository_impl.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/sale_modifier_repository.dart';
import 'package:sqflite/sqflite.dart';

final saleModifierBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(SaleModifierModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final saleModifierLocalRepoProvider = Provider<LocalSaleModifierRepository>((
  ref,
) {
  return LocalSaleModifierRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(saleModifierBoxProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalSaleModifierRepository] that uses local database
class LocalSaleModifierRepositoryImpl implements LocalSaleModifierRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String cId = 'id';
  static const String cSaleItemId = 'sale_item_id';
  static const String cModifierId = 'modifier_id';
  static const String cSaleModifierOptionCount = 'sale_modifier_option_count';
  static const String cCreatedAt = 'created_at';
  static const String cUpdatedAt = 'updated_at';
  static const String tableName = 'sale_modifiers';

  /// Constructor
  LocalSaleModifierRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the sale modifier table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $cSaleItemId TEXT NULL,
      $cModifierId TEXT NULL,
      $cSaleModifierOptionCount INTEGER NULL,
      $cCreatedAt TIMESTAMP DEFAULT NULL,
      $cUpdatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new sale modifier
  @override
  Future<int> insert(
    SaleModifierModel saleModifier, {
    required bool isInsertToPending,
  }) async {
    saleModifier.id ??= IdUtils.generateUUID().toString();
    saleModifier.updatedAt = DateTime.now();
    saleModifier.createdAt = DateTime.now();

    // Insert to pending changes if required
    if (isInsertToPending) {
      PendingChangesModel pcm = PendingChangesModel(
        operation: 'created',
        modelName: SaleModifierModel.modelName,
        modelId: saleModifier.id!,
        data: jsonEncode(saleModifier.toJson()),
      );
      await _pendingChangesRepository.insert(pcm);
    }
    int result = await _dbHelper.insertDb(tableName, saleModifier.toJson());
    await _hiveBox.put(saleModifier.id, saleModifier.toJson());
    return result;
  }

  // update
  @override
  Future<int> update(
    SaleModifierModel saleModifier, {
    required bool isInsertToPending,
  }) async {
    saleModifier.updatedAt = DateTime.now();
    if (isInsertToPending) {
      PendingChangesModel pcm = PendingChangesModel(
        operation: 'updated',
        modelName: SaleModifierModel.modelName,
        modelId: saleModifier.id!,
        data: jsonEncode(saleModifier.toJson()),
      );
      await _pendingChangesRepository.insert(pcm);
    }
    int result = await _dbHelper.updateDb(tableName, saleModifier.toJson());
    await _hiveBox.put(saleModifier.id, saleModifier.toJson());

    return result;
  }

  // update bulk
  // @override
  // Future<bool> updateBulk(
  //   List<SaleModifierModel> saleModifiers,
  //   bool isInsertToPending,
  // ) async {
  //   Database db = await _dbHelper.database;
  //   Batch batch = db.batch();
  //   try {
  //     for (SaleModifierModel sm in saleModifiers) {
  //       batch.update(
  //         tableName,
  //         sm.toJson(), // Convert the model to a map for updating
  //         where: '$cId = ?',
  //         whereArgs: [sm.id],
  //       );

  //       if (isInsertToPending) {
  //         PendingChangesModel pcm = PendingChangesModel(
  //           operation: 'updated',
  //           modelName: SaleModifierModel.modelName,
  //           modelId: sm.id!,
  //           data: jsonEncode(sm.toJson()),
  //         );
  //         await _pendingChangesRepository.insert(pcm);
  //       }
  //     }
  //     await batch.commit(noResult: true);

  //     return true;
  //   } catch (e) {
  //     prints('Error updating bulk sale modifier: $e');
  //     return false;
  //   }
  // }

  // delete using id
  @override
  Future<bool> delete(String id, {required bool isInsertToPending}) async {
    try {
      // get the model before delete
      Database db = await _dbHelper.database;
      List<Map<String, dynamic>> results = await db.query(
        tableName,
        where: '$cId = ?',
        whereArgs: [id],
      );

      if (results.isNotEmpty && isInsertToPending) {
        final model = SaleModifierModel.fromJson(results.first);
        PendingChangesModel pcm = PendingChangesModel(
          operation: 'deleted',
          modelName: SaleModifierModel.modelName,
          modelId: model.id,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pcm);
      }
      await _hiveBox.delete(id);
      int result = await _dbHelper.deleteDb(tableName, id);

      // If result is greater than 0, it means the deletion was successful.
      return result > 0;
    } catch (e) {
      // Log the error for debugging purposes.
      prints('Error deleting record with sale modifier $id: $e');
      return false;
    }
  }

  // delete bulk
  @override
  Future<bool> deleteBulk(
    List<SaleModifierModel> saleModifiers, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();
    try {
      for (SaleModifierModel saleModifier in saleModifiers) {
        batch.delete(
          tableName,
          where: '$cId = ?',
          whereArgs: [saleModifier.id],
        );

        if (isInsertToPending) {
          PendingChangesModel pcm = PendingChangesModel(
            operation: 'deleted',
            modelName: SaleModifierModel.modelName,
            modelId: saleModifier.id!,
            data: jsonEncode(saleModifier.toJson()),
          );
          await _pendingChangesRepository.insert(pcm);
        }
      }
      await batch.commit(noResult: true);
      await _hiveBox.deleteAll(
        saleModifiers.where((m) => m.id != null).map((m) => m.id!).toList(),
      );
      return true;
    } catch (e) {
      prints('Error deleting bulk sale modifier: $e');
      return false;
    }
  }

  // delete all
  @override
  Future<bool> deleteAll() async {
    try {
      Database db = await _dbHelper.database;
      await db.delete(tableName);
      // Also clear Hive box
      await _hiveBox.clear();
      return true;
    } catch (e) {
      prints('Error deleting all sale modifier: $e');
      return false;
    }
  }

  // Get sale modifiers by sale item ID and timestamp
  @override
  Future<List<SaleModifierModel>> getListSaleModifiersByItemIdAndTimestamp(
    String idSaleItem,
    DateTime updatedAt,
  ) async {
    List<SaleModifierModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: SaleModifierModel.fromJson,
    );

    if (list.isNotEmpty) {
      return list
          .where(
            (element) =>
                element.saleItemId == idSaleItem &&
                element.updatedAt?.toIso8601String() ==
                    updatedAt.toIso8601String(),
          )
          .toList();
    }
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cSaleItemId = ? AND $cUpdatedAt = ?',
      whereArgs: [idSaleItem, updatedAt.toIso8601String()],
    );

    return List.generate(maps.length, (i) {
      return SaleModifierModel.fromJson(maps[i]);
    });
  }

  // get all
  @override
  Future<List<SaleModifierModel>> getListSaleModifierModel() async {
    List<SaleModifierModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: SaleModifierModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list;
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return SaleModifierModel.fromJson(maps[index]);
    });
  }

  @override
  Future<List<String>> getListSaleModifierIds(String idSaleItem) async {
    if (idSaleItem.isEmpty) {
      return [];
    }
    List<SaleModifierModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: SaleModifierModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list
          .where((element) => element.saleItemId == idSaleItem)
          .map((e) => e.id!)
          .toList();
    }

    Database db = await _dbHelper.database;

    // query
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cSaleItemId = ?',
      whereArgs: [idSaleItem],
    );
    return List.generate(maps.length, (i) {
      return maps[i]['id'] as String;
    });
  }

  @override
  Future<List<SaleModifierModel>> getListSaleModifierModelBySaleId(
    String idSale,
  ) async {
    // Get list from Hive first
    List<SaleModifierModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: SaleModifierModel.fromJson,
    );

    if (list.isNotEmpty) {
      // Get sale items from Hive that belong to this sale
      List<SaleItemModel> saleItems = HiveSyncHelper.getListFromBox(
        box: _hiveBox,
        fromJson: SaleItemModel.fromJson,
      );

      // Extract sale item IDs that belong to this sale
      List<String> saleItemIds =
          saleItems
              .where((item) => item.saleId == idSale)
              .map((item) => item.id!)
              .toList();

      // Filter sale modifiers by sale item IDs
      return list
          .where((modifier) => saleItemIds.contains(modifier.saleItemId))
          .toList();
    }

    // Fall back to database query if Hive is empty
    Database db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
    SELECT ${LocalSaleModifierRepositoryImpl.tableName}.*
    FROM ${LocalSaleModifierRepositoryImpl.tableName}
    JOIN ${LocalSaleItemRepositoryImpl.tableName} ON ${LocalSaleModifierRepositoryImpl.tableName}.${LocalSaleModifierRepositoryImpl.cSaleItemId} = ${LocalSaleItemRepositoryImpl.tableName}.$cId
    WHERE ${LocalSaleItemRepositoryImpl.tableName}.${LocalSaleItemRepositoryImpl.saleId} = ?
  ''',
      [idSale],
    );

    // Convert the list of maps into a list of SaleModifierModel
    if (maps.isNotEmpty) {
      return List.generate(maps.length, (index) {
        return SaleModifierModel.fromJson(maps[index]);
      });
    } else {
      return [];
    }
  }

  // insert bulk
  @override
  Future<bool> upsertBulk(
    List<SaleModifierModel> saleModifiers, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // First, collect all existing IDs in a single query to check for creates vs updates
      // This eliminates the race condition: single query instead of per-item checks
      final idsToInsert =
          saleModifiers.map((m) => m.id).whereType<String>().toList();

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

      for (SaleModifierModel model in saleModifiers) {
        if (model.id == null) continue;

        final isExisting = existingIds.contains(model.id);
        final modelJson = model.toJson();

        if (isExisting) {
          // Only update if new item is newer than existing one
          batch.update(
            tableName,
            modelJson,
            where: '$cId = ? AND ($cUpdatedAt IS NULL OR $cUpdatedAt < ?)',
            whereArgs: [
              model.id,
              DateTimeUtils.getDateTimeFormat(model.updatedAt),
            ],
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'updated',
                modelName: SaleModifierModel.modelName,
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
                modelName: SaleModifierModel.modelName,
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
          saleModifiers
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
      prints('Error inserting bulk sale modifier: $e');
      return false;
    }
  }

  @override
  Future<bool> softDeleteSaleModifiersByPredefinedOrderId(
    String predefinedOrderId,
    // bool isInsertToPending,
  ) async {
    Database db = await _dbHelper.database;
    try {
      // Step 1: Get all sale IDs from the sales table where predefinedOrderId matches
      List<Map<String, dynamic>> sales = await db.query(
        LocalSaleRepositoryImpl.tableName,
        columns: [LocalSaleRepositoryImpl.cId],
        where: '${LocalSaleRepositoryImpl.predefinedOrderId} = ?',
        whereArgs: [predefinedOrderId],
      );

      // Extract sale IDs from the query result
      List<String> saleIds =
          sales
              .map((sale) => sale[LocalSaleRepositoryImpl.cId] as String)
              .toList();

      // If no sales found, nothing to delete
      if (saleIds.isEmpty) {
        return false;
      }

      // Step 2: Get all saleItemIds from the sale_items table based on the saleIds
      List<Map<String, dynamic>> saleItems = await db.query(
        LocalSaleItemRepositoryImpl.tableName,
        columns: [LocalSaleItemRepositoryImpl.cId],
        where:
            '${LocalSaleItemRepositoryImpl.saleId} IN (${List.filled(saleIds.length, '?').join(', ')})',
        whereArgs: saleIds,
      );

      // Extract saleItemIds from the query result
      List<String> saleItemIds =
          saleItems
              .map((item) => item[LocalSaleItemRepositoryImpl.cId] as String)
              .toList();

      // If no sale items found, nothing to delete
      if (saleItemIds.isEmpty) {
        return false;
      }

      // // If we need to track changes in pending changes
      // if (isInsertToPending) {
      //   // Get the modifiers that will be soft deleted
      //   final List<Map<String, dynamic>> saleModifiers = await db.query(
      //     LocalSaleModifierRepositoryImpl.tableName,
      //     where:
      //         '${LocalSaleModifierRepositoryImpl.saleItemId} IN (${List.filled(saleItemIds.length, '?').join(', ')})',
      //     whereArgs: saleItemIds,
      //   );

      //   // Create pending changes for each modifier
      //   for (var modifierMap in saleModifiers) {
      //     final modifier = SaleModifierModel.fromJson(modifierMap);
      //     PendingChangesModel pcm = PendingChangesModel(
      //       operation: 'deleted',
      //       modelName: SaleModifierModel.modelName,
      //       modelId: modifier.id!,
      //       data: jsonEncode(modifier.toJson()),
      //     );
      //     await _pendingChangesRepository.insert(pcm);
      //   }
      // }

      // Step 3: Soft delete sale modifiers where saleItemId matches any of the found saleItemIds
      // find the model to update

      final List<Map<String, dynamic>> maps = await db.query(
        LocalSaleModifierRepositoryImpl.tableName,
        where:
            '${LocalSaleModifierRepositoryImpl.cSaleItemId} IN (${List.filled(saleItemIds.length, '?').join(', ')})',
        whereArgs: saleItemIds,
      );
      List<SaleModifierModel> listSaleModifiers = List.generate(
        maps.length,
        (index) => SaleModifierModel.fromJson(maps[index]),
      );

      await Future.wait(
        listSaleModifiers.map(
          (model) => delete(model.id!, isInsertToPending: true),
        ),
      );
      // for (SaleModifierModel model in listSaleModifiers) {
      //   await delete(model.id! , isInsertToPending: true);
      // }

      // int count = await db.update(
      //   LocalSaleModifierRepositoryImpl.tableName,
      //   {
      //     LocalSaleModifierRepositoryImpl.cDeletedAt:
      //         DateTime.now().toIso8601String(),
      //   },
      //   where:
      //       '${LocalSaleModifierRepositoryImpl.cSaleItemId} IN (${List.filled(saleItemIds.length, '?').join(', ')})',
      //   whereArgs: saleItemIds,
      // );

      return true; // Return true if any rows were deleted
    } catch (e) {
      prints('ERROR soft deleting sale modifiers: $e');
      return false;
    }
  }

  @override
  Future<List<SaleModifierModel>> getListSaleModifiersByPredefinedOrderId(
    String predefinedOrderId,
    List<String> categoryIds,
  ) async {
    try {
      // Get list from Hive first
      List<SaleModifierModel> modifierList = HiveSyncHelper.getListFromBox(
        box: _hiveBox,
        fromJson: SaleModifierModel.fromJson,
      );

      if (modifierList.isNotEmpty) {
        // Get sales from Hive
        List<SaleModel> sales = HiveSyncHelper.getListFromBox(
          box: _hiveBox,
          fromJson: SaleModel.fromJson,
        );

        // Filter sales where predefinedOrderId matches and chargedAt is null
        List<String> saleIds =
            sales
                .where(
                  (sale) =>
                      sale.predefinedOrderId == predefinedOrderId &&
                      sale.chargedAt == null,
                )
                .map((sale) => sale.id!)
                .toList();

        prints('SALEIDS $saleIds');
        prints('categoryIds.ISNOTEMPTY ${categoryIds.isNotEmpty}');

        // If no sales found, return an empty list
        if (saleIds.isEmpty) {
          return [];
        }

        // Get sale items from Hive
        List<SaleItemModel> saleItems = HiveSyncHelper.getListFromBox(
          box: _hiveBox,
          fromJson: (json) => SaleItemModel.fromJson(json),
        );

        // Filter sale items by saleIds and optionally by categoryIds
        List<String> saleItemIds =
            saleItems
                .where((item) {
                  bool saleIdMatches = saleIds.contains(item.saleId);
                  bool categoryIdMatches =
                      categoryIds.isEmpty ||
                      (item.categoryId != null &&
                          categoryIds.contains(item.categoryId));
                  return saleIdMatches && categoryIdMatches;
                })
                .map((item) => item.id!)
                .toList();

        // If no sale items found, return an empty list
        if (saleItemIds.isEmpty) {
          return [];
        }

        // Filter sale modifiers by saleItemIds
        return modifierList
            .where((modifier) => saleItemIds.contains(modifier.saleItemId))
            .toList();
      }

      // Fall back to database query if Hive is empty
      Database db = await _dbHelper.database;
      // Step 1: Get all sale IDs from the sales table where predefinedOrderId matches and chargedAt is null
      List<Map<String, dynamic>> sales = await db.query(
        LocalSaleRepositoryImpl.tableName,
        columns: [LocalSaleRepositoryImpl.cId],
        where: '''
      ${LocalSaleRepositoryImpl.predefinedOrderId} = ? 
      AND ${LocalSaleRepositoryImpl.chargedAt} IS NULL 
    ''',
        whereArgs: [predefinedOrderId],
      );

      // Extract sale IDs from the query result
      List<String> saleIds =
          sales
              .map((sale) => sale[LocalSaleRepositoryImpl.cId] as String)
              .toList();

      prints('SALEIDS $saleIds');
      prints('categoryIds.ISNOTEMPTY ${categoryIds.isNotEmpty}');

      // If no sales found, return an empty list
      if (saleIds.isEmpty) {
        return [];
      }

      // Step 2: Only retrieve sale items if categoryIds is NOT empty
      List<String> saleItemIds = [];
      // Step 3: Get all sale items filtered by categoryIds directly from SaleItemRepository
      String query = '''
        SELECT si.${LocalSaleItemRepositoryImpl.cId}
        FROM ${LocalSaleItemRepositoryImpl.tableName} si
        WHERE si.${LocalSaleItemRepositoryImpl.saleId} IN (${List.filled(saleIds.length, '?').join(', ')})
        ''';

      List<dynamic> whereArgs = List<dynamic>.from(saleIds);

      if (categoryIds.isNotEmpty) {
        query +=
            ' AND si.${LocalSaleItemRepositoryImpl.categoryId} IN (${List.filled(categoryIds.length, '?').join(', ')})';
        whereArgs.addAll(categoryIds);
      }

      List<Map<String, dynamic>> saleItems = await db.rawQuery(
        query,
        whereArgs,
      );

      // Extract saleItemIds from the query result
      saleItemIds =
          saleItems
              .map((item) => item[LocalSaleItemRepositoryImpl.cId] as String)
              .toList();

      // If no sale items found, return an empty list
      if (saleItemIds.isEmpty) {
        return [];
      }

      // Step 4: Get all sale modifiers where saleItemId matches any of the found saleItemIds
      List<Map<String, dynamic>> saleModifiers = await db.query(
        LocalSaleModifierRepositoryImpl.tableName,
        where: '''
      ${LocalSaleModifierRepositoryImpl.cSaleItemId} IN (${List.filled(saleItemIds.length, '?').join(', ')})
    ''',
        whereArgs: saleItemIds,
      );

      // Map the query result to a list of SaleModifierModel objects
      List<SaleModifierModel> saleModifierList =
          saleModifiers
              .map((modifier) => SaleModifierModel.fromJson(modifier))
              .toList();

      return saleModifierList;
    } catch (e) {
      prints('Error fetching sale modifiers: $e');
      return [];
    }
  }

  // get list modifiers not synced

  @override
  Future<bool> deleteSaleModifiersByPredefinedOrderId(
    String predefinedOrderId,
    // bool isInsertToPending,
  ) async {
    Database db = await _dbHelper.database;
    try {
      // Step 1: Get all sale IDs from the sales table where predefinedOrderId matches
      List<Map<String, dynamic>> sales = await db.query(
        LocalSaleRepositoryImpl.tableName,
        columns: [LocalSaleRepositoryImpl.cId],
        where: '${LocalSaleRepositoryImpl.predefinedOrderId} = ?',
        whereArgs: [predefinedOrderId],
      );

      // Extract sale IDs from the query result
      List<String> saleIds =
          sales
              .map((sale) => sale[LocalSaleRepositoryImpl.cId] as String)
              .toList();

      // If no sales found, nothing to delete
      if (saleIds.isEmpty) {
        return false;
      }

      // Step 2: Get all saleItemIds from the sale_items table based on the saleIds
      List<Map<String, dynamic>> saleItems = await db.query(
        LocalSaleItemRepositoryImpl.tableName,
        columns: [LocalSaleItemRepositoryImpl.cId],
        where:
            '${LocalSaleItemRepositoryImpl.saleId} IN (${List.filled(saleIds.length, '?').join(', ')})',
        whereArgs: saleIds,
      );

      // Extract saleItemIds from the query result
      List<String> saleItemIds =
          saleItems
              .map((item) => item[LocalSaleItemRepositoryImpl.cId] as String)
              .toList();

      // If no sale items found, nothing to delete
      if (saleItemIds.isEmpty) {
        return false;
      }

      // Step 3: Get sale modifiers by saleItemIds
      List<Map<String, dynamic>> modifiersMaps = await db.query(
        tableName,
        where:
            '$cSaleItemId IN (${List.filled(saleItemIds.length, '?').join(', ')})',
        whereArgs: saleItemIds,
      );

      // Extract modifier IDs
      List<String> modifierIds =
          modifiersMaps.map((item) => item[cId] as String).toList();

      if (modifierIds.isEmpty) {
        return false;
      }

      // Step 4: Delete sale modifiers using the delete method with Future.wait
      final results = await Future.wait(
        modifierIds.map((id) => delete(id, isInsertToPending: true)),
      );

      // Sync deletions to Hive cache
      await _hiveBox.deleteAll(modifierIds);

      return results.every(
        (result) => result,
      ); // Return true if all deletions succeeded
    } catch (e) {
      prints('ERROR deleting sale modifiers: $e');
      return false;
    }
  }

  @override
  Future<List<SaleModifierModel>>
  getListSaleModifiersByPredefinedOrderIdFilterWithCategory(
    String predefinedOrderId,
    List<String> categoryIds, {
    required String? saleItemId,
  }) async {
    try {
      // Get list from Hive first
      List<SaleModifierModel> modifierList = HiveSyncHelper.getListFromBox(
        box: _hiveBox,
        fromJson: SaleModifierModel.fromJson,
      );

      if (modifierList.isNotEmpty) {
        // Get sales from Hive
        List<SaleModel> sales = HiveSyncHelper.getListFromBox(
          box: _hiveBox,
          fromJson: (json) => SaleModel.fromJson(json),
        );

        // Filter sales where predefinedOrderId matches and chargedAt is null
        List<String> saleIds =
            sales
                .where(
                  (sale) =>
                      sale.predefinedOrderId == predefinedOrderId &&
                      sale.chargedAt == null,
                )
                .map((sale) => sale.id!)
                .toList();

        if (saleIds.isNotEmpty) {
          // Get sale items from Hive
          List<SaleItemModel> saleItems = HiveSyncHelper.getListFromBox(
            box: _hiveBox,
            fromJson: (json) => SaleItemModel.fromJson(json),
          );

          // Filter sale items by saleIds and optionally by categoryIds
          List<String> saleItemIds =
              saleItems
                  .where((item) {
                    bool saleIdMatches = saleIds.contains(item.saleId);
                    bool categoryIdMatches =
                        categoryIds.isEmpty ||
                        (item.categoryId != null &&
                            categoryIds.contains(item.categoryId));
                    return saleIdMatches && categoryIdMatches;
                  })
                  .map((item) => item.id!)
                  .toList();

          if (saleItemIds.isNotEmpty) {
            // Filter sale modifiers by saleItemIds
            List<SaleModifierModel> result =
                modifierList
                    .where(
                      (modifier) =>
                          saleItemIds.contains(modifier.saleItemId) &&
                          (saleItemId == null ||
                              modifier.saleItemId == saleItemId),
                    )
                    .toList();

            if (result.isNotEmpty) {
              return result;
            }
          }
        }
      }

      // Fall back to database query if Hive is empty or filtering resulted in empty list
      Database db = await _dbHelper.database;
      // Step 1: Get all sale IDs from the sales table where predefinedOrderId matches and chargedAt is null
      List<Map<String, dynamic>> sales = await db.query(
        LocalSaleRepositoryImpl.tableName,
        columns: [LocalSaleRepositoryImpl.cId],
        where: '''
      ${LocalSaleRepositoryImpl.predefinedOrderId} = ? 
      AND ${LocalSaleRepositoryImpl.chargedAt} IS NULL 
    ''',
        whereArgs: [predefinedOrderId],
      );

      // Extract sale IDs from the query result
      List<String> saleIds =
          sales
              .map((sale) => sale[LocalSaleRepositoryImpl.cId] as String)
              .toList();

      // If no sales found, return an empty list
      if (saleIds.isEmpty) {
        return [];
      }

      // Step 2: Get all sale items filtered by categoryIds directly from SaleItemRepository
      String query = '''
        SELECT si.${LocalSaleItemRepositoryImpl.cId}
        FROM ${LocalSaleItemRepositoryImpl.tableName} si
        WHERE si.${LocalSaleItemRepositoryImpl.saleId} IN (${List.filled(saleIds.length, '?').join(', ')})
        ''';

      List<dynamic> whereArgs = List<dynamic>.from(saleIds);

      if (saleItemId != null) {
        query += ' AND si.${LocalSaleItemRepositoryImpl.cId} = ?';
        whereArgs.add(saleItemId);
      }

      if (categoryIds.isNotEmpty) {
        query +=
            ' AND si.${LocalSaleItemRepositoryImpl.categoryId} IN (${List.filled(categoryIds.length, '?').join(', ')})';
        whereArgs.addAll(categoryIds);
      }

      List<Map<String, dynamic>> saleItems = await db.rawQuery(
        query,
        whereArgs,
      );

      // Extract saleItemIds from the query result
      List<String> saleItemIds =
          saleItems
              .map((item) => item[LocalSaleItemRepositoryImpl.cId] as String)
              .toList();

      // If no sale items found, return an empty list
      if (saleItemIds.isEmpty) {
        return [];
      }

      // Step 3: Get all sale modifiers where saleItemId matches any of the found saleItemIds
      List<Map<String, dynamic>> saleModifiers = await db.query(
        tableName,
        where: '''
      $cSaleItemId IN (${List.filled(saleItemIds.length, '?').join(', ')})
    ''',
        whereArgs: saleItemIds,
      );

      // Map the query result to a list of SaleModifierModel objects
      List<SaleModifierModel> saleModifierList =
          saleModifiers
              .map((modifier) => SaleModifierModel.fromJson(modifier))
              .toList();

      return saleModifierList;
    } catch (e) {
      prints('Error fetching sale modifiers: $e');
      return [];
    }
  }

  /// Replace all data in the table with new data
  @override
  Future<bool> replaceAllData(
    List<SaleModifierModel> newData, {
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
}
