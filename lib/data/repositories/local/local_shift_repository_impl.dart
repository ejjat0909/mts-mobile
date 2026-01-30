import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_device_repository_impl.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/domain/repositories/local/device_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/shift_repository.dart';
import 'package:sqflite/sqflite.dart';

final shiftBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(ShiftModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final shiftLocalRepoProvider = Provider<LocalShiftRepository>((ref) {
  return LocalShiftRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(shiftBoxProvider),
    deviceLocalRepository: ref.read(deviceLocalRepoProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalShiftRepository] that uses local database
class LocalShiftRepositoryImpl implements LocalShiftRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;
  final LocalDeviceRepository _deviceLocalRepository;
  // Removed circular dependency

  /// Database table and column names
  static const String tableName = 'shifts';
  static const String cId = 'id';
  static const String outletId = 'outlet_id';
  static const String startingCash = 'starting_cash';
  static const String expectedCash = 'expected_cash';
  static const String actualCash = 'actual_cash';
  static const String shortCash = 'short_cash';
  static const String openedBy = 'opened_by';
  static const String closedBy = 'closed_by';
  static const String posDeviceId = 'pos_device_id';
  static const String posDeviceName = 'pos_device_name';
  static const String posDeviceJson = 'pos_device_json';
  static const String cashPayments = 'cash_payments';
  static const String cashRefunds = 'cash_refunds';
  static const String saleSummaryJson = 'sales_summary_json';
  static const String isPrint = 'is_print';
  static const String closedAt = 'closed_at';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  /// Stream controller for latest expected amount
  final StreamController<double> _latestExpectedAmountStreamController =
      StreamController<double>.broadcast();

  @override
  Stream<double> get getLatestExpectedAmountStream =>
      _latestExpectedAmountStreamController.stream;

  /// Constructor
  LocalShiftRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
    required LocalDeviceRepository deviceLocalRepository,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox,
       _deviceLocalRepository = deviceLocalRepository;

  /// Create the shift table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $outletId TEXT NULL,
      $startingCash FLOAT NULL,
      $expectedCash FLOAT NULL,
      $actualCash FLOAT NULL,
      $shortCash FLOAT NULL,
      $isPrint INTEGER NULL,
      $closedAt TIMESTAMP DEFAULT NULL,
      $closedBy TEXT NULL,
      $openedBy TEXT NULL,
      $posDeviceId TEXT NULL,
      $posDeviceName TEXT NULL,
      $posDeviceJson TEXT NULL,
      $cashPayments FLOAT NULL,
      $cashRefunds FLOAT NULL,
      $saleSummaryJson TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new shift
  @override
  Future<int> insert(
    ShiftModel shiftModel, {
    required bool isInsertToPending,
  }) async {
    shiftModel.id ??= IdUtils.generateUUID().toString();
    shiftModel.updatedAt = DateTime.now();
    shiftModel.createdAt = DateTime.now();
    // buat macamni sebab timing between hive nak insert ke sqlite adaa conflict dengan server (terlalu laju panggl API  sebelum masuk pending changes)
    await _hiveBox.put(shiftModel.id, shiftModel.toJson());
    int result = await _dbHelper.insertDb(tableName, shiftModel.toJson());
    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'created',
        modelName: ShiftModel.modelName,
        modelId: shiftModel.id,
        data: jsonEncode(shiftModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    notifyChanges();

    return result;
  }

  // Future<void> enforceShiftLimit() async {
  //   Database db = await _dbHelper.database;

  //   // Fetch all shifts sorted by `closedAt`, oldest first
  //   List<Map<String, dynamic>> shifts = await db.query(
  //     tableName,
  //     orderBy: '$closedAt ASC',
  //   );

  //   // Check if we have more than 30 shifts
  //   // mohsin cakap 30
  //   int maxShifts = 30;
  //   if (shifts.length > maxShifts) {
  //     int excessCount = shifts.length - maxShifts;

  //     for (var shift in shifts) {
  //       if (excessCount <= 0) break;

  //       // Only delete if `closedAt` is not null
  //       if (shift[closedAt] != null) {
  //         await delete(
  //           shift[cId],
  //           true,
  //         ); // Always insert to pending changes for limit enforcement
  //         excessCount--;
  //       }
  //     }
  //   }
  // }

  @override
  Future<int> update(
    ShiftModel shiftModel, {
    required bool isInsertToPending,
  }) async {
    shiftModel.updatedAt = DateTime.now();
    await _hiveBox.put(shiftModel.id, shiftModel.toJson());
    int result = await _dbHelper.updateDb(tableName, shiftModel.toJson());
    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: ShiftModel.modelName,
        modelId: shiftModel.id,
        data: jsonEncode(shiftModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    notifyChanges();

    return result;
  }

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
      final model = ShiftModel.fromJson(results.first);

      // Delete the record
      int result = await _dbHelper.deleteDb(tableName, id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: ShiftModel.modelName,
          modelId: model.id!,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      notifyChanges();
      return result;
    } else {
      prints('No shift record found with id: $id');
      notifyChanges();
      return 0;
    }
  }

  @override
  Future<bool> upsertBulk(
    List<ShiftModel> list, {
    required bool isInsertToPending,
  }) async {
    try {
      Database db = await _dbHelper.database;
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

      for (ShiftModel model in list) {
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
                modelName: ShiftModel.modelName,
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
                modelName: ShiftModel.modelName,
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
      prints('Error inserting bulk item: $e');
      return false;
    }
  }

  // get latest starting cash
  @override
  Future<double> getLatestExpectedCash() async {
    List<ShiftModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => ShiftModel.fromJson(json),
    );
    PosDeviceModel posDeviceModel =
        await _deviceLocalRepository.getLatestDeviceModel();
    if (posDeviceModel.id == null) {
      return 0.0;
    }

    if (list.isNotEmpty) {
      // Apply same filtering as database query: closedAt IS NULL AND posDeviceId matches
      final filteredList =
          list
              .where(
                (shift) =>
                    shift.closedAt == null &&
                    shift.posDeviceId == posDeviceModel.id,
              )
              .toList()
            ..sort(
              (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
                a.createdAt ?? DateTime.now(),
              ),
            );

      if (filteredList.isNotEmpty) {
        return filteredList.first.expectedCash ?? 0.0;
      }
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$closedAt IS NULL AND $posDeviceId = ?',
      whereArgs: [posDeviceModel.id],
      orderBy: '$createdAt DESC',
      limit: 1,
    );

    return maps.isNotEmpty ? maps.first[expectedCash] as double : 0.0;
  }

  @override
  Future<bool> hasShift() async {
    PosDeviceModel posDeviceModel =
        await _deviceLocalRepository.getLatestDeviceModel();
    List<ShiftModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => ShiftModel.fromJson(json),
    );

    if (list.isNotEmpty) {
      // Apply same filtering as database query: closedAt IS NULL AND posDeviceId matches
      final filteredList =
          list.where((shift) => shift.posDeviceId == posDeviceModel.id).toList()
            ..sort(
              (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
                a.createdAt ?? DateTime.now(),
              ),
            );

      if (filteredList.isNotEmpty) {
        return filteredList.first.closedAt == null;
      }
    }
    Database db = await _dbHelper.database;
    // where close at is null
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$posDeviceId = ?',
      whereArgs: [posDeviceModel.id],
      orderBy: '$createdAt DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      ShiftModel shiftModel = ShiftModel.fromJson(maps.first);
      return shiftModel.closedAt == null;
    } else {
      return false;
    }
  }

  @override
  Future<bool> deleteBulk(
    List<ShiftModel> shiftModels, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    List<String> idModels = shiftModels.map((e) => e.id!).toList();

    try {
      if (idModels.isEmpty) {
        prints('No shift ids provided for bulk delete');
        notifyChanges();
        return false;
      }

      // Insert to pending changes if required
      if (isInsertToPending) {
        for (ShiftModel model in shiftModels) {
          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: ShiftModel.modelName,
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
      prints('Sucessfully deleted shift ids');
      notifyChanges();
      return true;
    } catch (e) {
      prints('Error deleting shift ids: $e');
      notifyChanges();
      return false;
    }
  }

  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await Future.wait([_hiveBox.clear(), db.delete(tableName)]);

      notifyChanges();
      return true;
    } catch (e) {
      prints('Error deleting all shifts: $e');
      notifyChanges();
      return false;
    }
  }

  @override
  Future<ShiftModel> getLatestShift() async {
    PosDeviceModel posDeviceModel =
        await _deviceLocalRepository.getLatestDeviceModel();
    List<ShiftModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => ShiftModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      // Apply same filtering as database query: closedAt IS NULL AND posDeviceId matches
      final filteredList =
          list
              .where(
                (shift) =>
                    shift.posDeviceId == posDeviceModel.id &&
                    shift.closedAt == null,
              )
              .toList()
            ..sort(
              (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
                a.createdAt ?? DateTime.now(),
              ),
            );

      if (filteredList.isNotEmpty) {
        return filteredList.first;
      }
    }
    // if (posDeviceModel.id == null) {
    //   return ShiftModel();
    // }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$closedAt IS NULL AND $posDeviceId = ?',
      orderBy: '$createdAt DESC',
      whereArgs: [posDeviceModel.id ?? '-1'],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ShiftModel.fromJson(maps.first);
    } else {
      return ShiftModel();
    }
  }

  @override
  Future<ShiftModel> getShiftWhereClosedBy(
    String staffId,
    String idPosDevice,
  ) async {
    List<ShiftModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => ShiftModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      final filteredList = list.where(
        (element) =>
            element.closedBy == staffId && element.posDeviceId == idPosDevice,
      );

      if (filteredList.isNotEmpty) {
        return filteredList.last;
      }
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$closedBy = ? AND $posDeviceId = ?',
      whereArgs: [staffId, idPosDevice],
    );
    if (maps.isNotEmpty) {
      return ShiftModel.fromJson(maps.last);
    } else {
      return ShiftModel();
    }
  }

  @override
  Future<List<ShiftModel>> getListShiftForHistory() async {
    List<ShiftModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => ShiftModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list.where((element) => element.closedAt != null).toList();
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$closedAt NOT NULL',
      orderBy: '$createdAt DESC',
    );
    return List.generate(maps.length, (index) {
      return ShiftModel.fromJson(maps[index]);
    });
  }

  @override
  Future<List<ShiftModel>> getListShiftModel() async {
    List<ShiftModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => ShiftModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list;
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);

    List<ShiftModel> shifts = List.generate(maps.length, (index) {
      return ShiftModel.fromJson(maps[index]);
    });

    return shifts;
  }

  ///==================================[FOR STREAM]==================================
  // get expected amount from latest shift
  @override
  Future<void> emitLatestExpectedAmount() async {
    double expectedCash = await getLatestExpectedCash();
    _latestExpectedAmountStreamController.add(expectedCash);
  }

  @override
  Future<void> notifyChanges() async {
    await emitLatestExpectedAmount();
  }

  @override
  Future<bool> replaceAllData(
    List<ShiftModel> newData, {
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

      notifyChanges();
      return true;
    } catch (e) {
      prints('Error replacing all data in $tableName: $e');
      return false;
    }
  }
}
