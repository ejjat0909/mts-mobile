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
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/repositories/local/local_sale_item_repository_impl.dart';
import 'package:mts/data/repositories/local/local_sale_modifier_repository_impl.dart';
import 'package:mts/data/repositories/local/local_sale_repository_impl.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/sale_modifier_option_repository.dart';
import 'package:sqflite/sqflite.dart';

final saleModifierOptionBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(SaleModifierOptionModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final saleModifierOptionLocalRepoProvider =
    Provider<LocalSaleModifierOptionRepository>((ref) {
      return LocalSaleModifierOptionRepositoryImpl(
        dbHelper: ref.read(databaseHelpersProvider),
        pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
        hiveBox: ref.read(saleModifierOptionBoxProvider),
      );
    });

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalSaleModifierOptionRepositoryImpl] that uses local database
class LocalSaleModifierOptionRepositoryImpl
    implements LocalSaleModifierOptionRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String cId = 'id';
  static const String saleModifierId = 'sale_modifier_id';
  static const String modifierOptionId = 'modifier_option_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String deletedAt = 'deleted_at';
  static const String tableName = 'sale_modifier_options';

  /// Constructor
  LocalSaleModifierOptionRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the sale modifier option table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $saleModifierId TEXT NULL,
      $modifierOptionId TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL,
      $deletedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new sale modifier option
  @override
  Future<int> insert(
    SaleModifierOptionModel saleModifierOption, {
    required bool isInsertToPending,
  }) async {
    saleModifierOption.id ??= IdUtils.generateUUID().toString();
    saleModifierOption.updatedAt = DateTime.now();
    saleModifierOption.createdAt = DateTime.now();
    if (isInsertToPending) {
      PendingChangesModel pcm = PendingChangesModel(
        operation: 'created',
        modelName: SaleModifierOptionModel.modelName,
        modelId: saleModifierOption.id!,
        data: jsonEncode(saleModifierOption.toJson()),
      );
      await _pendingChangesRepository.insert(pcm);
    }
    int result = await _dbHelper.insertDb(
      tableName,
      saleModifierOption.toJson(),
    );
    // Sync to Hive cache
    await _hiveBox.put(saleModifierOption.id, saleModifierOption.toJson());

    return result;
  }

  @override
  Future<int> update(
    SaleModifierOptionModel saleModifierOption, {
    required bool isInsertToPending,
  }) async {
    saleModifierOption.updatedAt = DateTime.now();

    if (isInsertToPending) {
      PendingChangesModel pcm = PendingChangesModel(
        operation: 'updated',
        modelName: SaleModifierOptionModel.modelName,
        modelId: saleModifierOption.id!,
        data: jsonEncode(saleModifierOption.toJson()),
      );
      await _pendingChangesRepository.insert(pcm);
    }
    int result = await _dbHelper.updateDb(
      tableName,
      saleModifierOption.toJson(),
    );
    // Sync to Hive cache
    await _hiveBox.put(saleModifierOption.id, saleModifierOption.toJson());

    return result;
  }

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
        final model = SaleModifierOptionModel.fromJson(results.first);
        PendingChangesModel pcm = PendingChangesModel(
          operation: 'deleted',
          modelName: SaleModifierOptionModel.modelName,
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
      prints('Error deleting record with sale modifier option $id: $e');
      return false;
    }
  }

  @override
  Future<List<SaleModifierOptionModel>>
  getListSaleModifierOptionsBySaleModifierIds(
    List<String> saleModifierIds,
  ) async {
    if (saleModifierIds.isEmpty) {
      return [];
    }

    List<SaleModifierOptionModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: SaleModifierOptionModel.fromJson,
    );

    if (list.isNotEmpty) {
      return list
          .where((element) => saleModifierIds.contains(element.saleModifierId))
          .toList();
    }

    final db = await _dbHelper.database;
    final placeholders = List.filled(saleModifierIds.length, '?').join(',');

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$saleModifierId IN ($placeholders) AND $deletedAt IS NULL',
      whereArgs: saleModifierIds,
    );

    return List.generate(maps.length, (i) {
      return SaleModifierOptionModel.fromJson(maps[i]);
    });
  }

  @override
  Future<List<SaleModifierOptionModel>> getListSaleModifierOption() async {
    List<SaleModifierOptionModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: SaleModifierOptionModel.fromJson,
    );

    if (list.isNotEmpty) {
      return list;
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return SaleModifierOptionModel.fromJson(maps[index]);
    });
  }

  // insert bulk
  @override
  Future<bool> upsertBulk(
    List<SaleModifierOptionModel> list, {
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

      for (SaleModifierOptionModel model in list) {
        if (model.id == null) continue;

        final isExisting = existingIds.contains(model.id);
        final modelJson = model.toJson();

        if (isExisting) {
          // Only update if new item is newer than existing one
          batch.update(
            tableName,
            modelJson,
            where: '$cId = ? AND ($updatedAt IS NULL OR $updatedAt < ?)',
            whereArgs: [
              model.id,
              DateTimeUtils.getDateTimeFormat(model.updatedAt),
            ],
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'updated',
                modelName: SaleModifierOptionModel.modelName,
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
                modelName: SaleModifierOptionModel.modelName,
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
      prints('Error inserting bulk sale modifier option: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getListModifierOptionIds(
    List<String> saleModifierIds,
  ) async {
    if (saleModifierIds.isEmpty) {
      return [];
    }
    List<SaleModifierOptionModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: SaleModifierOptionModel.fromJson,
    );

    if (list.isNotEmpty) {
      return list
          .where((element) => saleModifierIds.contains(element.saleModifierId))
          .map((e) => e.id!)
          .toList();
    }

    Database db = await _dbHelper.database;
    final String ids = saleModifierIds.map((id) => "'$id'").join(',');
    // query
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$saleModifierId IN ($ids)',
    );
    return List.generate(maps.length, (i) {
      return maps[i]['modifier_option_id'] as String;
    });
  }

  @override
  Future<List<SaleModifierOptionModel>> getListSaleModifierOptionModelBySaleId(
    String idSale,
  ) async {
    try {
      // Get list from Hive first
      List<SaleModifierOptionModel> optionsList = HiveSyncHelper.getListFromBox(
        box: _hiveBox,
        fromJson: SaleModifierOptionModel.fromJson,
      );

      if (optionsList.isNotEmpty) {
        // Get sale items from Hive
        List<SaleItemModel> saleItems = HiveSyncHelper.getListFromBox(
          box: _hiveBox,
          fromJson: (json) => SaleItemModel.fromJson(json),
        );

        // Step 1: Filter sale items by saleId
        List<String> saleItemIds =
            saleItems
                .where((item) => item.saleId == idSale)
                .map((item) => item.id!)
                .toList();

        if (saleItemIds.isEmpty) {
          return [];
        }

        // Get sale modifiers from Hive
        List<SaleModifierModel> saleModifiers = HiveSyncHelper.getListFromBox(
          box: _hiveBox,
          fromJson: (json) => SaleModifierModel.fromJson(json),
        );

        // Step 2: Filter sale modifiers by saleItemIds
        List<String> saleModifierIds =
            saleModifiers
                .where((modifier) => saleItemIds.contains(modifier.saleItemId))
                .map((modifier) => modifier.id!)
                .toList();

        if (saleModifierIds.isEmpty) {
          return [];
        }

        // Step 3: Filter sale modifier options by saleModifierIds
        return optionsList
            .where((option) => saleModifierIds.contains(option.saleModifierId))
            .toList();
      }

      // Fall back to database query if Hive is empty
      Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
    SELECT ${LocalSaleModifierOptionRepositoryImpl.tableName}.*
    FROM ${LocalSaleModifierOptionRepositoryImpl.tableName}
    JOIN ${LocalSaleModifierRepositoryImpl.tableName} ON ${LocalSaleModifierOptionRepositoryImpl.tableName}.${LocalSaleModifierOptionRepositoryImpl.saleModifierId} = ${LocalSaleModifierRepositoryImpl.tableName}.$cId
    JOIN ${LocalSaleItemRepositoryImpl.tableName} ON ${LocalSaleModifierRepositoryImpl.tableName}.${LocalSaleModifierRepositoryImpl.cSaleItemId} = ${LocalSaleItemRepositoryImpl.tableName}.${LocalSaleItemRepositoryImpl.cId}
    WHERE ${LocalSaleItemRepositoryImpl.tableName}.${LocalSaleItemRepositoryImpl.saleId} = ?
  ''',
        [idSale],
      );

      // Convert the list of maps into a list of SaleModifierOptionModel
      if (maps.isNotEmpty) {
        return List.generate(maps.length, (index) {
          return SaleModifierOptionModel.fromJson(maps[index]);
        });
      } else {
        return [];
      }
    } catch (e) {
      prints('Error fetching sale modifier options by sale id: $e');
      return [];
    }
  }

  // delete bulk
  @override
  Future<bool> deleteBulk(
    List<SaleModifierOptionModel> saleModifierOptions, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();
    try {
      for (SaleModifierOptionModel saleModifierOption in saleModifierOptions) {
        batch.delete(
          tableName,
          where: 'id = ?',
          whereArgs: [saleModifierOption.id],
        );

        if (isInsertToPending) {
          PendingChangesModel pcm = PendingChangesModel(
            operation: 'deleted',
            modelId: saleModifierOption.id!,
            modelName: SaleModifierOptionModel.modelName,
            data: jsonEncode(saleModifierOption.toJson()),
          );
          await _pendingChangesRepository.insert(pcm);
        }
      }
      await batch.commit(noResult: true);

      // Sync deletions to Hive cache
      await _hiveBox.deleteAll(
        saleModifierOptions
            .where((m) => m.id != null)
            .map((m) => m.id!)
            .toList(),
      );

      return true;
    } catch (e) {
      prints('Error deleting bulk sale modifier option: $e');
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
      prints('Error deleting all sale modifier option: $e');
      return false;
    }
  }

  // @override
  // Future<bool> updateBulk(
  //   List<SaleModifierOptionModel> saleModifierOptions,
  //   bool isInsertToPending,
  // ) async {
  //   Database db = await _dbHelper.database;
  //   Batch batch = db.batch();
  //   try {
  //     for (SaleModifierOptionModel smo in saleModifierOptions) {
  //       batch.update(
  //         tableName,
  //         smo.toJson(), // Convert the model to a map for updating
  //         where: '$cId = ?',
  //         whereArgs: [smo.id],
  //       );

  //       if (isInsertToPending) {
  //         PendingChangesModel pcm = PendingChangesModel(
  //           operation: 'updated',
  //           modelId: smo.id,
  //           modelName: SaleModifierOptionModel.modelName,
  //           data: jsonEncode(smo.toJson()),
  //         );
  //         await _pendingChangesRepository.insert(pcm);
  //       }
  //     }
  //     await batch.commit(noResult: true);
  //     return true;
  //   } catch (e) {
  //     prints('Error updating bulk sale modifier option: $e');
  //     return false;
  //   }
  // }

  @override
  Future<bool> softDeleteSaleModifierOptionsByPredefinedOrderId(
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
        prints('No sales found for predefinedOrderId: $predefinedOrderId');
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
        prints('No sale items found for saleIds: $saleItemIds');
        return false;
      }

      // Step 3: Get all saleModifierIds from the sale_modifiers table based on saleItemIds
      List<Map<String, dynamic>> modifiers = await db.query(
        LocalSaleModifierRepositoryImpl.tableName,
        columns: [LocalSaleModifierRepositoryImpl.cId],
        where:
            '${LocalSaleModifierRepositoryImpl.cSaleItemId} IN (${List.filled(saleItemIds.length, '?').join(', ')})',
        whereArgs: saleItemIds,
      );

      // Extract saleModifierIds from the query result
      List<String> saleModifierIds =
          modifiers
              .map((mod) => mod[LocalSaleModifierRepositoryImpl.cId] as String)
              .toList();

      // If no sale modifiers found, nothing to delete
      if (saleModifierIds.isEmpty) {
        return false;
      }

      // // If we need to track changes in pending changes
      // if (isInsertToPending) {
      //   // Get the modifier options that will be soft deleted
      //   final List<Map<String, dynamic>> modifierOptions = await db.query(
      //     LocalSaleModifierOptionRepositoryImpl.tableName,
      //     where:
      //         '${LocalSaleModifierOptionRepositoryImpl.saleModifierId} IN (${List.filled(saleModifierIds.length, '?').join(', ')})',
      //     whereArgs: saleModifierIds,
      //   );

      //   // Create pending changes for each modifier option
      //   for (var optionMap in modifierOptions) {
      //     final option = SaleModifierOptionModel.fromJson(optionMap);
      //     PendingChangesModel pcm = PendingChangesModel(
      //       operation: 'deleted',
      //       modelId: option.id!,
      //       modelName: SaleModifierOptionModel.modelName,
      //       data: jsonEncode(option.toJson()),
      //     );
      //     await _pendingChangesRepository.insert(pcm);
      //   }
      // }

      // Step 4: Soft delete all entries in sale_modifier_options where saleModifierId matches
      // find the model to update

      final List<Map<String, dynamic>> maps = await db.query(
        LocalSaleModifierOptionRepositoryImpl.tableName,
        where:
            '${LocalSaleModifierOptionRepositoryImpl.saleModifierId} IN (${List.filled(saleModifierIds.length, '?').join(', ')})',
        whereArgs: saleModifierIds,
      );
      List<SaleModifierOptionModel> listModifiersOptionModels = List.generate(
        maps.length,
        (i) {
          return SaleModifierOptionModel.fromJson(maps[i]);
        },
      );

      await Future.wait(
        listModifiersOptionModels.map(
          (model) async => delete(model.id!, isInsertToPending: true),
        ),
      );
      // for (SaleModifierOptionModel model in listModifiersOptionModels) {
      //   await delete(model.id! , isInsertToPending: true);
      // }

      return true; // Return true if any rows were deleted
    } catch (e) {
      prints('Error deleting sale modifier options: $e');
      return false;
    }
  }

  @override
  Future<List<SaleModifierOptionModel>>
  getListSaleModifierOptionsByPredefinedOrderId(
    String predefinedOrderId, {
    required List<String> categoryIds,
  }) async {
    try {
      // Get all data from Hive cache first
      List<SaleModel> allSales = HiveSyncHelper.getListFromBox(
        box: _hiveBox,
        fromJson: (json) => SaleModel.fromJson(json),
      );

      if (allSales.isNotEmpty) {
        // Step 1: Filter sales by predefinedOrderId and chargedAt == null
        List<String> saleIds =
            allSales
                .where(
                  (sale) =>
                      sale.predefinedOrderId == predefinedOrderId &&
                      sale.chargedAt == null,
                )
                .map((sale) => sale.id!)
                .toList();

        if (saleIds.isEmpty) {
          return [];
        }

        // Get all sale items from Hive
        List<SaleItemModel> allSaleItems = HiveSyncHelper.getListFromBox(
          box: _hiveBox,
          fromJson: (json) => SaleItemModel.fromJson(json),
        );

        // Step 2: Filter sale items by saleIds and optionally by categoryIds
        List<SaleItemModel> filteredSaleItems =
            allSaleItems
                .where(
                  (item) =>
                      saleIds.contains(item.saleId) &&
                      (categoryIds.isEmpty ||
                          categoryIds.contains(item.categoryId)),
                )
                .toList();

        if (filteredSaleItems.isEmpty) {
          return [];
        }

        List<String> saleItemIds =
            filteredSaleItems.map((item) => item.id!).toList();

        // Get all sale modifiers from Hive
        List<SaleModifierModel> allSaleModifiers =
            HiveSyncHelper.getListFromBox(
              box: _hiveBox,
              fromJson: (json) => SaleModifierModel.fromJson(json),
            );

        // Step 3: Filter sale modifiers by saleItemIds
        List<String> saleModifierIds =
            allSaleModifiers
                .where((modifier) => saleItemIds.contains(modifier.saleItemId))
                .map((modifier) => modifier.id!)
                .toList();

        if (saleModifierIds.isEmpty) {
          return [];
        }

        // Get all sale modifier options from Hive
        List<SaleModifierOptionModel> allOptions =
            HiveSyncHelper.getListFromBox(
              box: _hiveBox,
              fromJson: SaleModifierOptionModel.fromJson,
            );

        // Step 4: Filter sale modifier options by saleModifierIds
        List<SaleModifierOptionModel> result =
            allOptions
                .where(
                  (option) => saleModifierIds.contains(option.saleModifierId),
                )
                .toList();

        prints('SALE MODIFIER OPTIONS1: ${result.map((e) => e.id!).toList()}');

        return result;
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

      // If no sales found, return an empty list
      if (saleIds.isEmpty) {
        return [];
      }

      // Step 3: Build the SQL query with join
      String query = '''
    SELECT smo.*
    FROM ${LocalSaleModifierOptionRepositoryImpl.tableName} smo
    INNER JOIN ${LocalSaleModifierRepositoryImpl.tableName} sm
    ON smo.${LocalSaleModifierOptionRepositoryImpl.saleModifierId} = sm.${LocalSaleModifierRepositoryImpl.cId}
    INNER JOIN ${LocalSaleItemRepositoryImpl.tableName} si
    ON sm.${LocalSaleModifierRepositoryImpl.cSaleItemId} = si.${LocalSaleItemRepositoryImpl.cId}
    WHERE si.${LocalSaleItemRepositoryImpl.saleId} IN (${List.filled(saleIds.length, '?').join(', ')})
  ''';

      List<dynamic> whereArgs = List<dynamic>.from(saleIds);

      // Add category filter only if categoryIds is not empty
      if (categoryIds.isNotEmpty) {
        query +=
            ' AND si.${LocalSaleItemRepositoryImpl.categoryId} IN (${List.filled(categoryIds.length, '?').join(', ')})';
        whereArgs.addAll(categoryIds);
      }

      // Step 4: Execute the query and fetch sale modifier options
      List<Map<String, dynamic>> saleModifierOptions = await db.rawQuery(
        query,
        whereArgs,
      );

      // Map the query result to a list of SaleModifierOptionModel objects
      List<SaleModifierOptionModel> saleModifierOptionList =
          saleModifierOptions
              .map((option) => SaleModifierOptionModel.fromJson(option))
              .toList();

      prints(
        'SALE MODIFIER OPTIONS2: ${saleModifierOptionList.map((e) => e.id!).toList()}',
      );

      return saleModifierOptionList;
    } catch (e) {
      prints('Error fetching sale modifier options: $e');
      return [];
    }
  }

  // hard delete
  @override
  Future<bool> deleteSaleModifierOptionsByPredefinedOrderId(
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
        prints('No sales found for predefinedOrderId: $predefinedOrderId');
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
        prints('No sale items found for saleIds: $saleItemIds');
        return false;
      }

      // Step 3: Get all saleModifierIds from the sale_modifiers table based on saleItemIds
      List<Map<String, dynamic>> modifiers = await db.query(
        LocalSaleModifierRepositoryImpl.tableName,
        columns: [LocalSaleModifierRepositoryImpl.cId],
        where:
            '${LocalSaleModifierRepositoryImpl.cSaleItemId} IN (${List.filled(saleItemIds.length, '?').join(', ')})',
        whereArgs: saleItemIds,
      );

      // Extract saleModifierIds from the query result
      List<String> saleModifierIds =
          modifiers
              .map((mod) => mod[LocalSaleModifierRepositoryImpl.cId] as String)
              .toList();

      // If no sale modifiers found, nothing to delete
      if (saleModifierIds.isEmpty) {
        return false;
      }

      // // get list smo to delete if we need to track changes
      // if (isInsertToPending) {
      //   List<SaleModifierOptionModel> listSmoToDelete = [];
      //   final List<Map<String, dynamic>> maps = await db.query(
      //     LocalSaleModifierOptionRepositoryImpl.tableName,
      //     where:
      //         '${LocalSaleModifierOptionRepositoryImpl.saleModifierId} IN (${List.filled(saleModifierIds.length, '?').join(', ')})',
      //     whereArgs: saleModifierIds,
      //   );
      //   if (maps.isNotEmpty) {
      //     listSmoToDelete =
      //         maps
      //             .map((option) => SaleModifierOptionModel.fromJson(option))
      //             .toList();

      //     // loop
      //     for (SaleModifierOptionModel smo in listSmoToDelete) {
      //       PendingChangesModel pcm = PendingChangesModel(
      //         operation: 'deleted',
      //         modelId: smo.id!,
      //         modelName: SaleModifierOptionModel.modelName,
      //         data: jsonEncode(smo.toJson()),
      //       );
      //       await _pendingChangesRepository.insert(pcm);
      //     }
      //   }
      // }

      // Step 4: Get all sale modifier options to delete
      final List<Map<String, dynamic>> modifierOptionsToDelete = await db.query(
        LocalSaleModifierOptionRepositoryImpl.tableName,
        where:
            '${LocalSaleModifierOptionRepositoryImpl.saleModifierId} IN (${List.filled(saleModifierIds.length, '?').join(', ')})',
        whereArgs: saleModifierIds,
      );

      if (modifierOptionsToDelete.isEmpty) {
        return false;
      }

      // Convert to SaleModifierOptionModel list
      List<SaleModifierOptionModel> modifierOptionsModels =
          modifierOptionsToDelete
              .map((option) => SaleModifierOptionModel.fromJson(option))
              .toList();

      // Delete all entries using Future.wait with individual delete calls
      List<bool> deleteResults = await Future.wait(
        modifierOptionsModels.map(
          (model) async => delete(model.id!, isInsertToPending: true),
        ),
      );

      // Sync deletions to Hive cache
      await _hiveBox.deleteAll(
        modifierOptionsModels
            .where((m) => m.id != null)
            .map((m) => m.id!)
            .toList(),
      );

      return deleteResults.every((result) => result);
    } catch (e) {
      prints('Error deleting sale modifier options: $e');
      return false;
    }
  }

  @override
  Future<List<SaleModifierOptionModel>>
  getListSaleModifierOptionsByPredefinedOrderIdFilterWithCategory(
    String predefinedOrderId, {
    required List<String> categoryIds,
    required String? saleModifierId,
  }) async {
    try {
      // Get all data from Hive cache first
      List<SaleModel> allSales = HiveSyncHelper.getListFromBox(
        box: _hiveBox,
        fromJson: (json) => SaleModel.fromJson(json),
      );

      if (allSales.isNotEmpty) {
        // Step 1: Filter sales by predefinedOrderId and chargedAt == null
        List<String> saleIds =
            allSales
                .where(
                  (sale) =>
                      sale.predefinedOrderId == predefinedOrderId &&
                      sale.chargedAt == null,
                )
                .map((sale) => sale.id!)
                .toList();

        if (saleIds.isNotEmpty) {
          // Get all sale items from Hive
          List<SaleItemModel> allSaleItems = HiveSyncHelper.getListFromBox(
            box: _hiveBox,
            fromJson: (json) => SaleItemModel.fromJson(json),
          );

          // Step 2: Filter sale items by saleIds
          List<SaleItemModel> filteredSaleItems =
              allSaleItems
                  .where((item) => saleIds.contains(item.saleId))
                  .toList();

          if (filteredSaleItems.isNotEmpty) {
            // Extract categoryIds from filtered sale items if categoryIds is empty
            List<String> workingCategoryIds =
                categoryIds.isNotEmpty
                    ? categoryIds
                    : filteredSaleItems
                        .map((item) => item.categoryId)
                        .where((categoryId) => categoryId != null)
                        .cast<String>()
                        .toSet()
                        .toList();

            // Filter sale items by categoryIds if provided
            List<SaleItemModel> categoryFilteredSaleItems =
                filteredSaleItems
                    .where(
                      (item) =>
                          categoryIds.isEmpty ||
                          workingCategoryIds.contains(item.categoryId),
                    )
                    .toList();

            if (categoryFilteredSaleItems.isNotEmpty) {
              List<String> saleItemIds =
                  categoryFilteredSaleItems.map((item) => item.id!).toList();

              // Get all sale modifiers from Hive
              List<SaleModifierModel> allSaleModifiers =
                  HiveSyncHelper.getListFromBox(
                    box: _hiveBox,
                    fromJson: (json) => SaleModifierModel.fromJson(json),
                  );
              // Step 3: Filter sale modifiers by saleItemIds
              List<String> saleModifierIds =
                  allSaleModifiers
                      .where(
                        (modifier) => saleItemIds.contains(modifier.saleItemId),
                      )
                      .map((modifier) => modifier.id!)
                      .toList();

              if (saleModifierIds.isNotEmpty) {
                // Get all sale modifier options from Hive
                List<SaleModifierOptionModel> allOptions =
                    HiveSyncHelper.getListFromBox(
                      box: _hiveBox,
                      fromJson: SaleModifierOptionModel.fromJson,
                    );

                // Step 4: Filter sale modifier options by saleModifierIds
                List<SaleModifierOptionModel> result =
                    allOptions
                        .where(
                          (option) =>
                              saleModifierIds.contains(option.saleModifierId) &&
                              (saleModifierId == null ||
                                  option.saleModifierId == saleModifierId),
                        )
                        .toList();

                if (result.isNotEmpty) {
                  prints(
                    'SALE MODIFIER OPTIONSS3: ${result.map((e) => e.id!).toList()}',
                  );
                  return result;
                }
              }
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

      // Step 2: Retrieve categoryIds from SaleItemRepository if categoryIds is empty
      List<String> workingCategoryIds = categoryIds;
      if (workingCategoryIds.isEmpty) {
        List<Map<String, dynamic>> categories = await db.query(
          LocalSaleItemRepositoryImpl.tableName,
          columns: [LocalSaleItemRepositoryImpl.categoryId],
          distinct: true,
          where: '''
          ${LocalSaleItemRepositoryImpl.saleId} IN (${List.filled(saleIds.length, '?').join(', ')})
        ''',
          whereArgs: saleIds,
        );

        workingCategoryIds =
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

      // Step 3: Build the SQL query with join
      String query = '''
      SELECT smo.*
      FROM ${LocalSaleModifierOptionRepositoryImpl.tableName} smo
      INNER JOIN ${LocalSaleModifierRepositoryImpl.tableName} sm
      ON smo.${LocalSaleModifierOptionRepositoryImpl.saleModifierId} = sm.${LocalSaleModifierRepositoryImpl.cId}
      INNER JOIN ${LocalSaleItemRepositoryImpl.tableName} si
      ON sm.${LocalSaleModifierRepositoryImpl.cSaleItemId} = si.${LocalSaleItemRepositoryImpl.cId}
      WHERE si.${LocalSaleItemRepositoryImpl.saleId} IN (${List.filled(saleIds.length, '?').join(', ')})
    ''';

      List<dynamic> whereArgs = List<dynamic>.from(saleIds);

      // Add saleModifierId filter if provided
      if (saleModifierId != null) {
        query +=
            ' AND smo.${LocalSaleModifierOptionRepositoryImpl.saleModifierId} = ?';
        whereArgs.add(saleModifierId);
      }

      // Add category filter if categoryIds is not empty
      if (workingCategoryIds.isNotEmpty) {
        query +=
            ' AND si.${LocalSaleItemRepositoryImpl.categoryId} IN (${List.filled(workingCategoryIds.length, '?').join(', ')})';
        whereArgs.addAll(workingCategoryIds);
      }

      // Step 4: Execute the query and fetch sale modifier options
      List<Map<String, dynamic>> saleModifierOptions = await db.rawQuery(
        query,
        whereArgs,
      );

      // Map the query result to a list of SaleModifierOptionModel objects
      List<SaleModifierOptionModel> saleModifierOptionList =
          saleModifierOptions
              .map((option) => SaleModifierOptionModel.fromJson(option))
              .toList();

      prints(
        'SALE MODIFIER OPTIONS4: ${saleModifierOptionList.map((e) => e.id!).toList()}',
      );

      return saleModifierOptionList;
    } catch (e) {
      prints('Error fetching sale modifier options: $e');
      return [];
    }
  }

  @override
  Future<bool> replaceAllData(
    List<SaleModifierOptionModel> newData, {
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
