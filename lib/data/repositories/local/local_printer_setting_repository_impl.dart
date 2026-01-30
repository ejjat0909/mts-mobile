import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/enum/printer_setting_enum.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_device_repository_impl.dart';
import 'package:mts/data/repositories/local/local_outlet_repository_impl.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/domain/repositories/local/device_repository.dart';
import 'package:mts/domain/repositories/local/outlet_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/printer_setting_repository.dart';
import 'package:sqflite/sqflite.dart';

final printerSettingBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(PrinterSettingModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final printerSettingLocalRepoProvider = Provider<LocalPrinterSettingRepository>(
  (ref) {
    return LocalPrinterSettingRepositoryImpl(
      dbHelper: ref.read(databaseHelpersProvider),
      pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
      hiveBox: ref.read(printerSettingBoxProvider),
      outletLocalRepository: ref.read(outletLocalRepoProvider),
      deviceLocalRepository: ref.read(deviceLocalRepoProvider),
    );
  },
);

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalPrinterSettingRepository] that uses local database
class LocalPrinterSettingRepositoryImpl
    implements LocalPrinterSettingRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;
  final LocalOutletRepository _outletLocalRepository;
  final LocalDeviceRepository _deviceLocalRepository;

  /// Database table and column names
  static const String cId = 'id';
  static const String name = 'name';
  static const String model = 'model';
  static const String interface = 'interface';
  static const String identifierAddress = 'identifier_address';
  static const String paperWidth = 'paper_width';
  static const String categories = 'categories';
  static const String departmentJson = 'department_printer_json';
  static const String printReceiptBills = 'print_receipt_bills';
  static const String printOrders = 'print_orders';
  static const String automaticallyPrintReceipt = 'automatically_print_receipt';
  static const String outletId = 'outlet_id';
  static const String customCdCommand = 'custom_cd_command';
  static const String posDeviceId = 'pos_device_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String tableName = 'printer_settings';

  /// Constructor
  LocalPrinterSettingRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
    required LocalOutletRepository outletLocalRepository,
    required LocalDeviceRepository deviceLocalRepository,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _outletLocalRepository = outletLocalRepository,
       _deviceLocalRepository = deviceLocalRepository,
       _hiveBox = hiveBox;

  /// Create the printer setting table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $name TEXT NULL,
      $model TEXT NULL,
      $interface TEXT NULL,
      $identifierAddress TEXT NULL,
      $paperWidth TEXT NULL,
      $printReceiptBills INTEGER DEFAULT 0,
      $printOrders INTEGER DEFAULT 0,
      $automaticallyPrintReceipt INTEGER DEFAULT 0,
      $categories TEXT NULL,
      $departmentJson TEXT NULL,
      $outletId TEXT DEFAULT NULL,
      $customCdCommand TEXT DEFAULT NULL,
      $posDeviceId TEXT DEFAULT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new printer setting
  @override
  Future<int> insert(
    PrinterSettingModel printerSetting, {
    required bool isInsertToPending,
  }) async {
    printerSetting.id ??= IdUtils.generateUUID().toString();
    printerSetting.updatedAt = DateTime.now();
    printerSetting.createdAt = DateTime.now();
    int result = await _dbHelper.insertDb(tableName, printerSetting.toJson());

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'created',
        modelName: PrinterSettingModel.modelName,
        modelId: printerSetting.id!,
        data: jsonEncode(printerSetting.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
      await _hiveBox.put(printerSetting.id, printerSetting.toJson());
    }

    return result;
  }

  // update
  @override
  Future<int> update(
    PrinterSettingModel printerSetting, {
    required bool isInsertToPending,
  }) async {
    int result = await _dbHelper.updateDb(tableName, printerSetting.toJson());

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: PrinterSettingModel.modelName,
        modelId: printerSetting.id!,
        data: jsonEncode(printerSetting.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
      await _hiveBox.put(printerSetting.id, printerSetting.toJson());
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
      final model = PrinterSettingModel.fromJson(results.first);

      // Delete the record
      await _hiveBox.delete(id);
      int result = await _dbHelper.deleteDb(tableName, id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: PrinterSettingModel.modelName,
          modelId: model.id!,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No printer setting record found with id: $id');
      return 0;
    }
  }

  /// Get all printer settings without filters
  @override
  Future<List<PrinterSettingModel>> getAllPrinterSettings() async {
    List<PrinterSettingModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: PrinterSettingModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list;
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (index) {
      return PrinterSettingModel.fromJson(maps[index]);
    });
  }

  // get list printer setting
  @override
  Future<List<PrinterSettingModel>> getListPrinterSetting({
    bool isByOutlet = false,
  }) async {
    PosDeviceModel posDeviceModel =
        await _deviceLocalRepository.getLatestDeviceModel();
    OutletModel outletModel =
        await _outletLocalRepository.getLatestOutletModel();

    /// [filter not have usb because no code setup for usb]
    // Get list from Hive first
    List<PrinterSettingModel> listPrinterSetting =
        HiveSyncHelper.getListFromBox(
          box: _hiveBox,
          fromJson: PrinterSettingModel.fromJson,
        );

    // If Hive is empty, fallback to SQLite
    if (listPrinterSetting.isEmpty) {
      Database db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        // Filtering condition by outlet id or pos device id based on the flag
        where:
            isByOutlet
                ? '$interface != ? AND $outletId = ?'
                : '$interface != ? AND $posDeviceId = ?',
        whereArgs:
            isByOutlet
                ? [PrinterSettingEnum.usb, outletModel.id]
                : [PrinterSettingEnum.usb, posDeviceModel.id],
      );

      listPrinterSetting = List.generate(maps.length, (index) {
        return PrinterSettingModel.fromJson(maps[index]);
      });
    } else {
      // Apply the same filtering logic as the original db.query
      // Filter 1: interface != usb
      listPrinterSetting =
          listPrinterSetting
              .where((item) => item.interface != PrinterSettingEnum.usb)
              .toList();

      // Filter 2: outlet id or pos device id based on the flag
      listPrinterSetting =
          listPrinterSetting.where((item) {
            if (isByOutlet) {
              return item.outletId == outletModel.id;
            } else {
              return item.posDeviceId == posDeviceModel.id;
            }
          }).toList();
    }

    // Sort the list by `updatedAt` in descending order
    listPrinterSetting.sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));
    return listPrinterSetting;
  }

  // get printer setting that categories not null
  @override
  Future<List<PrinterSettingModel>> getListPrinterSettingDepartment() async {
    List<PrinterSettingModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: PrinterSettingModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list
          .where((element) => element.departmentPrinterJson != null)
          .toList();
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$departmentJson NOT NULL',
    );
    return List.generate(maps.length, (index) {
      return PrinterSettingModel.fromJson(maps[index]);
    });
  }

  // check ip address existence
  @override
  Future<bool> checkIpAddressExist(String ipAddress) async {
    PosDeviceModel posDeviceModel =
        await _deviceLocalRepository.getLatestDeviceModel();

    List<PrinterSettingModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: PrinterSettingModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list
          .where(
            (element) =>
                element.identifierAddress == ipAddress &&
                element.posDeviceId == posDeviceModel.id,
          )
          .isNotEmpty;
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$identifierAddress = ? AND $posDeviceId = ?',
      whereArgs: [ipAddress, posDeviceModel.id],
    );
    return maps.isNotEmpty;
  }

  @override
  Future<bool> updatePrinterSetting(PrinterSettingModel model) async {
    PosDeviceModel posDeviceModel =
        await _deviceLocalRepository.getLatestDeviceModel();

    List<PrinterSettingModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: PrinterSettingModel.fromJson,
    );
    if (list.isNotEmpty) {
      final filteredList =
          list
              .where(
                (element) =>
                    element.identifierAddress == model.identifierAddress &&
                    element.id != model.id &&
                    element.posDeviceId == posDeviceModel.id,
              )
              .toList();

      if (filteredList.isEmpty) {
        // Safe to update - IP doesn't exist for another printer
        await update(model, isInsertToPending: true);
        await _hiveBox.put(model.id, model.toJson());
        return true;
      }
      // If filteredList is not empty, fall through to SQLite to verify
    }

    // Fallback to SQLite
    Database db = await _dbHelper.database;

    // Check if the IP address exists and pos device id exist for a different ID
    final existingPrinter = await db.query(
      tableName,
      where: '$identifierAddress = ? AND $cId != ? AND $posDeviceId = ?',
      whereArgs: [model.identifierAddress, model.id, posDeviceModel.id],
    );

    if (existingPrinter.isNotEmpty) {
      // IP address already exists for another printer
      return false;
    }

    // Proceed with updating the PrinterSettingModel
    await update(model, isInsertToPending: true);

    return true;
  }

  // insert bulk
  @override
  Future<bool> upsertBulk(
    List<PrinterSettingModel> list, {
    required bool isInsertToPending,
  }) async {
    try {
      Database db = await _dbHelper.database;
      // First, collect all existing IDs in a single query
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
      final pendingChanges = <PendingChangesModel>[];

      // Use a single batch for all operations (atomic)
      final batch = db.batch();

      for (final model in list) {
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
                modelName: PrinterSettingModel.modelName,
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
                modelName: PrinterSettingModel.modelName,
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
      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      prints('Error inserting bulk printer setting: $e');
      return false;
    }
  }

  /// Delete multiple printer settings
  @override
  Future<bool> deleteBulk(
    List<PrinterSettingModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    List<String> listIds = list.map((e) => e.id!).toList();
    if (listIds.isEmpty) {
      return false;
    }

    try {
      // Insert to pending changes if required
      if (isInsertToPending) {
        for (PrinterSettingModel model in list) {
          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: PrinterSettingModel.modelName,
            modelId: model.id!,
            data: jsonEncode(model.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }

      String whereIn = listIds.map((_) => '?').join(',');
      await db.delete(
        tableName,
        where: '$cId IN ($whereIn)',
        whereArgs: listIds,
      );
      await _hiveBox.deleteAll(listIds);
      return true;
    } catch (e) {
      prints('Error deleting bulk printer settings: $e');
      return false;
    }
  }

  /// Delete all printer settings
  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await Future.wait([_hiveBox.clear(), db.delete(tableName)]);

      return true;
    } catch (e) {
      prints('Error deleting all printer settings: $e');
      return false;
    }
  }

  /// Replace all data in the table with new data
  @override
  Future<bool> replaceAllData(
    List<PrinterSettingModel> newData, {
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

  /// Get a printer setting by its ID
  @override
  Future<PrinterSettingModel?> getPrinterSettingModelById(String id) async {
    try {
      List<PrinterSettingModel> list = HiveSyncHelper.getListFromBox(
        box: _hiveBox,
        fromJson: PrinterSettingModel.fromJson,
      );
      final hiveModel = list.firstWhere(
        (element) => element.id == id,
        orElse: () => throw Exception('Not found in Hive'),
      );
      return hiveModel;
    } catch (e) {
      Database db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: '$cId = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return PrinterSettingModel.fromJson(maps.first);
      }
      return null;
    }
  }

  /// Get list printer settings filtered by device
  @override
  Future<List<PrinterSettingModel>> getListPrinterSettingByDevice({
    required bool isForThisDevice,
  }) async {
    PosDeviceModel posDeviceModel =
        await _deviceLocalRepository.getLatestDeviceModel();

    // Get list from Hive first
    List<PrinterSettingModel> listPrinterSetting =
        HiveSyncHelper.getListFromBox(
          box: _hiveBox,
          fromJson: PrinterSettingModel.fromJson,
        );

    // If Hive is empty, fallback to SQLite
    if (listPrinterSetting.isEmpty) {
      Database db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: isForThisDevice ? '$posDeviceId = ?' : '$posDeviceId != ?',
        whereArgs: [posDeviceModel.id],
      );

      listPrinterSetting = List.generate(maps.length, (index) {
        return PrinterSettingModel.fromJson(maps[index]);
      });
    } else {
      // Apply filtering on Hive data
      listPrinterSetting =
          listPrinterSetting.where((item) {
            if (isForThisDevice) {
              return item.posDeviceId == posDeviceModel.id;
            } else {
              return item.posDeviceId != posDeviceModel.id;
            }
          }).toList();
    }

    // Sort the list by `updatedAt` in descending order
    listPrinterSetting.sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));
    return listPrinterSetting;
  }
}
