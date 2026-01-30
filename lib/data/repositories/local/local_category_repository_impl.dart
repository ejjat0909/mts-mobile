import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/category/category_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/category_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

final categoryBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(CategoryModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final categoryLocalRepoProvider = Provider<LocalCategoryRepository>((ref) {
  return LocalCategoryRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(categoryBoxProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalCategoryRepository] that uses local database
class LocalCategoryRepositoryImpl implements LocalCategoryRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String cId = 'id';
  static const String name = 'name';
  static const String color = 'color';
  static const String companyId = 'company_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String tableName = 'categories';

  /// Constructor
  LocalCategoryRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the category table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $name TEXT NULL,
      $color TEXT NULL,
      $companyId TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';

    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  @override
  Future<int> insert(
    CategoryModel model, {
    required bool isInsertToPending,
  }) async {
    model.id ??= IdUtils.generateUUID();
    model.createdAt = DateTime.now();
    model.updatedAt = DateTime.now();

    try {
      // Insert to SQLite
      int result = await _dbHelper.insertDb(tableName, model.toJson());

      // Insert to Hive
      await _hiveBox.put(model.id!, model.toJson());

      if (isInsertToPending) {
        await _insertPending(model, 'created');
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error inserting category', e);
      rethrow;
    }
  }

  Future<int> update(
    CategoryModel model, {
    required bool isInsertToPending,
  }) async {
    model.updatedAt = DateTime.now();

    try {
      // Update SQLite
      int result = await _dbHelper.updateDb(tableName, model.toJson());

      // Update Hive
      await _hiveBox.put(model.id!, model.toJson());

      if (isInsertToPending) {
        await _insertPending(model, 'updated');
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error updating category', e);
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
          fromJson: (json) => CategoryModel.fromJson(json),
        ) ??
        CategoryModel(id: id);

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
      await LogUtils.error('Error deleting category', e);
      rethrow;
    }
  }

  // ==================== Bulk Operations ====================

  @override
  Future<bool> upsertBulk(
    List<CategoryModel> list, {
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
              modelName: CategoryModel.modelName,
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
      await LogUtils.error('Error bulk inserting categories', e);
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<CategoryModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(tableName); // Delete all rows from SQLite
      await _hiveBox.clear();
      return await upsertBulk(newData, isInsertToPending: isInsertToPending);
    } catch (e) {
      await LogUtils.error('Error replacing all categories', e);
      return false;
    }
  }

  // ==================== Query Operations ====================

  Future<List<CategoryModel>> getListCategories() async {
    // Try Hive cache first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => CategoryModel.fromJson(json),
    );
    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final maps = await _dbHelper.readDb(tableName);
    return maps.map((json) => CategoryModel.fromJson(json)).toList();
  }

  /// Get single model by ID (Hive-first, fallback to SQLite)
  Future<CategoryModel?> getById(String id) async {
    // Try Hive cache first
    final hiveModel = HiveSyncHelper.getById(
      box: _hiveBox,
      id: id,
      fromJson: (json) => CategoryModel.fromJson(json),
    );
    if (hiveModel != null) {
      return hiveModel;
    }

    // Fallback to SQLite
    final map = await _dbHelper.readDbById(tableName, id);
    if (map != null) {
      return CategoryModel.fromJson(map);
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
      await LogUtils.error('Error deleting all categories', e);
      return false;
    }
  }

  // ==================== Helper Methods ====================

  Future<void> _insertPending(CategoryModel model, String operation) async {
    final pending = PendingChangesModel(
      operation: operation,
      modelName: CategoryModel.modelName,
      modelId: model.id!,
      data: jsonEncode(model.toJson()),
    );
    await _pendingChangesRepository.insert(pending);
  }

  List<CategoryModel> sortCategory(List<CategoryModel> categories) {
    categories.sort((a, b) => a.name!.compareTo(b.name!));

    return categories;
  }

  @override
  Future<List<CategoryModel>> getListCategoryModel() async {
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => CategoryModel.fromJson(json),
    );
    if (hiveList.isNotEmpty) {
      return sortCategory(hiveList);
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return CategoryModel.fromJson(maps[index]);
    });
  }

  // delete bulk
  @override
  Future<bool> deleteBulk(
    List<CategoryModel> listCM, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    try {
      for (CategoryModel cm in listCM) {
        if (cm.id == null) continue;

        batch.delete(tableName, where: '$cId = ?', whereArgs: [cm.id]);

        // Insert to pending changes if required
        if (isInsertToPending) {
          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: CategoryModel.modelName,
            modelId: cm.id,
            data: jsonEncode(cm.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }

      await batch.commit(noResult: true);

      // Delete from Hive
      for (CategoryModel cm in listCM) {
        if (cm.id != null) {
          await _hiveBox.delete(cm.id!);
        }
      }

      return true;
    } catch (e) {
      await LogUtils.error('Error deleting bulk category', e);
      return false;
    }
  }
}
