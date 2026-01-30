import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_outlet_repository_impl.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/page/page_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/outlet_repository.dart';
import 'package:mts/domain/repositories/local/page_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

final pageBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(PageModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final pageLocalRepoProvider = Provider<LocalPageRepository>((ref) {
  return LocalPageRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    hiveBox: ref.read(pageBoxProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    outletLocalRepository: ref.read(outletLocalRepoProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalPageRepository] that uses local database
class LocalPageRepositoryImpl implements LocalPageRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;
  final LocalOutletRepository _outletLocalRepository;

  /// Database table and column names
  static const String cId = 'id';
  static const String outletId = 'outlet_id';
  static const String pageName = 'page_name';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String tableName = 'pages';

  /// Constructor
  LocalPageRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
    required LocalOutletRepository outletLocalRepository,
  }) : _dbHelper = dbHelper,
       _outletLocalRepository = outletLocalRepository,
       _pendingChangesRepository = pendingChangesRepository,

       _hiveBox = hiveBox;

  /// Create the page table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $outletId TEXT NULL,
      $pageName TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new page
  @override
  Future<int> insert(
    PageModel pageModel, {
    required bool isInsertToPending,
  }) async {
    pageModel.updatedAt = DateTime.now();
    pageModel.createdAt = DateTime.now();

    try {
      // Insert to SQLite
      int result = await _dbHelper.insertDb(tableName, pageModel.toJson());

      // Insert to Hive
      await _hiveBox.put(pageModel.id!, pageModel.toJson());

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'created',
          modelName: PageModel.modelName,
          modelId: pageModel.id!,
          data: jsonEncode(pageModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error inserting page', e);
      rethrow;
    }
  }

  @override
  Future<int> update(
    PageModel pageModel, {
    required bool isInsertToPending,
  }) async {
    pageModel.updatedAt = DateTime.now();

    try {
      // Update SQLite
      int result = await _dbHelper.updateDb(tableName, pageModel.toJson());

      // Update Hive
      await _hiveBox.put(pageModel.id!, pageModel.toJson());

      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'updated',
          modelName: PageModel.modelName,
          modelId: pageModel.id!,
          data: jsonEncode(pageModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error updating page', e);
      rethrow;
    }
  }

  // delete
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
      final model = PageModel.fromJson(results.first);

      // Delete from Hive
      await _hiveBox.delete(id);

      // Delete the record
      int result = await _dbHelper.deleteDb(tableName, id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: PageModel.modelName,
          modelId: model.id,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No item record found with id: $id');
      return 0;
    }
  }

  // get list page
  @override
  Future<List<PageModel>> getListPage() async {
    Database db = await _dbHelper.database;
    OutletModel outletModel =
        await _outletLocalRepository.getLatestOutletModel();
    List<PageModel> list = [];

    if (outletModel.id == null) {
      return [];
    }

    list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => PageModel.fromJson(json),
    );

    if (list.isNotEmpty) {
      return list
          .where((element) => element.outletId == outletModel.id)
          .toList();
    }

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$outletId = ?',
      whereArgs: [outletModel.id],
    );
    list = List.generate(maps.length, (index) {
      return PageModel.fromJson(maps[index]);
    });

    return list;
  }

  // get first page
  @override
  Future<PageModel> getFirstPage() async {
    Database db = await _dbHelper.database;
    OutletModel outletModel =
        await _outletLocalRepository.getLatestOutletModel();
    List<PageModel> list = [];

    if (outletModel.id == null) {
      return PageModel();
    }

    list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => PageModel.fromJson(json),
    );

    if (list.isNotEmpty) {
      return list.where((element) => element.outletId == outletModel.id).first;
    }

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$outletId = ?',
      whereArgs: [outletModel.id],
    );
    return maps.isNotEmpty ? PageModel.fromJson(maps.first) : PageModel();
  }

  // insert bulk
  @override
  Future<bool> upsertBulk(
    List<PageModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // First, collect all existing IDs in a single query to check for creates vs updates
      // This eliminates the race condition: single query instead of per-item checks
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
      final List<PendingChangesModel> pendingChanges = [];

      // Use a single batch for all operations (atomic)
      // Key: Only ONE pre-flight check before batch, not per-item checks
      Batch batch = db.batch();

      for (PageModel model in list) {
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
                modelName: PageModel.modelName,
                modelId: model.id!,
                data: jsonEncode(modelJson),
              ),
            );
          }
        } else {
          // New item - use INSERT OR IGNORE for atomic conflict resolution
          // If two workers race here, one succeeds, the other is silently ignored
          batch.rawInsert(
            '''INSERT OR IGNORE INTO $tableName (${modelJson.keys.join(',')})
               VALUES (${List.filled(modelJson.length, '?').join(',')})''',
            modelJson.values.toList(),
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'created',
                modelName: PageModel.modelName,
                modelId: model.id!,
                data: jsonEncode(modelJson),
              ),
            );
          }
        }
      }

      // Commit batch atomically
      await batch.commit(noResult: true);

      // Track pending changes AFTER successful batch commit
      // This ensures we only track changes that actually succeeded
      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      prints('Error inserting bulk page item: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteBulk(
    List<PageModel> listCMM, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    List<String> idModels = listCMM.map((e) => e.id!).toList();

    if (idModels.isEmpty) {
      await LogUtils.error(
        'No cash management ids provided for bulk delete',
        null,
      );
      //notifyChanges();
      return false;
    }

    // If we need to insert to pending changes, we need to get the models first
    if (isInsertToPending) {
      for (PageModel model in listCMM) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: PageModel.modelName,
          modelId: model.id,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }
    }

    String whereIn = idModels.map((_) => '?').join(',');
    try {
      await db.delete(
        tableName,
        where: '$cId IN ($whereIn)',
        whereArgs: idModels,
      );

      // ✅ Delete from Hive
      await _hiveBox.deleteAll(idModels);

      await LogUtils.info('Successfully deleted cash management ids');
      //notifyChanges();
      return true;
    } catch (e) {
      await LogUtils.error('Error deleting cash management ids', e);
      //notifyChanges();
      return false;
    }
  }

  Future<List<PageModel>> getListCashManagementModel() async {
    // ✅ Try Hive first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => PageModel.fromJson(json),
    );

    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return PageModel.fromJson(maps[index]);
    });
  }

  @override
  Future<bool> replaceAllData(
    List<PageModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      // Step 1: Delete all existing data
      Database db = await _dbHelper.database;
      await db.delete(tableName);

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

  /// Delete all pages
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
      await LogUtils.error('Error deleting all page', e);
      return false;
    }
  }
}
