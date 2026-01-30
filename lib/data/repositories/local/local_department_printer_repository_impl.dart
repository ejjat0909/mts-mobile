import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/department_printer_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

final departmentPrinterBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(DepartmentPrinterModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final departmentPrinterLocalRepoProvider =
    Provider<LocalDepartmentPrinterRepository>((ref) {
      return LocalDepartmentPrinterRepositoryImpl(
        dbHelper: ref.read(databaseHelpersProvider),
        pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
        hiveBox: ref.read(departmentPrinterBoxProvider),
      );
    });

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalDepartmentPrinterRepository] that uses local database
class LocalDepartmentPrinterRepositoryImpl
    implements LocalDepartmentPrinterRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String tableName = 'department_printers';
  static const String cId = 'id';
  static const String categories = 'categories';
  static const String name = 'name';
  static const String companyId = 'company_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  /// Constructor
  LocalDepartmentPrinterRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the department printer table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $name TEXT NULL,
      $categories TEXT NULL,
      $companyId TEXT NULL,
      $createdAt TEXT NULL,
      $updatedAt TEXT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  @override
  Future<int> insert(
    DepartmentPrinterModel model, {
    required bool isInsertToPending,
  }) async {
    try {
      // Insert to SQLite
      int result = await _dbHelper.insertDb(tableName, model.toJson());

      // Insert to Hive
      await _hiveBox.put(model.id!.toString(), model.toJson());

      if (isInsertToPending) {
        await _insertPending(model, 'created');
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error inserting department printer', e);
      rethrow;
    }
  }

  @override
  Future<int> update(
    DepartmentPrinterModel model, {
    required bool isInsertToPending,
  }) async {
    try {
      // Update SQLite
      int result = await _dbHelper.updateDb(tableName, model.toJson());

      // Update Hive
      await _hiveBox.put(model.id!.toString(), model.toJson());

      if (isInsertToPending) {
        await _insertPending(model, 'updated');
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error updating department printer', e);
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
          fromJson: (json) => DepartmentPrinterModel.fromJson(json),
        ) ??
        DepartmentPrinterModel(id: id);

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
      await LogUtils.error('Error deleting department printer', e);
      rethrow;
    }
  }

  // ==================== Bulk Operations ====================

  @override
  Future<bool> upsertBulk(
    List<DepartmentPrinterModel> models, {
    required bool isInsertToPending,
  }) async {
    try {
      Database db = await _dbHelper.database;
      final batch = db.batch();
      final List<PendingChangesModel> pendingList = [];

      for (var model in models) {
        // Note: id is auto-generated by SQLite (INTEGER PRIMARY KEY)

        batch.insert(
          tableName,
          model.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (isInsertToPending) {
          pendingList.add(
            PendingChangesModel(
              operation: 'created',
              modelName: DepartmentPrinterModel.modelName,
              modelId: model.id!.toString(),
              data: jsonEncode(model.toJson()),
            ),
          );
        }
      }

      await batch.commit(noResult: true);

      // Bulk insert to Hive
      final dataMap = <dynamic, Map<dynamic, dynamic>>{};
      for (var model in models) {
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
      await LogUtils.error('Error bulk inserting department printers', e);
      return false;
    }
  }

  Future<bool> replaceAllData(
    List<DepartmentPrinterModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(tableName); // Delete all rows from SQLite
      await _hiveBox.clear(); // Clear Hive
      return await upsertBulk(newData, isInsertToPending: isInsertToPending);
    } catch (e) {
      await LogUtils.error('Error replacing all department printers', e);
      return false;
    }
  }

  // ==================== Query Operations ====================

  Future<List<DepartmentPrinterModel>> getListDepartmentPrinters() async {
    // Try Hive cache first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => DepartmentPrinterModel.fromJson(json),
    );
    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final maps = await _dbHelper.readDb(tableName);
    return maps.map((json) => DepartmentPrinterModel.fromJson(json)).toList();
  }

  /// Get single model by ID (Hive-first, fallback to SQLite)
  Future<DepartmentPrinterModel?> getById(String id) async {
    // Try Hive cache first
    final hiveModel = HiveSyncHelper.getById(
      box: _hiveBox,
      id: id,
      fromJson: (json) => DepartmentPrinterModel.fromJson(json),
    );
    if (hiveModel != null) {
      return hiveModel;
    }

    // Fallback to SQLite
    final map = await _dbHelper.readDbById(tableName, id);
    if (map != null) {
      return DepartmentPrinterModel.fromJson(map);
    }
    return null;
  }

  // ==================== Delete Operations ====================

  Future<bool> deleteAll() async {
    try {
      // Delete from SQLite
      final db = await _dbHelper.database;
      await db.delete(tableName);

      // Delete from Hive
      await _hiveBox.clear();

      return true;
    } catch (e) {
      await LogUtils.error('Error deleting all department printers', e);
      return false;
    }
  }

  // ==================== Helper Methods ====================

  Future<void> _insertPending(
    DepartmentPrinterModel model,
    String operation,
  ) async {
    final pending = PendingChangesModel(
      operation: operation,
      modelName: DepartmentPrinterModel.modelName,
      modelId: model.id!.toString(),
      data: jsonEncode(model.toJson()),
    );
    await _pendingChangesRepository.insert(pending);
  }

  /// Delete multiple department printer records
  @override
  Future<bool> deleteBulk(
    List<DepartmentPrinterModel> list, {
    required bool isInsertToPending,
  }) async {
    try {
      for (var printer in list) {
        if (printer.id != null) {
          await delete(
            printer.id.toString(),
            isInsertToPending: isInsertToPending,
          );
        }
      }
      return true;
    } catch (e) {
      await LogUtils.error('Error deleting bulk department printers', e);
      return false;
    }
  }

  /// Get all department printer records

  Future<List<DepartmentPrinterModel>> getListDepartmentPrinterModels() async {
    // ✅ Try Hive first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => DepartmentPrinterModel.fromJson(json),
    );

    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return DepartmentPrinterModel.fromJson(maps[index]);
    });
  }

  /// Get a department printer record by ID

  Future<DepartmentPrinterModel?> getDepartmentPrinterModelByIdAlt(
    String printerId,
  ) async {
    // Try Hive cache first
    final fromHive = HiveSyncHelper.getById<DepartmentPrinterModel>(
      box: _hiveBox,
      id: printerId,
      fromJson: (json) => DepartmentPrinterModel.fromJson(json),
    );
    if (fromHive != null) return fromHive;

    // Fallback to SQLite
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [printerId],
    );

    if (maps.isNotEmpty) {
      return DepartmentPrinterModel.fromJson(maps.first);
    }

    return null;
  }

  List<DepartmentPrinterModel> getListDepartmentPrinterFromHive() {
    return HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => DepartmentPrinterModel.fromJson(json),
    );
  }

  Future<List<DepartmentPrinterModel>> getListDepartmentPrinterModel() async {
    final hiveList = getListDepartmentPrinterFromHive();
    if (hiveList.isNotEmpty) {
      return hiveList;
    }
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(tableName);
    List<DepartmentPrinterModel> list = [];

    for (var element in maps) {
      list.add(DepartmentPrinterModel.fromJson(element));
    }

    return list;
  }

  /// Get a department printer record by ID

  Future<DepartmentPrinterModel?> getDepartmentPrinterModelById(
    String printerId,
  ) async {
    // Try Hive cache first
    final fromHive = HiveSyncHelper.getById<DepartmentPrinterModel>(
      box: _hiveBox,
      id: printerId,
      fromJson: (json) => DepartmentPrinterModel.fromJson(json),
    );
    if (fromHive != null) return fromHive;

    // Fallback to SQLite
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [printerId],
    );

    if (maps.isNotEmpty) {
      return DepartmentPrinterModel.fromJson(maps.first);
    }

    return null;
  }

  // get list
  @override
  Future<List<DepartmentPrinterModel>> getListDepartmentPrinter() async {
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => DepartmentPrinterModel.fromJson(json),
    );
    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final maps = await _dbHelper.readDb(tableName);
    return maps.map((json) => DepartmentPrinterModel.fromJson(json)).toList();
  }

  // get by id
  @override
  Future<DepartmentPrinterModel?> getDepartmentPrinterById(
    String printerId,
  ) async {
    // Try Hive cache first
    final fromHive = HiveSyncHelper.getById<DepartmentPrinterModel>(
      box: _hiveBox,
      id: printerId,
      fromJson: (json) => DepartmentPrinterModel.fromJson(json),
    );
    if (fromHive != null) return fromHive;

    // Fallback to SQLite
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [printerId],
    );

    if (maps.isNotEmpty) {
      return DepartmentPrinterModel.fromJson(maps.first);
    }

    return null;
  }

  @override
  Future<List<DepartmentPrinterModel>> getListDepartmentPrintersFromIds(
    List<String> departments,
  ) async {
    if (departments.isEmpty) return [];

    // Try Hive cache first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => DepartmentPrinterModel.fromJson(json),
    );
    if (hiveList.isNotEmpty) {
      return hiveList
          .where((element) => departments.contains(element.id))
          .toList();
    }

    // Fallback to SQLite
    Database db = await _dbHelper.database;

    // Generate placeholders like (?, ?, ?, ...)
    final placeholders = List.filled(departments.length, '?').join(',');

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId IN ($placeholders)',
      whereArgs: departments,
    );

    return List.generate(maps.length, (i) {
      return DepartmentPrinterModel.fromJson(maps[i]);
    });
  }
}
