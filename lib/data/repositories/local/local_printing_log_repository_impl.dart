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
import 'package:mts/data/models/printing_log/printing_log_model.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/printing_log_repository.dart';
import 'package:sqflite/sqflite.dart';

final printerLogBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(PrintingLogModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final printingLogLocalRepoProvider = Provider<LocalPrintingLogRepository>((
  ref,
) {
  return LocalPrintingLogRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(printerLogBoxProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalPrintingLogRepository] that uses local database
class LocalPrintingLogRepositoryImpl implements LocalPrintingLogRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String cId = 'id';
  static const String cReason = 'reason';
  static const String cPrinterIp = 'printer_ip';
  static const String cPrinterName = 'printer_name';
  static const String cPosDeviceName = 'pos_device_name';
  static const String cPosDeviceId = 'pos_device_id';
  static const String cPrinterModel = 'printer_model';
  static const String cPrinterInterface = 'printer_interface';
  static const String cStaffName = 'staff_name';
  static const String cShiftId = 'shift_id';
  static const String cStatus = 'status';
  static const String cCompanyId = 'company_id';
  static const String cCreatedAt = 'created_at';
  static const String cUpdatedAt = 'updated_at';
  static const String cShiftStartAt = 'shift_start_at';
  static const String tableName = 'printing_logs';

  /// Constructor
  LocalPrintingLogRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the printing log table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $cReason TEXT NULL,
      $cPrinterIp TEXT NULL,
      $cPrinterName TEXT NULL,
      $cPosDeviceName TEXT NULL,
      $cPosDeviceId TEXT NULL,
      $cPrinterModel TEXT NULL,
      $cPrinterInterface TEXT NULL,
      $cStaffName TEXT NULL,
      $cShiftId TEXT NULL,
      $cStatus TEXT NULL,
      $cCompanyId TEXT NULL,
      $cShiftStartAt TIMESTAMP DEFAULT NULL,
      $cCreatedAt TIMESTAMP DEFAULT NULL,
      $cUpdatedAt TIMESTAMP DEFAULT NULL
    ''';

    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new printing log record
  @override
  Future<int> insert(
    PrintingLogModel printingLogModel, {
    required bool isInsertToPending,
  }) async {
    printingLogModel.id ??= IdUtils.generateUUID();
    printingLogModel.updatedAt = DateTime.now();
    printingLogModel.createdAt = DateTime.now();
    int result = await _dbHelper.insertDb(tableName, printingLogModel.toJson());
    await _hiveBox.put(printingLogModel.id, printingLogModel.toJson());
    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'created',
        modelName: PrintingLogModel.modelName,
        modelId: printingLogModel.id.toString(),
        data: jsonEncode(printingLogModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    return result;
  }

  // update
  @override
  Future<int> update(
    PrintingLogModel printingLogModel, {
    required bool isInsertToPending,
  }) async {
    printingLogModel.updatedAt = DateTime.now();
    int result = await _dbHelper.updateDb(tableName, printingLogModel.toJson());
    await _hiveBox.put(printingLogModel.id, printingLogModel.toJson());
    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: PrintingLogModel.modelName,
        modelId: printingLogModel.id.toString(),
        data: jsonEncode(printingLogModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    return result;
  }

  @override
  Future<int> delete(String id, {required bool isInsertToPending}) async {
    // Get the model before deleting it
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [int.parse(id)],
    );

    if (results.isNotEmpty) {
      final model = PrintingLogModel.fromJson(results.first);

      // Delete the record
      int result = await _dbHelper.deleteDb(tableName, int.parse(id));
      await _hiveBox.delete(id);
      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: PrintingLogModel.modelName,
          modelId: model.id.toString(),
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No printing log record found with id: $id');
      return 0;
    }
  }

  @override
  Future<bool> deleteBulk(
    List<PrintingLogModel> listPrintingLog, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    List<String> ids = listPrintingLog.map((e) => e.id!).toList();
    if (ids.isEmpty) {
      return false;
    }

    // If we need to insert to pending changes, we need to get the models first
    if (isInsertToPending) {
      for (PrintingLogModel printingLog in listPrintingLog) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: PrintingLogModel.modelName,
          modelId: printingLog.id.toString(),
          data: jsonEncode(printingLog.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }
    }

    String whereIn = ids.map((_) => '?').join(',');
    try {
      await db.delete(tableName, where: '$cId IN ($whereIn)', whereArgs: ids);
      await _hiveBox.deleteAll(ids);
      return true;
    } catch (e) {
      prints('Error deleting bulk printing logs: $e');
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
      prints('Error deleting all printing logs: $e');
      return false;
    }
  }

  List<PrintingLogModel> getListPrintingLogFromHive() {
    return HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => PrintingLogModel.fromJson(json),
    );
  }

  @override
  Future<List<PrintingLogModel>> getListPrintingLogModel() async {
    // ✅ Try Hive first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => PrintingLogModel.fromJson(json),
    );

    if (hiveList.isNotEmpty) {
      return hiveList;
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return PrintingLogModel.fromJson(maps[index]);
    });
  }

  //insert bulk
  @override
  Future<bool> upsertBulk(
    List<PrintingLogModel> listPrintingLog, {
    required bool isInsertToPending,
  }) async {
    try {
      Database db = await _dbHelper.database;
      // First, collect all existing IDs in a single query
      final idsToInsert =
          listPrintingLog.map((m) => m.id).whereType<int>().toList();

      final existingIds = <int>{};
      if (idsToInsert.isNotEmpty) {
        final placeholders = List.filled(idsToInsert.length, '?').join(',');
        final existingRecords = await db.query(
          tableName,
          where: '$cId IN ($placeholders)',
          whereArgs: idsToInsert,
          columns: [cId],
        );
        existingIds.addAll(existingRecords.map((r) => r[cId] as int));
      }

      // Prepare pending changes to track after batch commit
      final pendingChanges = <PendingChangesModel>[];

      // Use a single batch for all operations (atomic)
      final batch = db.batch();

      for (final model in listPrintingLog) {
        if (model.id == null) continue;

        final isExisting = existingIds.contains(model.id);
        final modelJson = model.toJson();

        if (isExisting) {
          // Only update if new item is newer than existing one
          batch.update(
            tableName,
            modelJson,
            where: '$cId = ? AND ($cUpdatedAt IS NULL OR $cUpdatedAt <= ?)',
            whereArgs: [
              model.id,
              DateTimeUtils.getDateTimeFormat(model.updatedAt),
            ],
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'updated',
                modelName: PrintingLogModel.modelName,
                modelId: model.id.toString(),
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
                modelName: PrintingLogModel.modelName,
                modelId: model.id.toString(),
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
          listPrintingLog
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
      prints('Error inserting bulk printing logs: $e');
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<PrintingLogModel> newData, {
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
