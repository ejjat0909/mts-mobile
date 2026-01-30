import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/enum/print_cache_status_enum.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_device_repository_impl.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/device_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/print_receipt_cache_repository.dart';
import 'package:sqflite/sqflite.dart';

final printReceiptBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(PrintReceiptCacheModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final printReceiptCacheLocalRepoProvider =
    Provider<LocalPrintReceiptCacheRepository>((ref) {
      return LocalPrintReceiptCacheRepositoryImpl(
        dbHelper: ref.read(databaseHelpersProvider),
        pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
        hiveBox: ref.read(printReceiptBoxProvider),
        deviceLocalRepository: ref.read(deviceLocalRepoProvider),
      );
    });

/// ================================
/// Local Repository Implementation
/// ================================
class LocalPrintReceiptCacheRepositoryImpl
    implements LocalPrintReceiptCacheRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;
  final LocalDeviceRepository _deviceLocalRepository;

  static const String tableName = 'print_receipt_caches';
  static const String cId = 'id';
  static const String cSaleId = 'sale_id';
  static const String cOutletId = 'outlet_id';
  static const String cShiftId = 'shift_id';
  static const String cPrintType = 'print_type';
  static const String cOrderNumber = 'order_number';
  static const String cTableNumber = 'table_number';
  static const String cPaperWidth = 'paper_width';
  static const String cPrintData = 'print_data';
  static const String cDepartmentPrinterId = 'department_printer_id';
  static const String cPrinterSettingId = 'printer_setting_id';
  static const String cPosDeviceId = 'pos_device_id';
  static const String cStatus = 'status';
  static const String cPrintedAttempts = 'printed_attempts';
  static const String cLastError = 'last_error';
  static const String cCreatedAt = 'created_at';
  static const String cPrintedAt = 'printed_at';
  static const String cUpdatedAt = 'updated_at';

  LocalPrintReceiptCacheRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
    required LocalDeviceRepository deviceLocalRepository,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox,
       _deviceLocalRepository = deviceLocalRepository;

  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $cSaleId TEXT NULL,
      $cOutletId TEXT NULL,
      $cShiftId TEXT NULL,
      $cPrintType TEXT NULL,
      $cOrderNumber INTEGER NULL,
      $cTableNumber TEXT NULL,
      $cPaperWidth TEXT NULL,
      $cPrintData TEXT NULL,
      $cDepartmentPrinterId TEXT NULL,
      $cPrinterSettingId TEXT NULL,
      $cPosDeviceId TEXT NULL,
      $cStatus TEXT NULL,
      $cPrintedAttempts INTEGER DEFAULT 0,
      $cLastError TEXT NULL,
      $cCreatedAt TIMESTAMP DEFAULT NULL,
      $cPrintedAt TIMESTAMP DEFAULT NULL,
      $cUpdatedAt TIMESTAMP DEFAULT NULL
    ''';

    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  @override
  Future<bool> tableExists() async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'sqlite_master',
      where: 'type = ? AND name = ?',
      whereArgs: ['table', tableName],
    );
    return result.isNotEmpty;
  }

  @override
  Future<int> insert(
    PrintReceiptCacheModel printReceiptCacheModel, {
    required bool isInsertToPending,
  }) async {
    printReceiptCacheModel.updatedAt = DateTime.now();
    printReceiptCacheModel.createdAt = DateTime.now();

    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'created',
        modelName: PrintReceiptCacheModel.modelName,
        modelId: printReceiptCacheModel.id.toString(),
        data: jsonEncode(printReceiptCacheModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }
    await _hiveBox.put(
      printReceiptCacheModel.id,
      printReceiptCacheModel.toJson(),
    );
    int result = await _dbHelper.insertDb(
      tableName,
      printReceiptCacheModel.toJson(),
    );

    return result;
  }

  @override
  Future<int> update(
    PrintReceiptCacheModel printReceiptCacheModel, {
    required bool isInsertToPending,
  }) async {
    printReceiptCacheModel.updatedAt = DateTime.now();
    await _hiveBox.put(
      printReceiptCacheModel.id,
      printReceiptCacheModel.toJson(),
    );
    int result = await _dbHelper.updateDb(
      tableName,
      printReceiptCacheModel.toJson(),
    );

    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: PrintReceiptCacheModel.modelName,
        modelId: printReceiptCacheModel.id.toString(),
        data: jsonEncode(printReceiptCacheModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    return result;
  }

  @override
  Future<int> delete(String id, {required bool isInsertToPending}) async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      final model = PrintReceiptCacheModel.fromJson(results.first);

      await _hiveBox.delete(id);
      int result = await _dbHelper.deleteDb(tableName, id);

      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: PrintReceiptCacheModel.modelName,
          modelId: model.id.toString(),
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      return 0;
    }
  }

  @override
  Future<List<PrintReceiptCacheModel>> getListPrintReceiptCacheModel() async {
    List<PrintReceiptCacheModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => PrintReceiptCacheModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list;
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return PrintReceiptCacheModel.fromJson(maps[index]);
    });
  }

  @override
  Future<bool> upsertBulk(
    List<PrintReceiptCacheModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      final List<PendingChangesModel> pendingChanges = [];
      final List<PrintReceiptCacheModel> toInsert = [];
      final List<PrintReceiptCacheModel> toUpdate = [];

      final Set<String> seenIds = {};

      for (PrintReceiptCacheModel newModel in list) {
        if (newModel.id == null) continue;

        if (seenIds.contains(newModel.id)) continue;
        seenIds.add(newModel.id!);

        final List<Map<String, dynamic>> recordsToUpdate = await db.query(
          tableName,
          where: '$cId = ? AND $cUpdatedAt < ?',
          whereArgs: [
            newModel.id,
            DateTimeUtils.getDateTimeFormat(newModel.updatedAt),
          ],
        );

        if (recordsToUpdate.isNotEmpty) {
          toUpdate.add(newModel);
        } else {
          final List<Map<String, dynamic>> existingRecords = await db.query(
            tableName,
            where: '$cId = ?',
            whereArgs: [newModel.id],
          );

          if (existingRecords.isEmpty) {
            toInsert.add(newModel);
          }
        }
      }

      Batch batch = db.batch();

      for (PrintReceiptCacheModel model in toInsert) {
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
              modelName: PrintReceiptCacheModel.modelName,
              modelId: model.id!.toString(),
              data: jsonEncode(modelJson),
            ),
          );
        }
      }

      for (PrintReceiptCacheModel model in toUpdate) {
        model.updatedAt = DateTime.now();
        final modelJson = model.toJson();
        final keys = modelJson.keys.toList();
        final placeholders = keys.map((key) => '$key=?').join(',');

        batch.rawUpdate(
          '''UPDATE $tableName SET $placeholders 
             WHERE $cId = ?''',
          [...modelJson.values, model.id],
        );

        if (isInsertToPending) {
          pendingChanges.add(
            PendingChangesModel(
              operation: 'updated',
              modelName: PrintReceiptCacheModel.modelName,
              modelId: model.id!.toString(),
              data: jsonEncode(modelJson),
            ),
          );
        }
      }

      await batch.commit(noResult: true);
      // Sync to Hive cache after successful batch commit
      await _hiveBox.putAll(
        Map.fromEntries(
          list
              .where((m) => m.id != null)
              .map((m) => MapEntry(m.id!, m.toJson())),
        ),
      );
      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteBulk(
    List<PrintReceiptCacheModel> printReceiptCaches, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    try {
      if (isInsertToPending) {
        for (PrintReceiptCacheModel cache in printReceiptCaches) {
          List<Map<String, dynamic>> results = await db.query(
            tableName,
            where: '$cId = ?',
            whereArgs: [cache.id],
          );

          if (results.isNotEmpty) {
            final model = PrintReceiptCacheModel.fromJson(results.first);

            final pendingChange = PendingChangesModel(
              operation: 'deleted',
              modelName: PrintReceiptCacheModel.modelName,
              modelId: model.id!.toString(),
              data: jsonEncode(model.toJson()),
            );
            await _pendingChangesRepository.insert(pendingChange);
          }
        }
      }

      for (PrintReceiptCacheModel cache in printReceiptCaches) {
        batch.delete(tableName, where: '$cId = ?', whereArgs: [cache.id]);
      }
      await _hiveBox.deleteAll(printReceiptCaches);
      await batch.commit(noResult: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await Future.wait([removeAllFromHive(), db.delete(tableName)]);
      await _hiveBox.clear();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeAllFromHive() async {
    try {
      if (_hiveBox.isNotEmpty) {
        await _hiveBox.clear();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<PrintReceiptCacheModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      Database db = await _dbHelper.database;
      await db.delete(tableName);
      await _hiveBox.clear();
      if (newData.isNotEmpty) {
        bool insertResult = await upsertBulk(
          newData,
          isInsertToPending: isInsertToPending,
        );
        if (!insertResult) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<PrintReceiptCacheModel>>
  getListPrintReceiptCacheWithPendingOrFailed() async {
    List<PrintReceiptCacheModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => PrintReceiptCacheModel.fromJson(json),
    );

    final filteredList =
        list
            .where(
              (item) =>
                  item.status == PrintCacheStatusEnum.pending ||
                  item.status == PrintCacheStatusEnum.failed,
            )
            .toList();

    if (filteredList.isNotEmpty) {
      return filteredList;
    }

    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cStatus = ? OR $cStatus = ?',
      whereArgs: [PrintCacheStatusEnum.pending, PrintCacheStatusEnum.failed],
    );
    return List.generate(maps.length, (index) {
      return PrintReceiptCacheModel.fromJson(maps[index]);
    });
  }

  @override
  Future<PrintReceiptCacheModel?> getModelBySaleId(String saleId) async {
    List<PrintReceiptCacheModel> hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => PrintReceiptCacheModel.fromJson(json),
    );

    try {
      final hiveModel = hiveList.firstWhere(
        (item) => item.saleId == saleId,
        orElse: () => throw StateError('Not found in Hive'),
      );
      return hiveModel;
    } catch (e) {
      Database db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: '$cSaleId = ?',
        whereArgs: [saleId],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return PrintReceiptCacheModel.fromJson(maps.first);
      }
      return null;
    }
  }

  @override
  Future<bool> deleteBySuccessAndCancelStatusAndFailed() async {
    PosDeviceModel posDeviceModel =
        await _deviceLocalRepository.getLatestDeviceModel();
    try {
      List<PrintReceiptCacheModel> records =
          HiveSyncHelper.getListFromBox(
                box: _hiveBox,
                fromJson: (json) => PrintReceiptCacheModel.fromJson(json),
              )
              .where(
                (item) =>
                    item.status == PrintCacheStatusEnum.success ||
                    item.status == PrintCacheStatusEnum.cancel ||
                    item.status == PrintCacheStatusEnum.failed ||
                    item.posDeviceId != posDeviceModel.id,
              )
              .toList();

      if (records.isEmpty) {
        Database db = await _dbHelper.database;
        final List<Map<String, dynamic>> maps = await db.query(
          tableName,
          where:
              '$cStatus = ? OR $cStatus = ? OR $cStatus = ? OR $cPosDeviceId != ?',
          whereArgs: [
            PrintCacheStatusEnum.success,
            PrintCacheStatusEnum.cancel,
            PrintCacheStatusEnum.failed,
            posDeviceModel.id,
          ],
        );
        records = List.generate(maps.length, (index) {
          return PrintReceiptCacheModel.fromJson(maps[index]);
        });
      }

      for (var record in records) {
        await delete(record.id!, isInsertToPending: false);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<PrintReceiptCacheModel>>
  getListPrintReceiptCacheWithPendingStatus() async {
    List<PrintReceiptCacheModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => PrintReceiptCacheModel.fromJson(json),
    );
    PosDeviceModel posDeviceModel =
        await _deviceLocalRepository.getLatestDeviceModel();

    final filteredList =
        list
            .where(
              (item) =>
                  item.status == PrintCacheStatusEnum.pending &&
                  item.posDeviceId == posDeviceModel.id,
            )
            .toList();

    if (filteredList.isNotEmpty) {
      return filteredList;
    }

    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cStatus = ? AND $cPosDeviceId = ?',
      whereArgs: [PrintCacheStatusEnum.pending, posDeviceModel.id],
    );
    return List.generate(maps.length, (index) {
      return PrintReceiptCacheModel.fromJson(maps[index]);
    });
  }

  @override
  Future<bool> onlyInsertToPending(PrintReceiptCacheModel model) async {
    try {
      final pendingChange = PendingChangesModel(
        operation: 'created',
        modelName: PrintReceiptCacheModel.modelName,
        modelId: model.id.toString(),
        data: jsonEncode(model.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<PrintReceiptCacheModel>>
  getListPrintReceiptCacheWithProcessingStatus() async {
    List<PrintReceiptCacheModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => PrintReceiptCacheModel.fromJson(json),
    );

    final filteredList =
        list
            .where((item) => item.status == PrintCacheStatusEnum.processing)
            .toList();

    if (filteredList.isNotEmpty) {
      return filteredList;
    }

    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cStatus = ?',
      whereArgs: [PrintCacheStatusEnum.processing],
    );
    return List.generate(maps.length, (index) {
      return PrintReceiptCacheModel.fromJson(maps[index]);
    });
  }
}
