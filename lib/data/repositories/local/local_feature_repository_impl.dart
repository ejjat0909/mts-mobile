import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/feature/feature_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/feature_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mts/core/storage/hive_box_manager.dart';

final featureBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(FeatureModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final featureLocalRepoProvider = Provider<LocalFeatureRepository>((ref) {
  return LocalFeatureRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    hiveBox: ref.read(featureBoxProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalFeatureRepository] that uses local database
class LocalFeatureRepositoryImpl implements LocalFeatureRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  static const String tableName = 'features';

  /// Database table and column names
  static const String cId = 'id';
  static const String cName = 'name';
  static const String cDescription = 'description';
  static const String cIcon = 'icon';
  static const String cCreatedAt = 'created_at';
  static const String cUpdatedAt = 'updated_at';

  /// Constructor
  LocalFeatureRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required Box<Map> hiveBox,
    required LocalPendingChangesRepository pendingChangesRepository,
  }) : _dbHelper = dbHelper,
       _hiveBox = hiveBox,
       _pendingChangesRepository = pendingChangesRepository;

  /// Create the features table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $cName TEXT NULL,
      $cDescription TEXT NULL,
      $cIcon TEXT NULL,
      $cUpdatedAt TIMESTAMP DEFAULT NULL,
      $cCreatedAt TIMESTAMP DEFAULT NULL
    ''';

    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new feature record
  @override
  Future<int> insert(
    FeatureModel featureModel, {
    required bool isInsertToPending,
  }) async {
    featureModel.id ??= IdUtils.generateUUID().toString();
    featureModel.updatedAt = DateTime.now();
    featureModel.createdAt = DateTime.now();

    try {
      // Insert to SQLite
      int result = await _dbHelper.insertDb(tableName, featureModel.toJson());

      // Insert to Hive
      await _hiveBox.put(featureModel.id!, featureModel.toJson());

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'created',
          modelName: FeatureModel.modelName,
          modelId: featureModel.id,
          data: jsonEncode(featureModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error inserting feature', e);
      rethrow;
    }
  }

  @override
  Future<int> update(
    FeatureModel featureModel, {
    required bool isInsertToPending,
  }) async {
    featureModel.updatedAt = DateTime.now();

    try {
      // Update SQLite
      int result = await _dbHelper.updateDb(tableName, featureModel.toJson());

      // Update Hive
      await _hiveBox.put(featureModel.id!, featureModel.toJson());

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'updated',
          modelName: FeatureModel.modelName,
          modelId: featureModel.id,
          data: jsonEncode(featureModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error updating feature', e);
      rethrow;
    }
  }

  @override
  Future<int> delete(String id, {required bool isInsertToPending}) async {
    try {
      // Get the model before deleting for pending changes
      Database db = await _dbHelper.database;
      List<Map<String, dynamic>> results = await db.query(
        tableName,
        where: '$cId = ?',
        whereArgs: [id],
      );

      // Delete from SQLite
      int result = await _dbHelper.deleteDb(tableName, id);

      // Delete from Hive
      await _hiveBox.delete(id);

      // Insert to pending changes if required
      if (isInsertToPending && results.isNotEmpty) {
        final model = FeatureModel.fromJson(results.first);
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: FeatureModel.modelName,
          modelId: model.id,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error deleting feature', e);
      rethrow;
    }
  }

  @override
  Future<bool> upsertBulk(
    List<FeatureModel> listFeatures, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // First, collect all existing IDs in a single query to check for creates vs updates
      final idsToInsert =
          listFeatures.map((m) => m.id).whereType<String>().toList();

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
      Batch batch = db.batch();

      for (FeatureModel model in listFeatures) {
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
                modelName: FeatureModel.modelName,
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
                modelName: FeatureModel.modelName,
                modelId: model.id!,
                data: jsonEncode(modelJson),
              ),
            );
          }
        }
      }

      // Commit batch atomically
      await batch.commit(noResult: true);

      // Bulk insert to Hive
      final dataMap = <dynamic, Map<dynamic, dynamic>>{};
      for (var model in listFeatures) {
        if (model.id != null) {
          dataMap[model.id!] = model.toJson();
        }
      }
      await _hiveBox.putAll(dataMap);

      // Track pending changes AFTER successful batch commit
      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      prints('Error inserting bulk features: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteBulk(
    List<FeatureModel> listFeatures, {
    required bool isInsertToPending,
  }) async {
    try {
      for (var feature in listFeatures) {
        if (feature.id != null) {
          await delete(feature.id!, isInsertToPending: isInsertToPending);
        }
      }
      return true;
    } catch (e) {
      await LogUtils.error('Error deleting bulk features', e);
      return false;
    }
  }

  @override
  Future<List<FeatureModel>> getListFeatures() async {
    // ✅ Try Hive first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => FeatureModel.fromJson(json),
    );

    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return FeatureModel.fromJson(maps[index]);
    });
  }

  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await db.delete(tableName);

      // Clear Hive box
      await _hiveBox.clear();

      return true;
    } catch (e) {
      prints('Error deleting all features: $e');
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<FeatureModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      // Step 1: Delete all existing data
      Database db = await _dbHelper.database;
      await db.delete(tableName);

      // Clear Hive box
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
