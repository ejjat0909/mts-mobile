// ignore_for_file: constant_identifier_names

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

final pendingChangesBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(PendingChangesModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final pendingChangesLocalRepoProvider = Provider<LocalPendingChangesRepository>(
  (ref) {
    return LocalPendingChangesRepositoryImpl(
      dbHelper: ref.read(databaseHelpersProvider),
      hiveBox: ref.read(pendingChangesBoxProvider),
    );
  },
);

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalPendingChangesRepository] that uses local database
class LocalPendingChangesRepositoryImpl
    implements LocalPendingChangesRepository {
  final IDatabaseHelpers _dbHelper;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String tableName = 'pending_changes';
  static const String id = 'id';
  static const String operation = 'operation';
  static const String modelName = 'model_name';
  static const String modelId = 'model_id';
  static const String data = 'data';
  static const String createdAt = 'created_at';

  /// Constructor
  LocalPendingChangesRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _hiveBox = hiveBox;

  /// Create the pending changes table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $id TEXT PRIMARY KEY,
      $operation TEXT NULL,
      $modelName TEXT NULL,
      $modelId TEXT NULL,
      $data TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new pending change
  @override
  Future<int> insert(PendingChangesModel pendingChangesModel) async {
    pendingChangesModel.id ??= IdUtils.generateUUID().toString();
    pendingChangesModel.createdAt = DateTime.now();
    int result = await _dbHelper.insertDb(
      tableName,
      pendingChangesModel.toJson(),
    );
    await _hiveBox.put(pendingChangesModel.id, pendingChangesModel.toJson());
    return result;
  }

  // update
  // Future<int> update(PendingChangesModel pendingChangesModel) async {
  //   pendingChangesModel.updatedAt = DateTime.now();
  //   return await _dbHelper.updateDb(tableName, pendingChangesModel.toJson());
  // }

  // delete
  @override
  Future<int> delete(String id) async {
    await _hiveBox.delete(id);
    return await _dbHelper.deleteDb(tableName, id);
  }

  // getListPendingChanges
  @override
  Future<List<PendingChangesModel>> getListPendingChanges() async {
    try {
      List<PendingChangesModel> list = HiveSyncHelper.getListFromBox(
        box: _hiveBox,
        fromJson: PendingChangesModel.fromJson,
      );
      if (list.isNotEmpty) {
        return list;
      }
      final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);

      return List.generate(maps.length, (i) {
        return PendingChangesModel.fromJson(maps[i]);
      });
    } catch (e) {
      prints('Error reading pending changes: $e');
      return [];
    }
  }

  // insert bulk
  @override
  Future<bool> upsertBulk(List<PendingChangesModel> list) async {
    try {
      Database db = await _dbHelper.database;
      Batch batch = db.batch();

      for (PendingChangesModel pendingChanges in list) {
        // Check if the record exists
        List<Map<String, dynamic>> existingRecords = await db.query(
          tableName,
          where: '$id = ?',
          whereArgs: [pendingChanges.id],
        );

        if (existingRecords.isNotEmpty) {
          // If the record exists, update it
          batch.update(
            tableName,
            pendingChanges.toJson(),
            where: '$id = ?',
            whereArgs: [pendingChanges.id],
          );
        } else {
          // If the record does not exist, insert it
          batch.insert(tableName, pendingChanges.toJson());
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
      return true;
    } catch (e) {
      prints('Error inserting bulk pending changes: $e');
      return false;
    }
  }

  @override
  Future<void> deleteAll() async {
    Database db = await _dbHelper.database;
    await Future.wait([_hiveBox.clear(), db.delete(tableName)]);
  }

  @override
  Future<int> deleteWhereModelIdIsNull() async {
    try {
      Database db = await _dbHelper.database;

      // get pending changes where model id is null
      List<Map<String, dynamic>> records = await db.query(
        tableName,
        where: '$modelId IS NULL',
      );

      if (records.isEmpty) {
        return 0;
      }
      if (records.isNotEmpty) {
        List<PendingChangesModel> listPC = List.generate(records.length, (
          index,
        ) {
          return PendingChangesModel.fromJson(records[index]);
        });

        for (PendingChangesModel pc in listPC) {
          await LogUtils.error(
            pc.modelName != null
                ? 'Model id for ${pc.modelName} is null - operation ${pc.operation}'
                : "ada model id yang null, tapi takde nama model (RARE CASE)",
            null,
          );
        }
        await _hiveBox.delete('$id IS NULL');
        return await db.delete(tableName, where: '$modelId IS NULL');
      }

      return 0;
    } catch (e) {
      prints('Error deleting pending changes with null model id: $e');
      return 0;
    }
  }
}
