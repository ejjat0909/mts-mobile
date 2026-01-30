import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/data/repositories/local/local_item_tax_repository_impl.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/tax_repository.dart';
import 'package:sqflite/sqflite.dart';

final taxBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(TaxModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final taxLocalRepoProvider = Provider<LocalTaxRepository>((ref) {
  return LocalTaxRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    hiveBox: ref.read(taxBoxProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalTaxRepository] that uses local database
class LocalTaxRepositoryImpl implements LocalTaxRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;
  static const String tableName = 'taxes';

  /// Database table and column names
  static const String cId = 'id';
  static const String name = 'name';
  static const String rate = 'rate';
  static const String type = 'type';
  static const String option = 'option';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  static const String isOrderOptionChecked = 'is_order_option_checked';

  /// Constructor
  LocalTaxRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the tax table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $name TEXT NULL,
      $rate FLOAT NULL,
      $type TEXT NULL,
      $option TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL,
      $isOrderOptionChecked INTEGER DEFAULT 0
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new tax
  @override
  Future<int> insert(
    TaxModel taxModel, {
    required bool isInsertToPending,
  }) async {
    taxModel.id ??= IdUtils.generateUUID().toString();
    taxModel.updatedAt = DateTime.now();
    taxModel.createdAt = DateTime.now();

    try {
      // Insert to SQLite
      int result = await _dbHelper.insertDb(tableName, taxModel.toJson());

      // Insert to Hive
      await _hiveBox.put(taxModel.id!, taxModel.toJson());

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'created',
          modelName: TaxModel.modelName,
          modelId: taxModel.id,
          data: jsonEncode(taxModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error inserting cash management', e);
      rethrow;
    }
  }

  // update using model
  @override
  Future<int> update(
    TaxModel taxModel, {
    required bool isInsertToPending,
  }) async {
    taxModel.updatedAt = DateTime.now();
    try {
      // Update SQLite
      int result = await _dbHelper.updateDb(tableName, taxModel.toJson());

      // Update Hive
      await _hiveBox.put(taxModel.id!, taxModel.toJson());

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'updated',
          modelName: TaxModel.modelName,
          modelId: taxModel.id,
          data: jsonEncode(taxModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error updating cash management', e);
      rethrow;
    }
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

    await _hiveBox.delete(id);

    if (results.isNotEmpty) {
      final model = TaxModel.fromJson(results.first);

      // Delete the record
      int result = await _dbHelper.deleteDb(tableName, id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: TaxModel.modelName,
          modelId: model.id,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No tax record found with id: $id');
      return 0;
    }
  }

  // delete bulk
  @override
  Future<bool> deleteBulk(
    List<TaxModel> listTaxes, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    List<String> ids = listTaxes.map((e) => e.id!).toList();
    if (ids.isEmpty) {
      return false;
    }

    try {
      // If we need to insert to pending changes, get the models first
      if (isInsertToPending) {
        for (TaxModel tax in listTaxes) {
          // Insert to pending changes
          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: TaxModel.modelName,
            modelId: tax.id,
            data: jsonEncode(tax.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }

      String whereIn = ids.map((_) => '?').join(',');
      await _hiveBox.deleteAll(ids);
      await db.delete(tableName, where: '$cId IN ($whereIn)', whereArgs: ids);
      return true;
    } catch (e) {
      prints('Error deleting bulk tax: $e');
      return false;
    }
  }

  // delete all
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
      await LogUtils.error('Error deleting all tax', e);
      return false;
    }
  }

  // get list tax
  @override
  Future<List<TaxModel>> getListTaxModel() async {
    // ✅ Try Hive first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => TaxModel.fromJson(json),
    );

    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return TaxModel.fromJson(maps[index]);
    });
  }

  // insert bulk
  @override
  Future<bool> upsertBulk(
    List<TaxModel> list, {
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
              modelName: TaxModel.modelName,
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
      await LogUtils.error('Error bulk inserting tax', e);
      return false;
    }
  }

  @override
  Future<List<double>> getRatesByTaxIds(List<String> taxIds) async {
    Database db = await _dbHelper.database;

    // Prepare the placeholders and arguments
    final placeholders = List.filled(taxIds.length, '?').join(', ');
    final whereArgs = taxIds;

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: [rate], // Use the column name as a string
      where: '$cId IN ($placeholders)', // Use 'IN' clause for multiple IDs
      whereArgs: whereArgs,
    );

    // Return a list of rates
    return maps
        .map<double>((map) => map[rate]?.toDouble() ?? 0.0)
        .toList(); // Use the column name 'rate'
  }

  @override
  Future<List<TaxModel>> getTaxModelsByTaxIds(List<String> taxIds) async {
    if (taxIds.isEmpty) return [];

    // Try Hive cache first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => TaxModel.fromJson(json),
    );
    if (hiveList.isNotEmpty) {
      return hiveList.where((element) => taxIds.contains(element.id)).toList();
    }

    // Fallback to SQLite
    Database db = await _dbHelper.database;

    // Generate placeholders like (?, ?, ?, ...)
    final placeholders = List.filled(taxIds.length, '?').join(',');

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId IN ($placeholders)',
      whereArgs: taxIds,
    );

    return List.generate(maps.length, (i) {
      return TaxModel.fromJson(maps[i]);
    });
  }

  @override
  Future<List<TaxModel>> getTaxModelsByItemId(String idItem) async {
    Database db = await _dbHelper.database;
    String sql = '''
    SELECT t.* FROM ${LocalTaxRepositoryImpl.tableName} AS t
    INNER JOIN ${LocalItemTaxRepositoryImpl.tableName} AS it
    ON t.${LocalTaxRepositoryImpl.cId} = it.${LocalItemTaxRepositoryImpl.taxId}
    WHERE it.${LocalItemTaxRepositoryImpl.itemId} = ?;
    ''';

    // execute the query
    final List<Map<String, dynamic>> result = await db.rawQuery(sql, [idItem]);

    if (result.isEmpty) {
      prints('No tax found for item id: $idItem');
      return [];
    }

    return result.map((row) => TaxModel.fromJson(row)).toList();
  }

  @override
  Future<bool> replaceAllData(
    List<TaxModel> newData, {
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
