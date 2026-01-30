import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/division/division_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/division_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

final divisionBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(DivisionModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final divisionLocalRepoProvider = Provider<LocalDivisionRepository>((ref) {
  return LocalDivisionRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(divisionBoxProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalDivisionRepository] that uses local database
class LocalDivisionRepositoryImpl implements LocalDivisionRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String cId = 'id';
  static const String cCode = 'code';
  static const String cCountryId = 'division_id';
  static const String cFullName = 'full_name';
  static const String cHasCity = 'has_city';
  static const String cName = 'name';
  static const String tableName = 'divisions';

  /// Constructor
  LocalDivisionRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the division table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId INTEGER PRIMARY KEY,
      $cCode TEXT NULL,
      $cCountryId INTEGER NULL,
      $cFullName TEXT NULL,
      $cHasCity INTEGER NULL,
      $cName TEXT NULL
    ''';

    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  @override
  Future<int> insert(
    DivisionModel divisionModel, {
    required bool isInsertToPending,
  }) async {
    try {
      // Insert to SQLite
      int result = await _dbHelper.insertDb(tableName, divisionModel.toJson());

      // Insert to Hive
      await _hiveBox.put(divisionModel.id!.toString(), divisionModel.toJson());

      if (isInsertToPending) {
        await _insertPending(divisionModel, 'created');
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error inserting division', e);
      rethrow;
    }
  }

  @override
  Future<int> update(
    DivisionModel divisionModel, {
    required bool isInsertToPending,
  }) async {
    try {
      // Update SQLite
      int result = await _dbHelper.updateDb(tableName, divisionModel.toJson());

      // Update Hive
      await _hiveBox.put(divisionModel.id!.toString(), divisionModel.toJson());

      if (isInsertToPending) {
        await _insertPending(divisionModel, 'updated');
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error updating division', e);
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
          fromJson: (json) => DivisionModel.fromJson(json),
        ) ??
        DivisionModel(id: int.tryParse(id));

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
      await LogUtils.error('Error deleting division', e);
      rethrow;
    }
  }

  // ==================== Bulk Operations ====================

  @override
  Future<bool> upsertBulk(
    List<DivisionModel> list, {
    required bool isInsertToPending,
  }) async {
    try {
      Database db = await _dbHelper.database;
      final batch = db.batch();
      final List<PendingChangesModel> pendingList = [];

      for (var model in list) {
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
              modelName: DivisionModel.modelName,
              modelId: model.id!.toString(),
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
      await LogUtils.error('Error bulk inserting divisions', e);
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<DivisionModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(tableName); // Delete all rows from SQLite
      await _hiveBox.clear(); // Clear Hive
      return await upsertBulk(newData, isInsertToPending: isInsertToPending);
    } catch (e) {
      await LogUtils.error('Error replacing all divisions', e);
      return false;
    }
  }

  // ==================== Query Operations ====================

  Future<List<DivisionModel>> getListCountries() async {
    // Try Hive cache first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => DivisionModel.fromJson(json),
    );
    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final maps = await _dbHelper.readDb(tableName);
    return maps.map((json) => DivisionModel.fromJson(json)).toList();
  }

  /// Get single model by ID (Hive-first, fallback to SQLite)
  Future<DivisionModel?> getById(String id) async {
    // Try Hive cache first
    final hiveModel = HiveSyncHelper.getById(
      box: _hiveBox,
      id: id,
      fromJson: (json) => DivisionModel.fromJson(json),
    );
    if (hiveModel != null) {
      return hiveModel;
    }

    // Fallback to SQLite
    final map = await _dbHelper.readDbById(tableName, id);
    if (map != null) {
      return DivisionModel.fromJson(map);
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
      await LogUtils.error('Error deleting all divisions', e);
      return false;
    }
  }

  // ==================== Helper Methods ====================

  Future<void> _insertPending(DivisionModel model, String operation) async {
    final pending = PendingChangesModel(
      operation: operation,
      modelName: DivisionModel.modelName,
      modelId: model.id!.toString(),
      data: jsonEncode(model.toJson()),
    );
    await _pendingChangesRepository.insert(pending);
  }

  /// Delete multiple city records
  @override
  Future<bool> deleteBulk(
    List<DivisionModel> listCity, {
    required bool isInsertToPending,
  }) async {
    try {
      for (var city in listCity) {
        if (city.id != null) {
          await delete(
            city.id.toString(),
            isInsertToPending: isInsertToPending,
          );
        }
      }
      return true;
    } catch (e) {
      await LogUtils.error('Error deleting bulk cities', e);
      return false;
    }
  }

  /// Get all city records

  Future<List<DivisionModel>> getListCityModel() async {
    // ✅ Try Hive first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => DivisionModel.fromJson(json),
    );

    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return DivisionModel.fromJson(maps[index]);
    });
  }

  /// Get a city record by ID

  Future<DivisionModel?> getCityModelById(String cityId) async {
    // Try Hive cache first
    final fromHive = HiveSyncHelper.getById<DivisionModel>(
      box: _hiveBox,
      id: cityId,
      fromJson: (json) => DivisionModel.fromJson(json),
    );
    if (fromHive != null) return fromHive;

    // Fallback to SQLite
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [cityId],
    );

    if (maps.isNotEmpty) {
      return DivisionModel.fromJson(maps.first);
    }

    return null;
  }

  List<DivisionModel> getListCountryFromHive() {
    return HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => DivisionModel.fromJson(json),
    );
  }

  /// Get all division records
  @override
  Future<List<DivisionModel>> getListDivisionModel() async {
    final hiveList = getListCountryFromHive();
    if (hiveList.isNotEmpty) {
      return hiveList;
    }
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(tableName);
    List<DivisionModel> list = [];

    for (var element in maps) {
      list.add(DivisionModel.fromJson(element));
    }

    return list;
  }

  /// Get a division record by ID
  @override
  Future<DivisionModel?> getDivisionModelById(String divisionId) async {
    // Try Hive cache first
    final fromHive = HiveSyncHelper.getById<DivisionModel>(
      box: _hiveBox,
      id: divisionId,
      fromJson: (json) => DivisionModel.fromJson(json),
    );
    if (fromHive != null) return fromHive;

    // Fallback to SQLite
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [divisionId],
    );

    if (maps.isNotEmpty) {
      return DivisionModel.fromJson(maps.first);
    }

    return null;
  }
}
