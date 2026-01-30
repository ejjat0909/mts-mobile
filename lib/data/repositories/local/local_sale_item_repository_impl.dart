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
import 'package:mts/data/repositories/local/local_sale_repository_impl.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/sale_item_repository.dart';
import 'package:mts/domain/repositories/local/sale_repository.dart';
import 'package:sqflite/sqflite.dart';

final saleModifierBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(SaleItemModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final saleItemLocalRepoProvider = Provider<LocalSaleItemRepository>((ref) {
  return LocalSaleItemRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(saleModifierBoxProvider),
    saleRepository: ref.read(saleLocalRepoProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalSaleItemRepository] that uses local database
class LocalSaleItemRepositoryImpl implements LocalSaleItemRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;
  final LocalSaleRepository _saleRepository;

  /// Database table and column names
  static const String cId = 'id';
  static const String itemId = 'item_id';
  static const String categoryId = 'category_id';
  static const String saleId = 'sale_id';
  static const String taxId = 'tax_id';
  static const String discountId = 'discount_id';
  static const String variantOptionId = 'variant_option_id';
  static const String price = 'price';
  static const String quantity = 'quantity';
  static const String inventoryId = 'inventory_id';
  static const String cost = 'cost';
  static const String comments = 'comments';
  static const String soldBy = 'sold_by';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String isVoided = 'is_voided';
  static const String isPrintedVoided = 'is_printed_voided';
  static const String isPrintedKitchen = 'is_printed_kitchen';
  static const String variantOptionJson = 'variant_option_json';
  static const String discountTotal = 'discount_total';
  static const String taxAfterDiscount = 'tax_after_discount';
  static const String taxIncludedAfterDiscount = 'tax_included_after_discount';
  static const String totalAfterDiscAndTax = 'total_after_disc_and_tax';
  static const String saleModifierCount = 'sale_modifier_count';

  static const String tableName = 'sale_items';

  /// Constructor
  LocalSaleItemRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
    required LocalSaleRepository saleRepository,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox,
       _saleRepository = saleRepository;

  /// Create the sale item table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $itemId TEXT NULL,
      $categoryId TEXT NULL,
      $saleId TEXT NULL,
      $taxId TEXT NULL,
      $discountId TEXT NULL,
      $inventoryId TEXT NULL,
      $variantOptionId TEXT NULL,
      $variantOptionJson TEXT NULL,
      $price FLOAT NULL,
      $quantity FLOAT NULL,
      $cost FLOAT NULL,
      $comments TEXT NULL,
      $soldBy TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL,
      $discountTotal FLOAT NULL,
      $taxAfterDiscount FLOAT NULL,
      $taxIncludedAfterDiscount FLOAT NULL,
      $totalAfterDiscAndTax FLOAT NULL,
      $saleModifierCount INTEGER NULL,
      $isVoided INTEGER DEFAULT 0,
      $isPrintedVoided INTEGER DEFAULT 0,
      $isPrintedKitchen INTEGER DEFAULT 0
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new sale item
  @override
  Future<int> insert(
    SaleItemModel saleItemModel, {
    required bool isInsertToPending,
  }) async {
    saleItemModel.updatedAt = DateTime.now();
    saleItemModel.createdAt = DateTime.now();

    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'created',
        modelName: SaleItemModel.modelName,
        modelId: saleItemModel.id!,
        createdAt: DateTime.now(),
        data: jsonEncode(saleItemModel.toJson()),
        id: IdUtils.generateUUID(),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    int result = await _dbHelper.insertDb(tableName, saleItemModel.toJson());
    // Sync to Hive cache
    await _hiveBox.put(saleItemModel.id, saleItemModel.toJson());

    return result;
  }

  // update
  @override
  Future<int> update(
    SaleItemModel saleItemModel, {
    required bool isInsertToPending,
  }) async {
    saleItemModel.updatedAt = DateTime.now();

    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: SaleItemModel.modelName,
        modelId: saleItemModel.id!,
        createdAt: DateTime.now(),
        data: jsonEncode(saleItemModel.toJson()),
        id: IdUtils.generateUUID(),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    int result = await _dbHelper.updateDb(tableName, saleItemModel.toJson());
    // Sync to Hive cache
    await _hiveBox.put(saleItemModel.id, saleItemModel.toJson());

    return result;
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
      final model = SaleItemModel.fromJson(results.first);

      // Delete the record
      await _hiveBox.delete(id);
      int result = await _dbHelper.deleteDb(tableName, id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: SaleItemModel.modelName,
          modelId: model.id!,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No sale item record found with id: $id');
      return 0;
    }
  }

  // get list SaleITem
  @override
  Future<List<SaleItemModel>> getListSaleItem() async {
    List<SaleItemModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: SaleItemModel.fromJson,
    );

    if (list.isNotEmpty) {
      return list;
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return SaleItemModel.fromJson(maps[index]);
    });
  }

  @override
  Future<List<SaleItemModel>> getListSaleItemBySaleIdWhereIsVoidedTrue(
    List<String> listIdSale,
  ) async {
    if (listIdSale.isEmpty) {
      return []; // Return an empty list if no IDs are provided
    }

    List<SaleItemModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => SaleItemModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list
          .where(
            (item) => listIdSale.contains(item.saleId) && item.isVoided == true,
          )
          .toList();
    }

    Database db = await _dbHelper.database;

    // Generate placeholders for the IN clause
    String placeholders = List.filled(listIdSale.length, '?').join(',');

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$saleId IN ($placeholders) AND $isVoided = 1',
      whereArgs: listIdSale,
    );

    return List.generate(maps.length, (index) {
      return SaleItemModel.fromJson(maps[index]);
    });
  }

  // get list sale items that same with sale id
  @override
  Future<List<SaleItemModel>> getListSaleItemBySaleIds(
    List<String> listIdSale,
  ) async {
    if (listIdSale.isEmpty) {
      return []; // Return an empty list if no IDs are provided
    }

    List<SaleItemModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: SaleItemModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list.where((item) => listIdSale.contains(item.saleId)).toList();
    }

    Database db = await _dbHelper.database;

    // Generate placeholders for the IN clause
    String placeholders = List.filled(listIdSale.length, '?').join(',');

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$saleId IN ($placeholders)',
      whereArgs: listIdSale,
    );

    return List.generate(maps.length, (index) {
      return SaleItemModel.fromJson(maps[index]);
    });
  }

  @override
  Future<List<SaleItemModel>> getListSaleItemBasedOnSaleId(
    String idSale,
  ) async {
    List<SaleItemModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: SaleItemModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list.where((item) => item.saleId == idSale).toList();
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$saleId = ?',
      whereArgs: [idSale],
    );
    return List.generate(maps.length, (index) {
      return SaleItemModel.fromJson(maps[index]);
    });
  }

  // insert bulk
  @override
  Future<bool> upsertBulk(
    List<SaleItemModel> saleItemModels, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // First, collect all existing IDs in a single query to check for creates vs updates
      // This eliminates the race condition: single query instead of per-item checks
      final idsToInsert =
          saleItemModels.map((m) => m.id).whereType<String>().toList();

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

      for (SaleItemModel model in saleItemModels) {
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
                modelName: SaleItemModel.modelName,
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
                modelName: SaleItemModel.modelName,
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
          saleItemModels
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
      prints('Error inserting bulk sale item: $e');
      return false;
    }
  }

  // delete bulk
  @override
  Future<bool> deleteBulk(
    List<SaleItemModel> saleItemModels, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();
    try {
      // Insert to pending changes for each model before deleting if required
      if (isInsertToPending) {
        for (SaleItemModel saleItemModel in saleItemModels) {
          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: SaleItemModel.modelName,
            modelId: saleItemModel.id!,
            data: jsonEncode(saleItemModel.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }

      for (SaleItemModel saleItemModel in saleItemModels) {
        batch.delete(
          tableName,
          where: '$cId = ?',
          whereArgs: [saleItemModel.id],
        );
      }
      await batch.commit(noResult: true);

      // Sync deletions to Hive cache
      await _hiveBox.deleteAll(
        saleItemModels.where((m) => m.id != null).map((m) => m.id!).toList(),
      );

      return true;
    } catch (e) {
      prints('Error deleting bulk sale item: $e');
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
      prints('Error deleting all sale items: $e');
      return false;
    }
  }

  // @override
  // Future<bool> updateBulk(
  //   List<SaleItemModel> saleItemModels,
  //   bool isInsertToPending,
  // ) async {
  //   Database db = await _dbHelper.database;
  //   Batch batch = db.batch();
  //   try {
  //     for (SaleItemModel saleItemModel in saleItemModels) {
  //       batch.update(
  //         tableName,
  //         saleItemModel.toJson(), // Convert the model to a map for updating
  //         where: '$cId = ?',
  //         whereArgs: [saleItemModel.id],
  //       );

  //       // Insert to pending changes if required
  //       if (isInsertToPending) {
  //         PendingChangesModel pcm = PendingChangesModel(
  //           operation: 'updated',
  //           modelName: SaleItemModel.modelName,
  //           modelId: saleItemModel.id!,
  //           data: jsonEncode(saleItemModel.toJson()),
  //         );
  //         await _pendingChangesRepository.insert(pcm);
  //       }
  //     }
  //     await batch.commit(noResult: true);
  //     return true;
  //   } catch (e) {
  //     prints('Error updating bulk sale items: $e');
  //     return false;
  //   }
  // }

  @override
  Future<List<SaleItemModel>> getListSaleItemByPredefinedOrderId(
    String predefinedOrderId,
    bool? isVoided, // Changed to nullable bool
    bool? isPrintedKitchen,
    List<String> categoryIds,
  ) async {
    Database db = await _dbHelper.database;

    try {
      // Step 1: Get all sale IDs from the sales table where predefinedOrderId matches and deletedAt is null
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

      // Step 2: Build the SQL query without the join to ItemRepository
      String query = '''
    SELECT si.*
    FROM ${LocalSaleItemRepositoryImpl.tableName} si
    WHERE si.${LocalSaleItemRepositoryImpl.saleId} IN (${List.filled(saleIds.length, '?').join(', ')})
  ''';

      List<dynamic> whereArgs = List<dynamic>.from(saleIds);

      // Add isVoided filter only if isVoided is not null
      if (isVoided != null) {
        int isVoidedInt = isVoided ? 1 : 0;
        query += ' AND si.${LocalSaleItemRepositoryImpl.isVoided} = ?';
        whereArgs.add(isVoidedInt);
      }

      if (isPrintedKitchen != null) {
        int isPrintedKitchenInt = isPrintedKitchen ? 1 : 0;
        query += ' AND si.${LocalSaleItemRepositoryImpl.isPrintedKitchen} = ?';
        whereArgs.add(isPrintedKitchenInt);
      }
      // If isVoided is null, we don't filter by isVoided status (return both voided and non-voided items)

      // Add category filter only if categoryIds is not empty
      if (categoryIds.isNotEmpty) {
        query +=
            ' AND si.${LocalSaleItemRepositoryImpl.categoryId} IN (${List.filled(categoryIds.length, '?').join(', ')})';
        whereArgs.addAll(categoryIds);
      }

      // Step 3: Execute the query and fetch sale items
      List<Map<String, dynamic>> saleItems = await db.rawQuery(
        query,
        whereArgs,
      );

      // Map the query result to a list of SaleItemModel objects
      List<SaleItemModel> saleItemList =
          saleItems.map((item) => SaleItemModel.fromJson(item)).toList();

      return saleItemList;
    } catch (e) {
      prints('Error fetching sale items by predefinedOrderId: $e');
      return [];
    }
  }

  @override
  Future<List<SaleItemModel>> getListSaleItemByOneSaleId(
    String idSale,
    bool? isVoided, // Changed to nullable bool
    bool? isPrintedKitchen,
    List<String> categoryIds,
  ) async {
    Database db = await _dbHelper.database;

    try {
      // Step 1: Get all sale IDs from the sales table where predefinedOrderId matches and deletedAt is null
      List<Map<String, dynamic>> sales = await db.query(
        LocalSaleRepositoryImpl.tableName,
        columns: [LocalSaleRepositoryImpl.cId],
        where: '''
      ${LocalSaleRepositoryImpl.cId} = ? 
      AND ${LocalSaleRepositoryImpl.chargedAt} IS NULL 
    ''',
        whereArgs: [idSale],
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

      // Step 2: Build the SQL query without the join to ItemRepository
      String query = '''
    SELECT si.*
    FROM ${LocalSaleItemRepositoryImpl.tableName} si
    WHERE si.${LocalSaleItemRepositoryImpl.saleId} IN (${List.filled(saleIds.length, '?').join(', ')})
  ''';

      List<dynamic> whereArgs = List<dynamic>.from(saleIds);

      // Add isVoided filter only if isVoided is not null
      if (isVoided != null) {
        int isVoidedInt = isVoided ? 1 : 0;
        query += ' AND si.${LocalSaleItemRepositoryImpl.isVoided} = ?';
        whereArgs.add(isVoidedInt);
      }

      if (isPrintedKitchen != null) {
        int isPrintedKitchenInt = isPrintedKitchen ? 1 : 0;
        query += ' AND si.${LocalSaleItemRepositoryImpl.isPrintedKitchen} = ?';
        whereArgs.add(isPrintedKitchenInt);
      }
      // If isVoided is null, we don't filter by isVoided status (return both voided and non-voided items)

      // Add category filter only if categoryIds is not empty
      if (categoryIds.isNotEmpty) {
        query +=
            ' AND si.${LocalSaleItemRepositoryImpl.categoryId} IN (${List.filled(categoryIds.length, '?').join(', ')})';
        whereArgs.addAll(categoryIds);
      }

      // Step 3: Execute the query and fetch sale items
      List<Map<String, dynamic>> saleItems = await db.rawQuery(
        query,
        whereArgs,
      );

      // Map the query result to a list of SaleItemModel objects
      List<SaleItemModel> saleItemList =
          saleItems.map((item) => SaleItemModel.fromJson(item)).toList();

      return saleItemList;
    } catch (e) {
      prints('Error fetching sale items by predefinedOrderId: $e');
      return [];
    }
  }

  @override
  Future<SaleItemModel> getSaleItemById(String idSale) async {
    Database db = await _dbHelper.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: '$cId = ?',
        whereArgs: [idSale],
      );
      if (maps.isNotEmpty) {
        return SaleItemModel.fromJson(maps.first);
      } else {
        return SaleItemModel();
      }
    } catch (e) {
      prints('Error fetching sale item by id: $e');
      return SaleItemModel();
    }
  }

  @override
  Future<bool> deleteSaleItemWhereSaleId(String idSale) async {
    try {
      final saleItems = await getListSaleItemBasedOnSaleId(idSale);

      if (saleItems.isEmpty) {
        return true;
      }

      for (final saleItem in saleItems) {
        if (saleItem.id != null) {
          await delete(saleItem.id!, isInsertToPending: true);
        }
      }

      return true;
    } catch (e) {
      prints('Error deleting sale items by sale id: $e');
      return false;
    }
  }

  @override
  Future<List<SaleItemModel>>
  getListSaleItemByPredefinedOrderIdFilterWithCategory(
    String predefinedOrderId,
    bool isVoided,
    List<String> categoryIds,
  ) async {
    Database db = await _dbHelper.database;
    int isVoidedInt = isVoided ? 1 : 0;

    try {
      // Step 1: Get all sale IDs from the sales table where predefinedOrderId matches and deletedAt is null
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

      // Step 2: Retrieve categoryIds from LocalSaleItemRepositoryImpl if categoryIds is empty
      if (categoryIds.isEmpty) {
        List<Map<String, dynamic>> categories = await db.query(
          LocalSaleItemRepositoryImpl.tableName,
          columns: [LocalSaleItemRepositoryImpl.categoryId],
          distinct: true,
          where: '''
          ${LocalSaleItemRepositoryImpl.saleId} IN (${List.filled(saleIds.length, '?').join(', ')})
        ''',
          whereArgs: saleIds,
        );

        categoryIds =
            categories
                .map(
                  (category) =>
                      category[LocalSaleItemRepositoryImpl.categoryId]
                          as String?,
                )
                .where((categoryId) => categoryId != null)
                .cast<String>()
                .toList();
      }

      // Step 3: Build the SQL query without the join to ItemRepository
      String query = '''
      SELECT si.*
      FROM ${LocalSaleItemRepositoryImpl.tableName} si
      WHERE si.${LocalSaleItemRepositoryImpl.saleId} IN (${List.filled(saleIds.length, '?').join(', ')})
      AND si.${LocalSaleItemRepositoryImpl.isVoided} = ?
    ''';

      List<dynamic> whereArgs = List<dynamic>.from(saleIds)..add(isVoidedInt);

      // Add category filter only if categoryIds is not empty
      if (categoryIds.isNotEmpty) {
        query +=
            ' AND si.${LocalSaleItemRepositoryImpl.categoryId} IN (${List.filled(categoryIds.length, '?').join(', ')})';
        whereArgs.addAll(categoryIds);
      }

      // Step 4: Execute the query and fetch sale items
      List<Map<String, dynamic>> saleItems = await db.rawQuery(
        query,
        whereArgs,
      );

      // Map the query result to a list of SaleItemModel objects
      List<SaleItemModel> saleItemList =
          saleItems.map((item) => SaleItemModel.fromJson(item)).toList();

      return saleItemList;
    } catch (e) {
      prints('Error fetching sale items by predefinedOrderId: $e');
      return [];
    }
  }

  @override
  Future<bool> replaceAllData(
    List<SaleItemModel> newData, {
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
  Future<int> deleteSaleItemWhereStaffIdNull() async {
    Database db = await _dbHelper.database;
    List<int> listSuccess = [];

    // get sales where staff id is null

    List<SaleModel> listSales =
        await _saleRepository.getListSalesWhereStaffIdNull();

    if (listSales.isEmpty) {
      return 0;
    }

    for (SaleModel sale in listSales) {
      // delete sale items where sale id is in listSales
      final delete = await db.delete(
        tableName,
        where: '$saleId = ?',
        whereArgs: [sale.id],
      );
      listSuccess.add(delete);
    }

    if (listSuccess.every((element) => element == 1)) {
      return 1; // All deletes were successful
    } else {
      return 0; // At least one delete failed
    }
  }

  /// Refresh Hive box with new sale items, deleting items not in the new list
  ///
  /// This method replaces the entire Hive cache with a new set of sale items.
  /// It identifies stale cache entries and removes them, then bulk-inserts new data
  /// and queues all items for background synchronization.
  ///
  /// Parameters:
  /// - [list]: The new list of SaleItemModel objects to cache
  /// - [isInsertToPending]: Whether to queue items for sync (default: true)
  ///
  /// Returns: true if successful, false otherwise
}
