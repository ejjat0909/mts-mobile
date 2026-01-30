import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/data/repositories/local/local_shift_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/repositories/local/local_receipt_repository_impl.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/receipt_item_repository.dart';
import 'package:mts/domain/repositories/local/shift_repository.dart';
import 'package:sqflite/sqflite.dart';

final receiptModelBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(ReceiptItemModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final receiptItemLocalRepoProvider = Provider<LocalReceiptItemRepository>((
  ref,
) {
  return LocalReceiptItemRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    localShiftRepository: ref.read(shiftLocalRepoProvider),
    hiveBox: ref.read(receiptModelBoxProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalReceiptItemRepository] that uses local database
class LocalReceiptItemRepositoryImpl implements LocalReceiptItemRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final LocalShiftRepository _localShiftRepository;
  final Box<Map> _hiveBox;

  static const String tableName = 'receipt_items';

  /// Database table and column names
  static const String cId = 'id';
  static const String receiptId = 'receipt_id';
  static const String sku = 'sku';
  static const String barcode = 'barcode';
  static const String name = 'name';
  static const String itemId = 'item_id';
  static const String price = 'price';
  static const String cost = 'cost';
  static const String quantity = 'quantity';
  static const String cGrossAmount = 'gross_amount';
  static const String totalDiscount = 'total_discount';
  static const String totalTax = 'total_tax';
  static const String taxIncludedAfterDiscount = 'tax_included_after_discount';
  static const String netSale = 'net_sale';
  static const String categoryId = 'category_id';
  static const String isRefunded = 'is_refunded';
  static const String comment = 'comment';
  static const String soldBy = 'sold_by';
  static const String totalRefunded = 'total_refunded';
  static const String modifiers = 'modifiers';
  static const String variants = 'variants';
  static const String discounts = 'discounts';
  static const String taxes = 'taxes';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  /// Constructor
  LocalReceiptItemRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
    required LocalShiftRepository localShiftRepository,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _localShiftRepository = localShiftRepository,
       _hiveBox = hiveBox;

  /// Create the receipt item table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $receiptId TEXT NULL,
      $sku TEXT NULL,
      $barcode TEXT NULL,
      $name TEXT NULL,
      $itemId TEXT NULL,
      $price FLOAT NULL,
      $cost FLOAT NULL,
      $quantity FLOAT NULL,
      $totalDiscount FLOAT NULL,
      $totalTax FLOAT NULL,
      $taxIncludedAfterDiscount FLOAT NULL,
      $netSale FLOAT NULL,
      $cGrossAmount FLOAT NULL,
      $categoryId TEXT NULL,
      $totalRefunded FLOAT DEFAULT 0,
      $isRefunded INTEGER DEFAULT NULL,
      $comment TEXT NULL,
      $soldBy TEXT NULL,
      $modifiers TEXT NULL,
      $variants TEXT NULL,
      $discounts TEXT NULL,
      $taxes TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new receipt item
  @override
  Future<int> insert(
    ReceiptItemModel receiptItemModel, {
    required bool isInsertToPending,
  }) async {
    receiptItemModel.id ??= IdUtils.generateUUID().toString();
    receiptItemModel.updatedAt = DateTime.now();
    receiptItemModel.createdAt = DateTime.now();
    int result = await _dbHelper.insertDb(tableName, receiptItemModel.toJson());

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'created',
        modelName: ReceiptItemModel.modelName,
        modelId: receiptItemModel.id!,
        // modelId: receiptItemModel.id!,
        data: jsonEncode(receiptItemModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
      await _hiveBox.put(receiptItemModel.id, receiptItemModel.toJson());
    }

    return result;
  }

  // update
  @override
  Future<int> update(
    ReceiptItemModel receiptItemModel, {
    required bool isInsertToPending,
  }) async {
    receiptItemModel.updatedAt = DateTime.now();
    int result = await _dbHelper.updateDb(tableName, receiptItemModel.toJson());

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: ReceiptItemModel.modelName,
        modelId: receiptItemModel.id!,
        data: jsonEncode(receiptItemModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
      await _hiveBox.put(receiptItemModel.id, receiptItemModel.toJson());
    }

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
      final model = ReceiptItemModel.fromJson(results.first);

      // Delete the record
      int result = await _dbHelper.deleteDb(tableName, id);
      await _hiveBox.delete(id);
      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: ReceiptItemModel.modelName,
          modelId: model.id!,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No receipt item record found with id: $id');
      return 0;
    }
  }

  // get list receipt items
  @override
  Future<List<ReceiptItemModel>> getListReceiptItems() async {
    // ✅ Try Hive first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => ReceiptItemModel.fromJson(json),
    );

    if (hiveList.isNotEmpty) {
      return hiveList;
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);

    List<ReceiptItemModel> listReceiptItems = List.generate(maps.length, (
      index,
    ) {
      return ReceiptItemModel.fromJson(maps[index]);
    });

    listReceiptItems.sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));

    return listReceiptItems;
  }

  // get list receipt items where isRefunded = 0
  @override
  Future<List<ReceiptItemModel>> getListReceiptItemsNotRefunded() async {
    // Query the database with a condition where is_refunded = 0
    Database db = await _dbHelper.database;
    ShiftModel shiftModel = await _localShiftRepository.getLatestShift();
    if (shiftModel.id == null) {
      return [];
    }
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
    SELECT ri.*
    FROM $tableName ri
    JOIN ${LocalReceiptRepositoryImpl.tableName} r
      ON ri.$receiptId = r.${LocalReceiptRepositoryImpl.cId}
    WHERE ri.$isRefunded = 0
      AND r.${LocalReceiptRepositoryImpl.shiftId} = ?
    ''',
      [shiftModel.id],
    );

    // Generate and sort the list
    List<ReceiptItemModel> listReceiptItems = List.generate(maps.length, (
      index,
    ) {
      return ReceiptItemModel.fromJson(maps[index]);
    });

    listReceiptItems.sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));

    return listReceiptItems;
  }

  // get list receipt items where isRefunded = 1
  @override
  Future<List<ReceiptItemModel>> getListReceiptItemsIsRefunded() async {
    ShiftModel shiftModel = await _localShiftRepository.getLatestShift();
    if (shiftModel.id == null) {
      return [];
    }
    // Query the database with a condition where is_refunded = 1
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
    SELECT ri.*
    FROM $tableName ri
    JOIN ${LocalReceiptRepositoryImpl.tableName} r
      ON ri.$receiptId = r.${LocalReceiptRepositoryImpl.cId}
    WHERE ri.$isRefunded = 1
      AND r.${LocalReceiptRepositoryImpl.shiftId} = ?
    ''',
      [shiftModel.id],
    );

    // Generate and sort the list
    List<ReceiptItemModel> listReceiptItems = List.generate(maps.length, (
      index,
    ) {
      return ReceiptItemModel.fromJson(maps[index]);
    });

    listReceiptItems.sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));

    return listReceiptItems;
  }

  // get receipt item by receiptId
  @override
  Future<List<ReceiptItemModel>> getListReceiptItemsByReceiptId(
    String idReceipt,
  ) async {
    // first try to get list from hive first
    // Try to get from Hive first
    final receiptsItemFromHive = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: ReceiptItemModel.fromJson,
    );
    if (receiptsItemFromHive.isNotEmpty) {
      return receiptsItemFromHive
          .where((r) => r.receiptId == idReceipt)
          .toList();
    }

    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$receiptId = ?',
      whereArgs: [idReceipt],
    );
    return List.generate(maps.length, (index) {
      return ReceiptItemModel.fromJson(maps[index]);
    });
  }

  // get count list receipt items
  @override
  Future<int> getCountListReceiptItems() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return maps.length;
  }

  // calc sum total quantity
  @override
  Future<String> calcTotalQuantityNotRefundedSoldByItem() async {
    Database db = await _dbHelper.database;
    ShiftModel shiftModel = await _localShiftRepository.getLatestShift();
    if (shiftModel.id == null) {
      return '0';
    }
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
    SELECT SUM(ri.$quantity) AS totalQuantity
    FROM $tableName ri
    JOIN ${LocalReceiptRepositoryImpl.tableName} r ON ri.$receiptId = r.${LocalReceiptRepositoryImpl.cId}
    WHERE ri.$isRefunded = 0
      AND ri.$soldBy = ${ItemSoldByEnum.item}
      AND r.${LocalReceiptRepositoryImpl.shiftId} = ?
    ''',
      [shiftModel.id],
    );

    if (maps.isNotEmpty && maps[0]['totalQuantity'] != null) {
      double totalQuantity = (maps[0]['totalQuantity'] as num).toDouble();
      return totalQuantity.toStringAsFixed(0);
    } else {
      return '0';
    }
  }

  @override
  Future<String> calcTotalQuantityNotRefundedSoldByMeasurement() async {
    Database db = await _dbHelper.database;
    ShiftModel shiftModel = await _localShiftRepository.getLatestShift();
    if (shiftModel.id == null) {
      return '0.000';
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
    SELECT SUM(ri.$quantity) AS totalQuantity
    FROM $tableName ri
    JOIN ${LocalReceiptRepositoryImpl.tableName} r ON ri.$receiptId = r.${LocalReceiptRepositoryImpl.cId}
    WHERE ri.$isRefunded = 0
      AND ri.$soldBy = ${ItemSoldByEnum.measurement}
      AND r.${LocalReceiptRepositoryImpl.shiftId} = ?
    ''',
      [shiftModel.id],
    );

    if (maps.isNotEmpty && maps[0]['totalQuantity'] != null) {
      double totalQuantity = (maps[0]['totalQuantity'] as num).toDouble();
      return totalQuantity.toStringAsFixed(3);
    } else {
      return '0.000';
    }
  }

  // calc sum total quantity
  @override
  Future<String> calcTotalQuantityIsRefunded() async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT SUM($quantity) AS totalQuantity FROM $tableName WHERE $isRefunded = 1',
    );
    if (maps.isNotEmpty && maps[0]['totalQuantity'] != null) {
      return maps[0]['totalQuantity'].toString();
    } else {
      return '0';
    }
  }

  // calc total tax included after discount by receipt ID
  @override
  Future<double> calcTaxIncludedAfterDiscountByReceiptId(
    String idReceipt,
  ) async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT SUM($taxIncludedAfterDiscount) AS totalTaxIncludedAfterDiscount FROM $tableName WHERE $receiptId = ?',
      [idReceipt],
    );

    if (maps.isNotEmpty && maps[0]['totalTaxIncludedAfterDiscount'] != null) {
      return (maps[0]['totalTaxIncludedAfterDiscount'] as num).toDouble();
    } else {
      return 0.0;
    }
  }

  // insert bulk
  @override
  Future<bool> upsertBulk(
    List<ReceiptItemModel> receiptItems, {
    required bool isInsertToPending,
  }) async {
    try {
      Database db = await _dbHelper.database;

      // First, collect all existing IDs in a single query
      final idsToInsert =
          receiptItems.map((m) => m.id).whereType<String>().toList();

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
      final pendingChanges = <PendingChangesModel>[];

      // Use a single batch for all operations (atomic)
      final batch = db.batch();

      for (final model in receiptItems) {
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
                modelName: ReceiptItemModel.modelName,
                modelId: model.id!,
                data: jsonEncode(modelJson),
              ),
            );
          }
        } else {
          // New item - use INSERT OR IGNORE for atomic conflict resolution
          batch.rawInsert(
            '''INSERT OR IGNORE INTO $tableName (${modelJson.keys.join(',')})
               VALUES (${List.filled(modelJson.length, '?').join(',')})''',
            modelJson.values.toList(),
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'created',
                modelName: ReceiptItemModel.modelName,
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
          receiptItems
              .where((m) => m.id != null)
              .map((m) => MapEntry(m.id!, m.toJson())),
        ),
      );
      // Track pending changes AFTER successful batch commit
      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      prints('Error inserting bulk receipt item: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteBulk(
    List<ReceiptItemModel> receiptItems, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    List<String> idModels = receiptItems.map((e) => e.id!).toList();

    try {
      if (idModels.isEmpty) {
        prints('No receipt items ids provided for bulk delete');
        return false;
      }

      // If we need to insert to pending changes, we need to get the models first
      if (isInsertToPending) {
        for (ReceiptItemModel item in receiptItems) {
          // Insert to pending changes
          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: ReceiptItemModel.modelName,
            modelId: item.id!,
            data: jsonEncode(item.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }

      String whereIn = idModels.map((_) => '?').join(',');
      await db.delete(
        tableName,
        where: '$cId IN ($whereIn)',
        whereArgs: idModels,
      );
      prints('Sucessfully deleted receipt items ids');
      return true;
    } catch (e) {
      prints('Error deleting receipt items ids: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await db.delete(tableName);
      await _hiveBox.clear();
      return true;
    } catch (e) {
      prints('Error deleting all receipt item: $e');
      return false;
    }
  }

  @override
  Future<ReceiptItemModel?> getReceiptItemById(String idRI) async {
    final receiptsFromHive = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: ReceiptItemModel.fromJson,
    );
    if (receiptsFromHive.isNotEmpty) {
      receiptsFromHive.sort(
        (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
          a.createdAt ?? DateTime(1970),
        ),
      );
      return receiptsFromHive.first;
    }

    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [idRI],
    );
    if (maps.isNotEmpty) {
      return ReceiptItemModel.fromJson(maps[0]);
    } else {
      return null;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<ReceiptItemModel> newData, {
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
  Future<bool> deleteByReceiptId(String idReceipt) async {
    Database db = await _dbHelper.database;
    try {
      await db.delete(
        tableName,
        where: '$receiptId = ?',
        whereArgs: [idReceipt],
      );
      await _hiveBox.delete(idReceipt);
      return true;
    } catch (e) {
      prints('Error deleting receipt items by receipt ID: $e');
      return false;
    }
  }
}
