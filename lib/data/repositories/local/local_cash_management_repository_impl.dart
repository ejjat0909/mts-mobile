import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/enum/cash_management_type_enum.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/cash_management/cash_management_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/data/repositories/local/local_shift_repository_impl.dart';
import 'package:mts/domain/repositories/local/cash_management_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/shift_repository.dart';
import 'package:sqflite/sqflite.dart';

final cashManagementBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(CashManagementModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final cashManagementLocalRepoProvider = Provider<LocalCashManagementRepository>(
  (ref) {
    return LocalCashManagementRepositoryImpl(
      dbHelper: ref.read(databaseHelpersProvider),
      pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
      hiveBox: ref.read(cashManagementBoxProvider),
      shiftRepository: ref.read(shiftLocalRepoProvider),
    );
  },
);

/// Implementation of [LocalCashManagementRepository] that uses local database
class LocalCashManagementRepositoryImpl
    implements LocalCashManagementRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;
  final LocalShiftRepository _shiftRepository;
  static const String tableName = 'cash_managements';

  /// Database table and column names
  static const String cId = 'id';
  static const String cStaffId = 'staff_id';
  static const String cShiftId = 'shift_id';
  static const String cAmount = 'amount';
  static const String cComment = 'comment';
  static const String cType = 'type';
  static const String cCreatedAt = 'created_at';
  static const String cUpdatedAt = 'updated_at';
  // isSynced property removed

  /// Constructor
  LocalCashManagementRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
    required LocalShiftRepository shiftRepository,
  }) : _dbHelper = dbHelper,
       _shiftRepository = shiftRepository,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the cash management table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $cStaffId TEXT NULL,
      $cShiftId TEXT NULL,
      $cAmount FLOAT NULL,
      $cComment TEXT NULL,
      $cType INTEGER NULL,
      $cUpdatedAt TIMESTAMP DEFAULT NULL,
      $cCreatedAt TIMESTAMP DEFAULT NULL
    ''';

    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  @override
  Future<int> insert(
    CashManagementModel model, {
    required bool isInsertToPending,
  }) async {
    model.id ??= IdUtils.generateUUID();
    model.createdAt = DateTime.now();
    model.updatedAt = DateTime.now();

    try {
      // Insert to SQLite
      int result = await _dbHelper.insertDb(tableName, model.toJson());

      // Insert to Hive
      await _hiveBox.put(model.id!, model.toJson());

      if (isInsertToPending) {
        await _insertPending(model, 'created');
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error inserting cash management', e);
      rethrow;
    }
  }

  @override
  Future<int> update(
    CashManagementModel model, {
    required bool isInsertToPending,
  }) async {
    model.updatedAt = DateTime.now();

    try {
      // Update SQLite
      int result = await _dbHelper.updateDb(tableName, model.toJson());

      // Update Hive
      await _hiveBox.put(model.id!, model.toJson());

      if (isInsertToPending) {
        await _insertPending(model, 'updated');
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error updating cash management', e);
      rethrow;
    }
  }

  @override
  Future<int> delete(String id, {required bool isInsertToPending}) async {
    // Get single item efficiently instead of fetching all
    final model =
        HiveSyncHelper.getById(
          box: _hiveBox,
          id: id,
          fromJson: (json) => CashManagementModel.fromJson(json),
        ) ??
        CashManagementModel(id: id);

    try {
      // Delete from SQLite
      int result = await _dbHelper.deleteDb(tableName, id);

      // Delete from Hive
      await _hiveBox.delete(id);

      if (isInsertToPending) {
        await _insertPending(model, 'deleted');
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error deleting cash management', e);
      rethrow;
    }
  }

  // ==================== Bulk Operations ====================

  @override
  Future<bool> upsertBulk(
    List<CashManagementModel> list, {
    required bool isInsertToPending,
  }) async {
    try {
      Database db = await _dbHelper.database;
      final batch = db.batch();
      final List<PendingChangesModel> pendingList = [];

      for (var model in list) {
        model.id ??= IdUtils.generateUUID();
        model.createdAt ??= DateTime.now();
        model.updatedAt ??= DateTime.now();

        batch.insert(
          tableName,
          model.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (isInsertToPending) {
          pendingList.add(
            PendingChangesModel(
              operation: 'created',
              modelName: CashManagementModel.modelName,
              modelId: model.id!,
              data: jsonEncode(model.toJson()),
            ),
          );
        }
      }

      await batch.commit(noResult: true);

      // Bulk insert to Hive
      final dataMap = <dynamic, Map<dynamic, dynamic>>{};
      for (var model in list) {
        if (model.id != null) {
          dataMap[model.id!] = model.toJson();
        }
      }
      await _hiveBox.putAll(dataMap);

      for (var pending in pendingList) {
        await _pendingChangesRepository.insert(pending);
      }

      return true;
    } catch (e) {
      await LogUtils.error('Error bulk inserting cash managements', e);
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<CashManagementModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(tableName); // Delete all rows from SQLite
      await _hiveBox.clear(); // Clear Hive
      return await upsertBulk(newData, isInsertToPending: isInsertToPending);
    } catch (e) {
      await LogUtils.error('Error replacing all cash managements', e);
      return false;
    }
  }

  // ==================== Query Operations ====================

  Future<List<CashManagementModel>> getListCashManagements() async {
    // Try Hive cache first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => CashManagementModel.fromJson(json),
    );
    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final maps = await _dbHelper.readDb(tableName);
    return maps.map((json) => CashManagementModel.fromJson(json)).toList();
  }

  /// Get single model by ID (Hive-first, fallback to SQLite)
  Future<CashManagementModel?> getById(String id) async {
    // Try Hive cache first
    final hiveModel = HiveSyncHelper.getById(
      box: _hiveBox,
      id: id,
      fromJson: (json) => CashManagementModel.fromJson(json),
    );
    if (hiveModel != null) {
      return hiveModel;
    }

    // Fallback to SQLite
    final map = await _dbHelper.readDbById(tableName, id);
    if (map != null) {
      return CashManagementModel.fromJson(map);
    }
    return null;
  }

  // ==================== Delete Operations ====================

  @override
  Future<bool> deleteAll() async {
    try {
      // Delete from SQLite
      final db = await _dbHelper.database;
      await db.delete(tableName);

      // Delete from Hive
      await _hiveBox.clear();

      return true;
    } catch (e) {
      await LogUtils.error('Error deleting all cash managements', e);
      return false;
    }
  }

  // ==================== Helper Methods ====================

  Future<void> _insertPending(
    CashManagementModel model,
    String operation,
  ) async {
    final pending = PendingChangesModel(
      operation: operation,
      modelName: CashManagementModel.modelName,
      modelId: model.id!,
      data: jsonEncode(model.toJson()),
    );
    await _pendingChangesRepository.insert(pending);
  }

  @override
  Future<bool> deleteBulk(
    List<CashManagementModel> listCMM, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    List<String> idModels = listCMM.map((e) => e.id!).toList();

    if (idModels.isEmpty) {
      await LogUtils.error(
        'No cash management ids provided for bulk delete',
        null,
      );
      //notifyChanges();
      return false;
    }

    // If we need to insert to pending changes, we need to get the models first
    if (isInsertToPending) {
      for (CashManagementModel model in listCMM) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: CashManagementModel.modelName,
          modelId: model.id,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }
    }

    String whereIn = idModels.map((_) => '?').join(',');
    try {
      await db.delete(
        tableName,
        where: '$cId IN ($whereIn)',
        whereArgs: idModels,
      );

      // ✅ Delete from Hive
      await _hiveBox.deleteAll(idModels);

      await LogUtils.info('Successfully deleted cash management ids');
      //notifyChanges();
      return true;
    } catch (e) {
      await LogUtils.error('Error deleting cash management ids', e);
      //notifyChanges();
      return false;
    }
  }

  @override
  Future<List<CashManagementModel>> getListCashManagementModel() async {
    // ✅ Try Hive first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => CashManagementModel.fromJson(json),
    );

    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return CashManagementModel.fromJson(maps[index]);
    });
  }

  @override
  Future<List<CashManagementModel>> getListCashManagementNotSynced() async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      // No longer filtering by isSynced
      orderBy: '$cCreatedAt DESC',
    );
    return List.generate(maps.length, (index) {
      return CashManagementModel.fromJson(maps[index]);
    });
  }

  Future<double> getSumAmountPayInNotSynced() async {
    Database db = await _dbHelper.database;

    // Use a SQL query with SUM() for better efficiency
    final result = await db.rawQuery(
      '''
    SELECT SUM($cAmount) as totalAmount
    FROM $tableName
    WHERE $cType = ?
    ''',
      [CashManagementTypeEnum.payIn],
    );

    // Extract the total amount from the result
    if (result.isNotEmpty && result.first['totalAmount'] != null) {
      return result.first['totalAmount'] as double;
    }

    return 0.00; // Return 0 if no rows matched
  }

  Future<double> getSumAmountPayOutNotSynced() async {
    Database db = await _dbHelper.database;

    // Use a SQL query with SUM() for better efficiency
    final result = await db.rawQuery(
      '''
    SELECT SUM($cAmount) as totalAmount
    FROM $tableName
    WHERE $cType = ?
    ''',
      [CashManagementTypeEnum.payOut],
    );

    // Extract the total amount from the result
    if (result.isNotEmpty && result.first['totalAmount'] != null) {
      return result.first['totalAmount'] as double;
    }

    return 0.00; // Return 0 if no rows matched
  }

  /// Notify changes to update streams
  // @override
  // Future<void> notifyChanges() async {
  //   await emitSumAmountPayOutNotSynced();
  //   await emitSumAmountPayInNotSynced();
  // }

  @override
  Future<List<CashManagementModel>> getCashManagementListByShift() async {
    ShiftModel shiftModel = await _shiftRepository.getLatestShift();

    // If no shift exists, return empty list
    if (shiftModel.id == null && shiftModel.createdAt == null) {
      return [];
    }

    Database db = await _dbHelper.database;

    // Get current time
    final DateTime now = DateTime.now();

    // Format dates for SQL query
    final String startDate = DateTimeUtils.getDateTimeFormat(
      shiftModel.createdAt,
    );
    final String endDate = DateTimeUtils.getDateTimeFormat(now);

    // Query cash management records between shift creation time and now
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cCreatedAt BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: '$cCreatedAt ASC',
    );

    // Convert query results to CashManagementModel objects
    return List.generate(maps.length, (index) {
      return CashManagementModel.fromJson(maps[index]);
    });
  }
}
