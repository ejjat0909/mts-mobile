import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/repositories/local/local_discount_item_repository_impl.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/data/datasources/local/pivot_element.dart';
import 'package:mts/data/models/discount_sale_item/discount_sale_item_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/discount_sale_item_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

final discountSaleItemBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(DiscountSaleItemModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final discountSaleItemLocalRepoProvider =
    Provider<LocalDiscountSaleItemRepository>((ref) {
      return LocalDiscountSaleItemRepositoryImpl(
        dbHelper: ref.read(databaseHelpersProvider),
        pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
        hiveBox: ref.read(discountItemBoxProvider),
      );
    });

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalDiscountSaleItemRepository] that uses local database
class LocalDiscountSaleItemRepositoryImpl
    implements LocalDiscountSaleItemRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String tableName = 'discount_sale_item';
  static const String discountId = 'discount_id';
  static const String saleItemId = 'sale_item_id';

  /// Constructor
  LocalDiscountSaleItemRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the discount sale saleItemId table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $discountId TEXT NULL,
      $saleItemId TEXT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  @override
  Future<int> upsert(
    DiscountSaleItemModel discountSaleItemModel, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;

    try {
      // Check if the record exists
      List<Map<String, dynamic>> existingRecords = await db.query(
        tableName,
        where: '$discountId = ? AND $saleItemId = ?',
        whereArgs: [
          discountSaleItemModel.discountId,
          discountSaleItemModel.saleItemId,
        ],
      );

      String operation;
      int result;

      if (existingRecords.isNotEmpty) {
        // If the record exists, update it
        operation = 'updated';
        PivotElement firstElement = PivotElement(
          columnName: discountId,
          value: discountSaleItemModel.discountId!,
        );
        PivotElement secondElement = PivotElement(
          columnName: saleItemId,
          value: discountSaleItemModel.saleItemId!,
        );

        result = await _dbHelper.updatePivotDb(
          tableName,
          firstElement,
          secondElement,
          discountSaleItemModel.toJson(),
        );
      } else {
        // If the record doesn't exist, insert it
        operation = 'created';
        result = await _dbHelper.insertDb(
          tableName,
          discountSaleItemModel.toJson(),
        );
      }

      // Upsert to Hive using composite key
      final compositeKey =
          '${discountSaleItemModel.discountId}_${discountSaleItemModel.saleItemId}';
      await _hiveBox.put(compositeKey, discountSaleItemModel.toJson());

      // Insert to pending changes if required
      if (isInsertToPending) {
        Map<String, String> pivotData = {
          discountId: discountSaleItemModel.discountId!,
          saleItemId: discountSaleItemModel.saleItemId!,
        };

        final pendingChange = PendingChangesModel(
          operation: operation,
          modelName: DiscountSaleItemModel.modelName,
          modelId: jsonEncode(pivotData),
          data: jsonEncode(discountSaleItemModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error upserting discount saleItemId', e);
      rethrow;
    }
  }

  @override
  Future<bool> upsertBulk(
    List<DiscountSaleItemModel> listDiscountSaleItem, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // Prepare pending changes to track after batch commit
      final List<PendingChangesModel> pendingChanges = [];
      final List<DiscountSaleItemModel> toInsert = [];
      final List<DiscountSaleItemModel> toUpdate = [];

      // Build a set of composite keys already seen in this batch
      final Set<String> seenKeys = {};

      for (DiscountSaleItemModel newModel in listDiscountSaleItem) {
        if (newModel.discountId == null || newModel.saleItemId == null) {
          continue;
        }

        final compositeKey = '${newModel.discountId}_${newModel.saleItemId}';

        // Skip if already processed in this batch
        if (seenKeys.contains(compositeKey)) continue;
        seenKeys.add(compositeKey);

        // Check if record exists in database
        final List<Map<String, dynamic>> existingRecords = await db.query(
          tableName,
          where: '$discountId = ? AND $saleItemId = ?',
          whereArgs: [newModel.discountId, newModel.saleItemId],
        );

        if (existingRecords.isNotEmpty) {
          // Record exists, add to update list
          toUpdate.add(newModel);
        } else {
          // Record doesn't exist, add to insert list
          toInsert.add(newModel);
        }
      }

      // Use a single batch for all operations (atomic)
      Batch batch = db.batch();

      // Batch insert new records
      for (DiscountSaleItemModel model in toInsert) {
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
              modelName: DiscountSaleItemModel.modelName,
              modelId: '${model.discountId}_${model.saleItemId}',
              data: jsonEncode(modelJson),
            ),
          );
        }
      }

      // Batch update existing records
      for (DiscountSaleItemModel model in toUpdate) {
        final modelJson = model.toJson();
        final keys = modelJson.keys.toList();
        final placeholders = keys.map((key) => '$key=?').join(',');

        batch.rawUpdate(
          '''UPDATE $tableName SET $placeholders 
             WHERE $discountId = ? AND $saleItemId = ?''',
          [...modelJson.values, model.discountId, model.saleItemId],
        );

        if (isInsertToPending) {
          pendingChanges.add(
            PendingChangesModel(
              operation: 'updated',
              modelName: DiscountSaleItemModel.modelName,
              modelId: '${model.discountId}_${model.saleItemId}',
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
        if (model.discountId != null && model.saleItemId != null) {
          final compositeKey = '${model.discountId}_${model.saleItemId}';
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
      prints('Error inserting bulk discount saleItemId: $e');
      return false;
    }
  }

  // delete pivot
  // usage:
  // DiscountSaleItemModel DiscountItem = DiscountSaleItemModel(discountId: '1', saleItemId: '2');
  // int result = await deletePivot(DiscountItem, true);
  @override
  Future<int> deletePivot(
    DiscountSaleItemModel discountSaleItemModel, {
    required bool isInsertToPending,
  }) async {
    // Validate required fields
    if (discountSaleItemModel.discountId == null ||
        discountSaleItemModel.saleItemId == null) {
      prints(
        'Cannot delete discount saleItemId: discountId or saleItemId is null',
      );
      return 0;
    }

    // Create pivot elements from the model
    PivotElement firstElement = PivotElement(
      columnName: discountId,
      value: discountSaleItemModel.discountId!,
    );
    PivotElement secondElement = PivotElement(
      columnName: saleItemId,
      value: discountSaleItemModel.saleItemId!,
    );

    // Get the model before deleting it
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$discountId = ? AND $saleItemId = ?',
      whereArgs: [
        discountSaleItemModel.discountId,
        discountSaleItemModel.saleItemId,
      ],
    );

    if (results.isNotEmpty) {
      final model = DiscountSaleItemModel.fromJson(results.first);

      // Delete the record
      int result = await _dbHelper.deletePivotDb(
        tableName,
        firstElement,
        secondElement,
      );

      // Delete from Hive
      final compositeKey = '${model.discountId}_${model.saleItemId}';
      await _hiveBox.delete(compositeKey);

      // Insert to pending changes if required
      if (isInsertToPending) {
        Map<String, String> pivotData = {
          discountId: model.discountId!,
          saleItemId: model.saleItemId!,
        };

        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: DiscountSaleItemModel.modelName,
          modelId: jsonEncode(pivotData),
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints(
        'No discount saleItemId record found with discountId=${discountSaleItemModel.discountId} and saleItemId=${discountSaleItemModel.saleItemId}',
      );
      return 0;
    }
  }

  @override
  Future<List<DiscountSaleItemModel>> getListDiscountSaleItem() async {
    // Try Hive cache first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => DiscountSaleItemModel.fromJson(json),
    );
    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return DiscountSaleItemModel.fromJson(maps[index]);
    });
  }
}
