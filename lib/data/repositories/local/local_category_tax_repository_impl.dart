import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/datasources/local/pivot_element.dart';
import 'package:mts/data/models/category_tax/category_tax_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/data/repositories/local/local_tax_repository_impl.dart';
import 'package:mts/domain/repositories/local/category_tax_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/tax_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mts/core/services/hive_sync_helper.dart';

final categoryTaxBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(CategoryTaxModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final categoryTaxLocalRepoProvider = Provider<LocalCategoryTaxRepository>((
  ref,
) {
  return LocalCategoryTaxRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(categoryTaxBoxProvider),
    taxLocalRepository: ref.read(taxLocalRepoProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalCategoryTaxRepository] that uses local database
class LocalCategoryTaxRepositoryImpl implements LocalCategoryTaxRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final LocalTaxRepository _taxLocalRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String categoryId = 'category_id';
  static const String taxId = 'tax_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String tableName = 'category_tax';

  // Tax table constants
  static const String taxTableName = 'taxes';

  /// Constructor
  LocalCategoryTaxRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
    required LocalTaxRepository taxLocalRepository,
  }) : _dbHelper = dbHelper,
       _taxLocalRepository = taxLocalRepository,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the category tax table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $categoryId TEXT NULL,
      $taxId TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  @override
  Future<int> upsert(
    CategoryTaxModel categoryTaxModel, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;

    // Set the updated timestamp
    categoryTaxModel.updatedAt = DateTime.now();

    try {
      // Check if the record exists
      List<Map<String, dynamic>> existingRecords = await db.query(
        tableName,
        where: '$categoryId = ? AND $taxId = ?',
        whereArgs: [categoryTaxModel.categoryId, categoryTaxModel.taxId],
      );

      String operation;
      int result;

      if (existingRecords.isNotEmpty) {
        // If the record exists, update it
        operation = 'updated';
        PivotElement firstElement = PivotElement(
          columnName: categoryId,
          value: categoryTaxModel.categoryId!,
        );
        PivotElement secondElement = PivotElement(
          columnName: taxId,
          value: categoryTaxModel.taxId!,
        );

        result = await _dbHelper.updatePivotDb(
          tableName,
          firstElement,
          secondElement,
          categoryTaxModel.toJson(),
        );
      } else {
        // If the record doesn't exist, insert it
        operation = 'created';
        // Set the created timestamp for new records
        categoryTaxModel.createdAt = DateTime.now();
        result = await _dbHelper.insertDb(tableName, categoryTaxModel.toJson());
      }

      // Upsert to Hive using composite key
      final compositeKey =
          '${categoryTaxModel.categoryId}_${categoryTaxModel.taxId}';
      await _hiveBox.put(compositeKey, categoryTaxModel.toJson());

      // Insert to pending changes if required
      if (isInsertToPending) {
        Map<String, String> pivotData = {
          categoryId: categoryTaxModel.categoryId!,
          taxId: categoryTaxModel.taxId!,
        };

        final pendingChange = PendingChangesModel(
          operation: operation,
          modelName: CategoryTaxModel.modelName,
          modelId: jsonEncode(pivotData),
          data: jsonEncode(categoryTaxModel.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error upserting category discount', e);
      rethrow;
    }
  }

  @override
  Future<bool> upsertBulk(
    List<CategoryTaxModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // Prepare pending changes to track after batch commit
      final List<PendingChangesModel> pendingChanges = [];
      final List<CategoryTaxModel> toInsert = [];
      final List<CategoryTaxModel> toUpdate = [];

      // Build a set of composite keys already seen in this batch
      final Set<String> seenKeys = {};

      for (CategoryTaxModel newModel in list) {
        if (newModel.categoryId == null || newModel.taxId == null) {
          continue;
        }

        final compositeKey = '${newModel.categoryId}_${newModel.taxId}';

        // Skip if already processed in this batch
        if (seenKeys.contains(compositeKey)) continue;
        seenKeys.add(compositeKey);

        // Query records that need updating (existing and older)
        final List<Map<String, dynamic>> recordsToUpdate = await db.query(
          tableName,
          where: '$categoryId = ? AND $taxId = ? AND $updatedAt < ?',
          whereArgs: [
            newModel.categoryId,
            newModel.taxId,
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
            where: '$categoryId = ? AND $taxId = ?',
            whereArgs: [newModel.categoryId, newModel.taxId],
          );

          if (existingRecords.isEmpty) {
            // Record doesn't exist, add to insert list
            toInsert.add(newModel);
          }
        }
      }

      // Use a single batch for all operations (atomic)
      Batch batch = db.batch();

      // Batch insert new records
      for (CategoryTaxModel model in toInsert) {
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
              modelName: CategoryTaxModel.modelName,
              modelId: '${model.categoryId}_${model.taxId}',
              data: jsonEncode(modelJson),
            ),
          );
        }
      }

      // Batch update existing records
      for (CategoryTaxModel model in toUpdate) {
        model.updatedAt = DateTime.now();
        final modelJson = model.toJson();
        final keys = modelJson.keys.toList();
        final placeholders = keys.map((key) => '$key=?').join(',');

        batch.rawUpdate(
          '''UPDATE $tableName SET $placeholders 
             WHERE $categoryId = ? AND $taxId = ?''',
          [...modelJson.values, model.categoryId, model.taxId],
        );

        if (isInsertToPending) {
          pendingChanges.add(
            PendingChangesModel(
              operation: 'updated',
              modelName: CategoryTaxModel.modelName,
              modelId: '${model.categoryId}_${model.taxId}',
              data: jsonEncode(modelJson),
            ),
          );
        }
      }

      // Commit batch atomically
      await batch.commit(noResult: true);

      // Bulk insert to Hive
      final dataMap = <dynamic, Map<dynamic, dynamic>>{};
      for (var model in [...toInsert, ...toUpdate]) {
        if (model.categoryId != null && model.taxId != null) {
          final compositeKey = '${model.categoryId}_${model.taxId}';
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
      prints('Error inserting bulk category discount: $e');
      return false;
    }
  }

  // delete pivot
  // usage:
  // CategoryTaxModel categoryDiscount = CategoryTaxModel(categoryId: '1', taxId: '2');
  // int result = await deletePivot(categoryDiscount, true);
  @override
  Future<int> deletePivot(
    CategoryTaxModel categoryTaxModel, {
    required bool isInsertToPending,
  }) async {
    // Validate required fields
    if (categoryTaxModel.categoryId == null || categoryTaxModel.taxId == null) {
      prints('Cannot delete category discount: categoryId or taxId is null');
      return 0;
    }

    // Create pivot elements from the model
    PivotElement firstElement = PivotElement(
      columnName: categoryId,
      value: categoryTaxModel.categoryId!,
    );
    PivotElement secondElement = PivotElement(
      columnName: taxId,
      value: categoryTaxModel.taxId!,
    );

    // Get the model before deleting it
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$categoryId = ? AND $taxId = ?',
      whereArgs: [categoryTaxModel.categoryId, categoryTaxModel.taxId],
    );

    if (results.isNotEmpty) {
      final model = CategoryTaxModel.fromJson(results.first);

      // Delete the record
      int result = await _dbHelper.deletePivotDb(
        tableName,
        firstElement,
        secondElement,
      );

      // Delete from Hive
      final compositeKey = '${model.categoryId}_${model.taxId}';
      await _hiveBox.delete(compositeKey);

      // Insert to pending changes if required
      if (isInsertToPending) {
        Map<String, String> pivotData = {
          categoryId: model.categoryId!,
          taxId: model.taxId!,
        };

        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: CategoryTaxModel.modelName,
          modelId: jsonEncode(pivotData),
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints(
        'No category discount record found with categoryId=${categoryTaxModel.categoryId} and taxId=${categoryTaxModel.taxId}',
      );
      return 0;
    }
  }

  // delete bulk pivot
  @override
  Future<bool> deleteBulk(
    List<CategoryTaxModel> listCategoryDiscount, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    try {
      for (CategoryTaxModel cd in listCategoryDiscount) {
        // Skip items with null IDs
        if (cd.categoryId == null || cd.taxId == null) {
          continue;
        }

        // If we need to insert to pending changes, get the model first
        if (isInsertToPending) {
          List<Map<String, dynamic>> results = await db.query(
            tableName,
            where: '$categoryId = ? AND $taxId = ?',
            whereArgs: [cd.categoryId, cd.taxId],
          );

          if (results.isNotEmpty) {
            final model = CategoryTaxModel.fromJson(results.first);

            // Insert to pending changes
            Map<String, String> pivotData = {
              categoryId: model.categoryId!,
              taxId: model.taxId!,
            };

            final pendingChange = PendingChangesModel(
              operation: 'deleted',
              modelName: CategoryTaxModel.modelName,
              modelId: jsonEncode(pivotData),
              data: jsonEncode(model.toJson()),
            );
            await _pendingChangesRepository.insert(pendingChange);
          }
        }

        // Delete the record using the batch operation
        batch.delete(
          tableName,
          where: '$categoryId = ? AND $taxId = ?',
          whereArgs: [cd.categoryId, cd.taxId],
        );
      }

      // Execute all delete operations in a single batch
      await batch.commit(noResult: true);

      // Delete from Hive
      for (CategoryTaxModel cd in listCategoryDiscount) {
        if (cd.categoryId != null && cd.taxId != null) {
          final compositeKey = '${cd.categoryId}_${cd.taxId}';
          await _hiveBox.delete(compositeKey);
        }
      }

      return true;
    } catch (e) {
      prints('Error deleting bulk category discount: $e');
      return false;
    }
  }

  // delete all
  @override
  Future<bool> deleteAll() async {
    try {
      Database db = await _dbHelper.database;
      await db.delete(tableName);

      // Clear Hive
      await _hiveBox.clear();

      return true;
    } catch (e) {
      await LogUtils.error('Error deleting all category discount', e);
      return false;
    }
  }

  Future<List<CategoryTaxModel>> getListCategoryDiscount() async {
    // Try Hive cache first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => CategoryTaxModel.fromJson(json),
    );
    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return CategoryTaxModel.fromJson(maps[index]);
    });
  }

  @override
  Future<bool> replaceAllData(
    List<CategoryTaxModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      // Step 1: Delete all existing data from SQLite
      Database db = await _dbHelper.database;
      await db.delete(tableName);

      // Step 2: Clear Hive
      await _hiveBox.clear();

      // Step 3: Insert new data using existing insertBulk method
      if (newData.isNotEmpty) {
        bool insertResult = await upsertBulk(
          newData,
          isInsertToPending: isInsertToPending,
        );
        if (!insertResult) {
          await LogUtils.error(
            'Failed to insert bulk data in $tableName',
            null,
          );
          return false;
        }
      }

      return true;
    } catch (e) {
      await LogUtils.error('Error replacing all data in $tableName', e);
      return false;
    }
  }

  // ==================== Other Operations ====================

  @override
  Future<int> deleteByColumnName(
    String columnName,
    dynamic value, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      List<Map<String, dynamic>> results = await db.query(
        tableName,
        where: '$columnName = ?',
        whereArgs: [value],
      );

      int result = await db.delete(
        tableName,
        where: '$columnName = ?',
        whereArgs: [value],
      );

      // Delete from Hive and optionally track pending changes
      for (var record in results) {
        final model = CategoryTaxModel.fromJson(record);

        // Delete from Hive
        if (model.categoryId != null && model.taxId != null) {
          final compositeKey = '${model.categoryId}_${model.taxId}';
          await _hiveBox.delete(compositeKey);
        }

        // Track pending changes if required
        if (isInsertToPending) {
          Map<String, String> pivotData = {
            categoryId: model.categoryId ?? '',
            taxId: model.taxId ?? '',
          };

          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: CategoryTaxModel.modelName,
            modelId: jsonEncode(pivotData),
            data: jsonEncode(model.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }

      return result;
    } catch (e) {
      await LogUtils.error(
        'Error deleting category discount by column name',
        e,
      );
      return 0;
    }
  }

  // getListCategoryTax
  @override
  Future<List<CategoryTaxModel>> getListCategoryTax() async {
    // Try Hive cache first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => CategoryTaxModel.fromJson(json),
    );
    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return CategoryTaxModel.fromJson(maps[index]);
    });
  }

  Future<List<TaxModel>> getTaxModelsByCategoryId(String idCategory) async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$categoryId = ?',
      whereArgs: [idCategory],
    );

    // Extract tax IDs from the result
    List<String> taxIds = maps.map((map) => map['tax_id'] as String).toList();

    return await _taxLocalRepository.getTaxModelsByTaxIds(taxIds);
  }
}
