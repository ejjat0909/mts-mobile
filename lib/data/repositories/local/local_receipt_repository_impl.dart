import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/data/repositories/local/local_shift_repository_impl.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/receipt_repository.dart';
import 'package:mts/domain/repositories/local/shift_repository.dart';
import 'package:sqflite/sqflite.dart';

final receiptBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(ReceiptModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final receiptLocalRepoProvider = Provider<LocalReceiptRepository>((ref) {
  return LocalReceiptRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    shiftRepository: ref.read(shiftLocalRepoProvider),
    hiveBox: ref.read(receiptBoxProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalReceiptRepository] that uses local database
class LocalReceiptRepositoryImpl implements LocalReceiptRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final LocalShiftRepository _localShiftRepository;
  final Box<Map> _hiveBox;

  static const String tableName = 'receipts';

  /// Database table and column names
  static const String cId = 'id';
  static const String showUUID = 'show_uuid';
  static const String outletId = 'outlet_id';
  static const String shiftId = 'shift_id';
  static const String staffId = 'staff_id';
  static const String staffName = 'staff_name';
  static const String orderedByStaffId = 'ordered_by_staff_id';
  static const String orderedByStaffName = 'ordered_by_staff_name';
  static const String customerId = 'customer_id';
  static const String customerName = 'customer_name';
  static const String cash = 'cash';
  static const String refundedReceiptId = 'refunded_receipt_id';
  static const String paymentType = 'payment_type';
  static const String orderOption = 'order_option';
  static const String cOrderOptionId = 'order_option_id';
  static const String cTableName = 'table_name';
  static const String receiptStatus = 'receipt_status';
  static const String totalDiscount = 'total_discount';
  static const String taxPercentage = 'tax_percentage';
  static const String payableAmount = 'payable_amount';
  static const String cost = 'cost';
  static const String grossSale = 'gross_sale';
  static const String netSale = 'net_sale';
  static const String totalCollected = 'total_collected';
  static const String grossProfit = 'gross_profit';
  static const String posDeviceName = 'pos_device_name';
  static const String posDeviceId = 'pos_device_id';
  static const String openOrderName = 'open_order_name';
  static const String adjustedPrice = 'adjusted_price';
  static const String totalTaxes = 'total_taxes';
  static const String totalIncludedTaxes = 'total_included_taxes';
  static const String totalCashRounding = 'total_cash_rounding';

  static const String remarks = 'remarks'; //
  static const String runningNumber = 'running_number';
  static const String isChangePaymentType = 'is_change_payment_type';

  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  /// Constructor
  LocalReceiptRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required LocalShiftRepository shiftRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _localShiftRepository = shiftRepository,
       _hiveBox = hiveBox;

  /// Create the receipt table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $showUUID TEXT NULL,
      $outletId TEXT NULL,
      $shiftId TEXT NULL,
      $staffId TEXT NULL,
      $staffName TEXT NULL,
      $orderedByStaffId TEXT NULL,
      $orderedByStaffName TEXT NULL,
      $customerId TEXT NULL,
      $customerName TEXT NULL,
      $cTableName TEXT NULL,
      $runningNumber TEXT NULL,
      $cash FLOAT NULL,
      $remarks TEXT NULL,
      $posDeviceName TEXT NULL,
      $posDeviceId TEXT NULL,
      $adjustedPrice FLOAT NULL,
      $totalCashRounding FLOAT NULL,
      $totalTaxes FLOAT NULL,
      $totalIncludedTaxes FLOAT NULL,
      $refundedReceiptId TEXT NULL,
      $paymentType TEXT NULL,
      $cOrderOptionId TEXT NULL,
      $orderOption TEXT NULL,
      $openOrderName TEXT NULL,
      $receiptStatus INTEGER NULL,
      $totalDiscount DOUBLE NULL,
      $taxPercentage INTEGER NULL,
      $payableAmount FLOAT NULL,
      $cost FLOAT NULL,
      $grossSale FLOAT NULL,
      $netSale FLOAT NULL,
      $totalCollected FLOAT NULL,
      $grossProfit FLOAT NULL,
      $isChangePaymentType INTEGER DEFAULT 0,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new receipt
  @override
  Future<int> insert(
    ReceiptModel receiptModel, {
    required bool isInsertToPending,
  }) async {
    receiptModel.updatedAt = DateTime.now();
    receiptModel.createdAt = DateTime.now();
    int result = await _dbHelper.insertDb(tableName, receiptModel.toJson());

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'created',
        modelName: ReceiptModel.modelName,
        modelId: receiptModel.id!,
        data: jsonEncode(receiptModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
      await _hiveBox.put(receiptModel.id, receiptModel.toJson());
    }

    return result;
  }

  @override
  Future<int> update(
    ReceiptModel receiptModel, {
    required bool isInsertToPending,
  }) async {
    receiptModel.updatedAt = DateTime.now();
    int result = await _dbHelper.updateDb(tableName, receiptModel.toJson());

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: ReceiptModel.modelName,
        modelId: receiptModel.id!,
        data: jsonEncode(receiptModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
      await _hiveBox.put(receiptModel.id, receiptModel.toJson());
    }

    return result;
  }

  // delete using id
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
      final model = ReceiptModel.fromJson(results.first);

      // Delete the record
      int result = await _dbHelper.deleteDb(tableName, id);
      _hiveBox.delete(id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: ReceiptModel.modelName,
          modelId: model.id!,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No receipt record found with id: $id');
      return 0;
    }
  }

  // get list receiptModel
  @override
  Future<List<ReceiptModel>> getListReceiptModel() async {
    // Try to get from Hive first
    final receiptsFromHive = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: ReceiptModel.fromJson,
    );
    if (receiptsFromHive.isNotEmpty) {
      return receiptsFromHive;
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return ReceiptModel.fromJson(maps[index]);
    });
  }

  @override
  Future<List<ReceiptModel>> getListReceiptModelByShiftId() async {
    ShiftModel shiftModel = await _localShiftRepository.getLatestShift();
    //prints('SHIFFFFTTTT IDDDDD ${shiftModel.id}');
    if (shiftModel.id == null) {
      return [];
    }

    // Try to get from Hive first
    final receiptsFromHive = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: ReceiptModel.fromJson,
    );
    if (receiptsFromHive.isNotEmpty) {
      return receiptsFromHive.where((r) => r.shiftId == shiftModel.id).toList();
    }

    // Fallback to SQLite
    Database db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$shiftId = ?',
      whereArgs: [shiftModel.id],
    );
    return List.generate(maps.length, (index) {
      return ReceiptModel.fromJson(maps[index]);
    });
  }

  // insert bulk
  @override
  Future<bool> upsertBulk(
    List<ReceiptModel> receiptModels, {
    required bool isInsertToPending,
  }) async {
    try {
      Database db = await _dbHelper.database;
      // First, collect all existing IDs in a single query
      final idsToInsert =
          receiptModels.map((m) => m.id).whereType<String>().toList();

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

      for (final model in receiptModels) {
        if (model.id == null) continue;

        final isExisting = existingIds.contains(model.id);
        final modelJson = model.toJson();
        final updatedAtStr =
            model.updatedAt != null
                ? model.updatedAt!.toIso8601String()
                : DateTime.now().toIso8601String();

        if (isExisting) {
          // Only update if new item is newer than existing one
          batch.update(
            tableName,
            modelJson,
            where: '$cId = ? AND ($updatedAt IS NULL OR $updatedAt <= ?)',
            whereArgs: [model.id, updatedAtStr],
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'updated',
                modelName: ReceiptModel.modelName,
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
                modelName: ReceiptModel.modelName,
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
          receiptModels
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
      prints("Error inserting receipt bulk $e");
      return false;
    }
  }

  @override
  String formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss', 'en_US');
    return formatter.format(dateTime);
  }

  @override
  Future<List<ReceiptModel>> searchReceiptIDFromDb(
    String query,
    DateTimeRange? dateRange,
    int page,
    int pageSize,
    String? paymentType,
    String? orderOption,
  ) async {
    List<ReceiptModel> receipts = [];

    // First, try to get receipts from Hive box
    // try {
    //   receipts = getListReceiptFromHive();
    //   if (receipts.isNotEmpty) {
    //     // Filter receipts based on search criteria
    //     receipts = _filterReceipts(
    //       receipts,
    //       query,
    //       dateRange,
    //       paymentType,
    //       orderOption,
    //     );

    //     // Sort by updatedAt in descending order
    //     receipts.sort(
    //       (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
    //         a.updatedAt ?? DateTime(1970),
    //       ),
    //     );

    //     // Paginate the results
    //     final startIndex = (page - 1) * pageSize;
    //     final endIndex = startIndex + pageSize;
    //     return receipts.sublist(
    //       startIndex,
    //       endIndex > receipts.length ? receipts.length : endIndex,
    //     );
    //   }
    // } catch (e) {
    //   prints(
    //     'Error retrieving receipts from Hive box, falling back to SQLite $e',
    //   );
    // }

    // Fallback: Get receipts from SQLite if Hive box is empty or not available
    Database db = await _dbHelper.database;

    // Start building the SQL query
    String sql = 'SELECT * FROM $tableName WHERE 1=1';
    List<dynamic> args = [];

    // Add query condition if not empty
    if (query.isNotEmpty) {
      sql += ' AND ($showUUID LIKE ? OR $showUUID LIKE ?)';
      args.add('%$query%');
      args.add('%#$query%');
    }

    // Add date range condition if provided
    if (dateRange != null) {
      sql += ' AND ${LocalReceiptRepositoryImpl.createdAt} BETWEEN ? AND ?';
      args.add(formatDateTime(dateRange.start));
      args.add(formatDateTime(dateRange.end));
    }

    // Add paymentType condition if provided
    if (paymentType != null) {
      sql += ' AND ${LocalReceiptRepositoryImpl.paymentType} = ?';
      args.add(paymentType);
    }

    // for order option
    if (orderOption != null) {
      sql += ' AND ${LocalReceiptRepositoryImpl.orderOption} = ?';
      args.add(orderOption);
    }

    // Add ORDER BY clause to sort by updatedAt in descending order
    sql += ' ORDER BY $updatedAt DESC';

    /// [Debugging]: Print the full SQL query with arguments
    // String fullSql = sql;
    // for (var arg in args) {
    //   fullSql = fullSql.replaceFirst('?', arg.toString());
    // }
    // prints('Executing SQL: $fullSql');

    // Execute the query
    List<Map<String, dynamic>> result = await db.rawQuery(sql, args);

    // Convert the result to a list of ReceiptModel
    receipts = result.map((item) => ReceiptModel.fromJson(item)).toList();

    // Paginate the results
    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    return receipts.sublist(
      startIndex,
      endIndex > receipts.length ? receipts.length : endIndex,
    );
  }

  @override
  Future<bool> deleteBulk(
    List<ReceiptModel> receiptModels, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    List<String> idModels =
        receiptModels.map((receiptModel) => receiptModel.id!).toList();

    try {
      if (idModels.isEmpty) {
        prints('No receipt ids provided for bulk delete');
        return false;
      }

      // If we need to insert to pending changes, we need to get the models first
      if (isInsertToPending) {
        for (ReceiptModel model in receiptModels) {
          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: ReceiptModel.modelName,
            modelId: model.id!,
            data: jsonEncode(model.toJson()),
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
      await _hiveBox.deleteAll(idModels);
      prints('Sucessfully deleted receipt ids');
      return true;
    } catch (e) {
      prints('Error deleting receipt ids: $e');
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
      prints('Error deleting all receipt: $e');
      return false;
    }
  }

  @override
  Future<double> calcPayableAmountNotRefunded() async {
    ShiftModel shiftModel = await _localShiftRepository.getLatestShift();
    if (shiftModel.id == null) {
      return 0.0;
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT SUM($payableAmount) AS payableAmount 
      FROM $tableName 
      WHERE LOWER($paymentType) LIKE "%cash%" 
      AND $refundedReceiptId IS NULL
      AND $shiftId = ?
      ''',
      [shiftModel.id],
    );

    if (maps.isNotEmpty && maps[0]['payableAmount'] != null) {
      return (maps[0]['payableAmount'] as double);
    } else {
      return 0.0;
    }
  }

  @override
  Future<double> calcPayableAmountRefunded() async {
    ShiftModel shiftModel = await _localShiftRepository.getLatestShift();
    if (shiftModel.id == null) {
      return 0.0;
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT SUM($payableAmount) AS payableAmount 
      FROM $tableName 
      WHERE LOWER($paymentType) LIKE "%cash%" 
      AND $refundedReceiptId IS NOT NULL
      AND $shiftId = ?
      ''',
      [shiftModel.id],
    );

    if (maps.isNotEmpty && maps[0]['payableAmount'] != null) {
      return (maps[0]['payableAmount'] as double);
    } else {
      return 0.0;
    }
  }

  @override
  Future<double> calcAllAmountRefunded() async {
    ShiftModel shiftModel = await _localShiftRepository.getLatestShift();
    if (shiftModel.id == null) {
      return 0.0;
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT SUM($payableAmount) AS payableAmount 
      FROM $tableName 
      WHERE $refundedReceiptId IS NOT NULL 
      AND $shiftId = ?
      ''',
      [shiftModel.id],
    );

    if (maps.isNotEmpty && maps[0]['payableAmount'] != null) {
      return (maps[0]['payableAmount'] as double);
    } else {
      return 0.0;
    }
  }

  @override
  Future<String> calcGrossSales() async {
    Database db = await _dbHelper.database;
    ShiftModel shiftModel = await _localShiftRepository.getLatestShift();
    if (shiftModel.id == null) {
      return '0.00';
    }
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT SUM($grossSale) AS grossSale FROM $tableName WHERE $shiftId = ?',
      [shiftModel.id],
    );

    if (maps.isNotEmpty && maps[0]['grossSale'] != null) {
      return (maps[0]['grossSale'] as double).toStringAsFixed(2);
    } else {
      return '0.00';
    }
  }

  @override
  Future<String> calcNetSales() async {
    Database db = await _dbHelper.database;
    ShiftModel shiftModel = await _localShiftRepository.getLatestShift();
    if (shiftModel.id == null) {
      return '0.00';
    }
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT SUM($netSale) AS netSale FROM $tableName WHERE $shiftId = ?',
      [shiftModel.id],
    );

    if (maps.isNotEmpty && maps[0]['netSale'] != null) {
      return (maps[0]['netSale'] as double).toStringAsFixed(2);
    } else {
      return '0.00';
    }
  }

  //  calc adjustment
  @override
  Future<String> calcAdjustment() async {
    Database db = await _dbHelper.database;
    ShiftModel shiftModel = await _localShiftRepository.getLatestShift();
    if (shiftModel.id == null) {
      return '0.00';
    }
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT SUM($adjustedPrice) AS adjustment FROM $tableName WHERE $shiftId = ?',
      [shiftModel.id],
    );

    if (maps.isNotEmpty && maps[0]['adjustment'] != null) {
      return (maps[0]['adjustment'] as double).toStringAsFixed(2);
    } else {
      return '0.00';
    }
  }

  //calc total discount
  @override
  Future<String> calcTotalDiscount() async {
    Database db = await _dbHelper.database;
    ShiftModel shiftModel = await _localShiftRepository.getLatestShift();
    if (shiftModel.id == null) {
      return '0.00';
    }
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT SUM($totalDiscount) AS totalDiscount FROM $tableName WHERE $shiftId = ?',
      [shiftModel.id],
    );

    if (maps.isNotEmpty && maps[0]['totalDiscount'] != null) {
      return (maps[0]['totalDiscount'] as double).toStringAsFixed(2);
    } else {
      return '0.00';
    }
  }

  // calc total tax
  @override
  Future<String> calcTotalTax() async {
    Database db = await _dbHelper.database;
    ShiftModel shiftModel = await _localShiftRepository.getLatestShift();
    if (shiftModel.id == null) {
      return '0.00';
    }
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT SUM($totalTaxes) AS totalTax FROM $tableName WHERE $shiftId = ?',
      [shiftModel.id],
    );

    if (maps.isNotEmpty && maps[0]['totalTax'] != null) {
      return (maps[0]['totalTax'] as double).toStringAsFixed(2);
    } else {
      return '0.00';
    }
  }

  // calc total cash rounding
  @override
  Future<String> calcTotalCashRounding() async {
    Database db = await _dbHelper.database;
    ShiftModel shiftModel = await _localShiftRepository.getLatestShift();
    if (shiftModel.id == null) {
      return '0.00';
    }
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT SUM($totalCashRounding) AS totalCashRounding FROM $tableName WHERE $shiftId = ?',
      [shiftModel.id],
    );

    if (maps.isNotEmpty && maps[0]['totalCashRounding'] != null) {
      return (maps[0]['totalCashRounding'] as double).toStringAsFixed(2);
    } else {
      return '0.00';
    }
  }

  // get receipt model from id
  @override
  Future<ReceiptModel?> getReceiptModelFromId(String idReceipt) async {
    List<ReceiptModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => ReceiptModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      final receiptFromHive =
          list.where((element) => element.id == idReceipt).firstOrNull;
      if (receiptFromHive != null) {
        return receiptFromHive;
      }
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [idReceipt],
    );
    if (maps.isNotEmpty) {
      return ReceiptModel.fromJson(maps.first);
    } else {
      return null;
    }
  }

  @override
  Future<ReceiptModel> getLatestReceiptModel() async {
    // Try to get from Hive first
    final receiptsFromHive = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: ReceiptModel.fromJson,
    );
    if (receiptsFromHive.isNotEmpty) {
      receiptsFromHive.sort(
        (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
          a.createdAt ?? DateTime(1970),
        ),
      );
      return receiptsFromHive.first;
    }

    // Fallback to SQLite
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: '$createdAt DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ReceiptModel.fromJson(maps.first);
    } else {
      return ReceiptModel();
    }
  }

  @override
  Future<bool> replaceAllData(
    List<ReceiptModel> newData, {
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
