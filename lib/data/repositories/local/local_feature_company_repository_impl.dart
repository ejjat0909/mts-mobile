import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/feature/feature_company_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/feature_company_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mts/core/storage/hive_box_manager.dart';

final featureCompanyBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(FeatureCompanyModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final featureCompanyLocalRepoProvider = Provider<LocalFeatureCompanyRepository>(
  (ref) {
    return LocalFeatureCompanyRepositoryImpl(
      dbHelper: ref.read(databaseHelpersProvider),
      hiveBox: ref.read(featureCompanyBoxProvider),
      pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    );
  },
);

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalFeatureCompanyRepository] that uses local database
class LocalFeatureCompanyRepositoryImpl
    implements LocalFeatureCompanyRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  static const String tableName = 'feature_companies';

  /// Database table and column names
  static const String cFeatureId = 'feature_id';
  static const String cCompanyId = 'company_id';
  static const String cIsActive = 'is_active';
  static const String cCreatedAt = 'created_at';
  static const String cUpdatedAt = 'updated_at';

  /// Constructor
  LocalFeatureCompanyRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required Box<Map> hiveBox,
    required LocalPendingChangesRepository pendingChangesRepository,
  }) : _dbHelper = dbHelper,
       _hiveBox = hiveBox,
       _pendingChangesRepository = pendingChangesRepository;

  /// Create the feature_companies table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cFeatureId TEXT DEFAULT NULL,
      $cCompanyId TEXT DEFAULT NULL,
      $cIsActive INTEGER DEFAULT 0,
      $cCreatedAt TIMESTAMP DEFAULT NULL,
      $cUpdatedAt TIMESTAMP DEFAULT NULL
    ''';

    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new feature company record
  @override
  Future<int> insert(FeatureCompanyModel featureCompanyModel) async {
    featureCompanyModel.updatedAt = DateTime.now();
    featureCompanyModel.createdAt = DateTime.now();

    try {
      // Insert to SQLite
      int result = await _dbHelper.insertDb(
        tableName,
        featureCompanyModel.toJson(),
      );

      // Insert to Hive using composite key
      final compositeKey =
          '${featureCompanyModel.featureId}_${featureCompanyModel.companyId}';
      await _hiveBox.put(compositeKey, featureCompanyModel.toJson());

      return result;
    } catch (e) {
      await LogUtils.error('Error inserting feature company', e);
      rethrow;
    }
  }

  @override
  Future<int> update(FeatureCompanyModel featureCompanyModel) async {
    featureCompanyModel.updatedAt = DateTime.now();

    try {
      // Update SQLite
      Database db = await _dbHelper.database;
      int result = await db.update(
        tableName,
        featureCompanyModel.toJson(),
        where: '$cFeatureId = ? AND $cCompanyId = ?',
        whereArgs: [
          featureCompanyModel.featureId,
          featureCompanyModel.companyId,
        ],
      );

      // Update Hive using composite key
      final compositeKey =
          '${featureCompanyModel.featureId}_${featureCompanyModel.companyId}';
      await _hiveBox.put(compositeKey, featureCompanyModel.toJson());

      return result;
    } catch (e) {
      await LogUtils.error('Error updating feature company', e);
      rethrow;
    }
  }

  @override
  Future<int> delete(String id) async {
    // Parse the composite ID to get featureId and companyId
    final parts = id.split('_');
    if (parts.length != 2) {
      prints('Invalid ID format for feature company: $id');
      return 0;
    }

    final featureId = parts[0];
    final companyId = parts[1];

    try {
      // Delete from SQLite
      Database db = await _dbHelper.database;
      int result = await db.delete(
        tableName,
        where: '$cFeatureId = ? AND $cCompanyId = ?',
        whereArgs: [featureId, companyId],
      );

      // Delete from Hive using composite key
      await _hiveBox.delete(id);

      return result;
    } catch (e) {
      await LogUtils.error('Error deleting feature company', e);
      rethrow;
    }
  }

  @override
  Future<bool> upsertBulk(
    List<FeatureCompanyModel> listFeatureCompanies, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // Prepare pending changes to track after batch commit
      final List<PendingChangesModel> pendingChanges = [];
      final List<FeatureCompanyModel> toInsert = [];
      final List<FeatureCompanyModel> toUpdate = [];

      // Build a set of composite keys already seen in this batch
      final Set<String> seenKeys = {};

      for (FeatureCompanyModel newModel in listFeatureCompanies) {
        if (newModel.featureId == null || newModel.companyId == null) continue;

        final compositeKey = '${newModel.featureId}_${newModel.companyId}';

        // Skip if already processed in this batch
        if (seenKeys.contains(compositeKey)) continue;
        seenKeys.add(compositeKey);

        // Query records that need updating (existing and older)
        final List<Map<String, dynamic>> recordsToUpdate = await db.query(
          tableName,
          where: '$cFeatureId = ? AND $cCompanyId = ? AND $cUpdatedAt < ?',
          whereArgs: [
            newModel.featureId,
            newModel.companyId,
            DateTimeUtils.getDateTimeFormat(newModel.updatedAt),
          ],
        );

        if (recordsToUpdate.isNotEmpty) {
          // Record exists and is older, add to update list
          toUpdate.add(newModel);
        } else {
          // Check if record exists at all
          final List<Map<String, dynamic>> existingRecords = await db.query(
            tableName,
            where: '$cFeatureId = ? AND $cCompanyId = ?',
            whereArgs: [newModel.featureId, newModel.companyId],
          );

          if (existingRecords.isEmpty) {
            // Record doesn't exist, add to insert list
            toInsert.add(newModel);
          }
          // else: record exists but is newer or equal, skip it
        }
      }

      // Use a single batch for all operations (atomic)
      Batch batch = db.batch();

      // Batch insert new records
      for (FeatureCompanyModel model in toInsert) {
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
              modelName: FeatureCompanyModel.modelName,
              modelId: '${model.featureId}_${model.companyId}',
              data: jsonEncode(modelJson),
            ),
          );
        }
      }

      // Batch update existing records
      for (FeatureCompanyModel model in toUpdate) {
        model.updatedAt = DateTime.now();
        final modelJson = model.toJson();
        final keys = modelJson.keys.toList();
        final placeholders = keys.map((key) => '$key=?').join(',');

        batch.rawUpdate(
          '''UPDATE $tableName SET $placeholders 
             WHERE $cFeatureId = ? AND $cCompanyId = ?''',
          [...modelJson.values, model.featureId, model.companyId],
        );

        if (isInsertToPending) {
          pendingChanges.add(
            PendingChangesModel(
              operation: 'updated',
              modelName: FeatureCompanyModel.modelName,
              modelId: '${model.featureId}_${model.companyId}',
              data: jsonEncode(modelJson),
            ),
          );
        }
      }

      // Commit batch atomically
      await batch.commit(noResult: true);

      // Bulk insert to Hive using composite keys
      final dataMap = <dynamic, Map<dynamic, dynamic>>{};
      for (var model in listFeatureCompanies) {
        if (model.featureId != null && model.companyId != null) {
          final compositeKey = '${model.featureId}_${model.companyId}';
          dataMap[compositeKey] = model.toJson();
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
      prints('Error inserting bulk feature companies: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteBulk(
    List<FeatureCompanyModel> listFeatureCompanies,
  ) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    if (listFeatureCompanies.isEmpty) {
      prints('No feature company ids provided for bulk delete');
      return false;
    }

    try {
      for (FeatureCompanyModel model in listFeatureCompanies) {
        batch.delete(
          tableName,
          where: '$cFeatureId = ? AND $cCompanyId = ?',
          whereArgs: [model.featureId, model.companyId],
        );
      }

      await batch.commit(noResult: true);

      // Delete from Hive using composite keys
      for (var model in listFeatureCompanies) {
        if (model.featureId != null && model.companyId != null) {
          final compositeKey = '${model.featureId}_${model.companyId}';
          await _hiveBox.delete(compositeKey);
        }
      }

      prints('Successfully deleted feature company ids');
      return true;
    } catch (e) {
      prints('Error deleting feature company ids: $e');
      return false;
    }
  }

  @override
  Future<List<FeatureCompanyModel>> getListFeatureCompanies() async {
    // ✅ Try Hive first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => FeatureCompanyModel.fromJson(json),
    );

    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return FeatureCompanyModel.fromJson(maps[index]);
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
      prints('Error deleting all feature companies: $e');
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<FeatureCompanyModel> newData, {
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

        // Step 3: Handle pending changes for insertion (since insertBulk doesn't support it)
        if (isInsertToPending) {
          final pendingChange = PendingChangesModel(
            operation: 'bulk_created',
            modelName: FeatureCompanyModel.modelName,
            modelId: 'all',
            data: jsonEncode(newData.map((e) => e.toJson()).toList()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }

      return true;
    } catch (e) {
      prints('Error replacing all data in $tableName: $e');
      return false;
    }
  }
}
