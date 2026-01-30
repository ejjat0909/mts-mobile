import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/country/country_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/country_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

final countryBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(CountryModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final countryLocalRepoProvider = Provider<LocalCountryRepository>((ref) {
  return LocalCountryRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(countryBoxProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalCountryRepository] that uses local database
class LocalCountryRepositoryImpl implements LocalCountryRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String cId = 'id';
  static const String cCallingCode = 'callingcode';
  static const String cCapital = 'capital';
  static const String cCode = 'code';
  static const String cCodeAlpha3 = 'code_alpha3';
  static const String cContinentId = 'continent_id';
  static const String cCurrencyCode = 'currency_code';
  static const String cCurrencyName = 'currency_name';
  static const String cEmoji = 'emoji';
  static const String cFullName = 'full_name';
  static const String cHasDivision = 'has_division';
  static const String cName = 'name';
  static const String cTld = 'tld';
  static const String tableName = 'countries';

  /// Constructor
  LocalCountryRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the country table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId INTEGER PRIMARY KEY,
      $cCallingCode TEXT NULL,
      $cCapital TEXT NULL,
      $cCode TEXT NULL,
      $cCodeAlpha3 TEXT NULL,
      $cContinentId INTEGER NULL,
      $cCurrencyCode TEXT NULL,
      $cCurrencyName TEXT NULL,
      $cEmoji TEXT NULL,
      $cFullName TEXT NULL,
      $cHasDivision INTEGER NULL,
      $cName TEXT NULL,
      $cTld TEXT NULL
    ''';

    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  @override
  Future<int> insert(
    CountryModel model, {
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
      await LogUtils.error('Error inserting country', e);
      rethrow;
    }
  }

  @override
  Future<int> update(
    CountryModel model, {
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
      await LogUtils.error('Error updating country', e);
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
          fromJson: (json) => CountryModel.fromJson(json),
        ) ??
        CountryModel(id: int.tryParse(id));

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
      await LogUtils.error('Error deleting country', e);
      rethrow;
    }
  }

  // ==================== Bulk Operations ====================

  @override
  Future<bool> upsertBulk(
    List<CountryModel> list, {
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
              modelName: CountryModel.modelName,
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
      await LogUtils.error('Error bulk inserting countries', e);
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<CountryModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(tableName); // Delete all rows from SQLite
      await _hiveBox.clear(); // Clear Hive
      return await upsertBulk(newData, isInsertToPending: isInsertToPending);
    } catch (e) {
      await LogUtils.error('Error replacing all countries', e);
      return false;
    }
  }

  // ==================== Query Operations ====================

  Future<List<CountryModel>> getListCountries() async {
    // Try Hive cache first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => CountryModel.fromJson(json),
    );
    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final maps = await _dbHelper.readDb(tableName);
    return maps.map((json) => CountryModel.fromJson(json)).toList();
  }

  /// Get single model by ID (Hive-first, fallback to SQLite)
  Future<CountryModel?> getById(String id) async {
    // Try Hive cache first
    final hiveModel = HiveSyncHelper.getById(
      box: _hiveBox,
      id: id,
      fromJson: (json) => CountryModel.fromJson(json),
    );
    if (hiveModel != null) {
      return hiveModel;
    }

    // Fallback to SQLite
    final map = await _dbHelper.readDbById(tableName, id);
    if (map != null) {
      return CountryModel.fromJson(map);
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
      await LogUtils.error('Error deleting all countries', e);
      return false;
    }
  }

  // ==================== Helper Methods ====================

  Future<void> _insertPending(CountryModel model, String operation) async {
    final pending = PendingChangesModel(
      operation: operation,
      modelName: CountryModel.modelName,
      modelId: model.id!.toString(),
      data: jsonEncode(model.toJson()),
    );
    await _pendingChangesRepository.insert(pending);
  }

  /// Delete multiple city records
  @override
  Future<bool> deleteBulk(
    List<CountryModel> listCity, {
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

  Future<List<CountryModel>> getListCityModel() async {
    // ✅ Try Hive first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => CountryModel.fromJson(json),
    );

    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return CountryModel.fromJson(maps[index]);
    });
  }

  /// Get a city record by ID

  Future<CountryModel?> getCityModelById(String cityId) async {
    // Try Hive cache first
    final fromHive = HiveSyncHelper.getById<CountryModel>(
      box: _hiveBox,
      id: cityId,
      fromJson: (json) => CountryModel.fromJson(json),
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
      return CountryModel.fromJson(maps.first);
    }

    return null;
  }

  /// Get all country records
  @override
  Future<List<CountryModel>> getListCountryModel() async {
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => CountryModel.fromJson(json),
    );

    if (hiveList.isNotEmpty) {
      return hiveList;
    }
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(tableName);
    List<CountryModel> list = [];

    for (var element in maps) {
      list.add(CountryModel.fromJson(element));
    }

    return list;
  }

  /// Get a country record by ID
  @override
  Future<CountryModel?> getCountryModelById(String countryId) async {
    // Try Hive cache first
    final fromHive = HiveSyncHelper.getById<CountryModel>(
      box: _hiveBox,
      id: countryId,
      fromJson: (json) => CountryModel.fromJson(json),
    );
    if (fromHive != null) return fromHive;

    // Fallback to SQLite
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [countryId],
    );

    if (maps.isNotEmpty) {
      return CountryModel.fromJson(maps.first);
    }

    return null;
  }
}
