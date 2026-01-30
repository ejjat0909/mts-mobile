import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/data/repositories/local/local_tax_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/datasources/local/pivot_element.dart';
import 'package:mts/data/models/order_option_tax/order_option_tax_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/domain/repositories/local/order_option_tax_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/tax_repository.dart';
import 'package:sqflite/sqflite.dart';

/// ================================
/// Hive Box Provider
/// ================================
final orderOptionTaxBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(OrderOptionTaxModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final orderOptionTaxLocalRepoProvider = Provider<LocalOrderOptionTaxRepository>(
  (ref) {
    return LocalOrderOptionTaxRepositoryImpl(
      dbHelper: ref.read(databaseHelpersProvider),
      hiveBox: ref.read(orderOptionTaxBoxProvider),
      pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
      localTaxRepository: ref.read(taxLocalRepoProvider),
    );
  },
);

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalOrderOptionTaxRepository] that uses local database

class LocalOrderOptionTaxRepositoryImpl
    implements LocalOrderOptionTaxRepository {
  final IDatabaseHelpers _dbHelper;
  final Box<Map> _hiveBox;
  final LocalTaxRepository _localTaxRepository;
  final LocalPendingChangesRepository _pendingChangesRepository;

  /// Constructor
  LocalOrderOptionTaxRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required Box<Map> hiveBox,
    required LocalTaxRepository localTaxRepository,
    required LocalPendingChangesRepository pendingChangesRepository,
  }) : _dbHelper = dbHelper,
       _hiveBox = hiveBox,
       _localTaxRepository = localTaxRepository,
       _pendingChangesRepository = pendingChangesRepository;

  // Database table and column names
  static const String cOrderOptionId = 'order_option_id';
  static const String cTaxId = 'tax_id';
  static const String cCreatedAt = 'created_at';
  static const String cUpdatedAt = 'updated_at';
  static const String tableName = 'order_option_tax';

  static const String taxTableName = 'taxes';

  static Future<void> createTable(Database db) async {
    String rows = '''
      $cOrderOptionId TEXT NULL,
      $cTaxId TEXT NULL,
      $cCreatedAt TIMESTAMP DEFAULT NULL,
      $cUpdatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await db.delete(tableName);

      // Clear Hive
      await _hiveBox.clear();

      return true;
    } catch (e) {
      prints('Error deleting all item tax: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteBulk(
    List<OrderOptionTaxModel> listOrderOptionTax, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    try {
      for (OrderOptionTaxModel itm in listOrderOptionTax) {
        // Skip items with null IDs
        if (itm.orderOptionId == null || itm.taxId == null) {
          continue;
        }

        // If we need to insert to pending changes, get the model first
        if (isInsertToPending) {
          List<Map<String, dynamic>> results = await db.query(
            tableName,
            where: '$cOrderOptionId = ? AND $cTaxId = ?',
            whereArgs: [itm.orderOptionId, itm.taxId],
          );

          if (results.isNotEmpty) {
            final model = OrderOptionTaxModel.fromJson(results.first);

            // Insert to pending changes
            Map<String, String> pivotData = {
              cOrderOptionId: model.orderOptionId!,
              cTaxId: model.taxId!,
            };

            final pendingChange = PendingChangesModel(
              operation: 'deleted',
              modelName: OrderOptionTaxModel.modelName,
              modelId: jsonEncode(pivotData),
              data: jsonEncode(model.toJson()),
            );
            await _pendingChangesRepository.insert(pendingChange);
          }
        }

        // Delete the record using the batch operation
        batch.delete(
          tableName,
          where: '$cOrderOptionId = ? AND $cTaxId = ?',
          whereArgs: [itm.orderOptionId, itm.taxId],
        );
      }

      // Execute all delete operations in a single batch
      await batch.commit(noResult: true);

      // Delete from Hive using composite keys
      final compositeKeys =
          listOrderOptionTax
              .where((itm) => itm.orderOptionId != null && itm.taxId != null)
              .map((itm) => '${itm.orderOptionId}_${itm.taxId}')
              .toList();
      if (compositeKeys.isNotEmpty) {
        await _hiveBox.deleteAll(compositeKeys);
      }

      return true;
    } catch (e) {
      prints('Error deleting bulk item tax: $e');
      return false;
    }
  }

  @override
  Future<int> deletePivot(
    OrderOptionTaxModel orderOptionTaxModel, {
    required bool isInsertToPending,
  }) async {
    // Validate required fields
    if (orderOptionTaxModel.orderOptionId == null ||
        orderOptionTaxModel.taxId == null) {
      prints('Cannot delete item tax: itemId or taxId is null');
      return 0;
    }

    // Create pivot elements from the model
    PivotElement firstElement = PivotElement(
      columnName: cOrderOptionId,
      value: orderOptionTaxModel.orderOptionId!,
    );
    PivotElement secondElement = PivotElement(
      columnName: cTaxId,
      value: orderOptionTaxModel.taxId!,
    );

    // Get the model before deleting it
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$cOrderOptionId = ? AND $cTaxId = ?',
      whereArgs: [orderOptionTaxModel.orderOptionId, orderOptionTaxModel.taxId],
    );

    if (results.isNotEmpty) {
      final model = OrderOptionTaxModel.fromJson(results.first);

      // Delete the record
      int result = await _dbHelper.deletePivotDb(
        tableName,
        firstElement,
        secondElement,
      );

      // Delete from Hive using composite key
      if (result > 0) {
        final compositeKey = '${model.orderOptionId}_${model.taxId}';
        await _hiveBox.delete(compositeKey);
      }

      // Insert to pending changes if required
      if (isInsertToPending) {
        Map<String, String> pivotData = {
          cOrderOptionId: model.orderOptionId!,
          cTaxId: model.taxId!,
        };

        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: OrderOptionTaxModel.modelName,
          modelId: jsonEncode(pivotData),
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints(
        'No item tax record found with orderOptionId=${orderOptionTaxModel.orderOptionId} and taxId=${orderOptionTaxModel.taxId}',
      );
      return 0;
    }
  }

  @override
  Future<List<OrderOptionTaxModel>> getListOrderOptionTax() async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (index) {
      return OrderOptionTaxModel.fromJson(maps[index]);
    });
  }

  @override
  Future<int> delete(String id, {required bool isInsertToPending}) async {
    Database db = await _dbHelper.database;
    try {
      if (isInsertToPending) {
        List<Map<String, dynamic>> results = await db.query(
          tableName,
          where: '$cOrderOptionId = ? OR $cTaxId = ?',
          whereArgs: [id, id],
        );

        for (final result in results) {
          final model = OrderOptionTaxModel.fromJson(result);
          Map<String, String> pivotData = {
            cOrderOptionId: model.orderOptionId ?? '',
            cTaxId: model.taxId ?? '',
          };

          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: OrderOptionTaxModel.modelName,
            modelId: jsonEncode(pivotData),
            data: jsonEncode(model.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }

      int result = await db.delete(
        tableName,
        where: '$cOrderOptionId = ? OR $cTaxId = ?',
        whereArgs: [id, id],
      );

      // Delete from Hive - remove all affected composite keys
      if (result > 0) {
        final allKeys = _hiveBox.keys.cast<String>().toList();
        final keysToDelete = allKeys.where((key) => key.contains(id)).toList();
        if (keysToDelete.isNotEmpty) {
          await _hiveBox.deleteAll(keysToDelete);
        }
      }

      return result;
    } catch (e) {
      prints('Error deleting records with id $id: $e');
      return 0;
    }
  }

  @override
  Future<List<TaxModel>> getTaxModelsByOrderOptionId(
    String idOrderOption,
  ) async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cOrderOptionId = ?',
      whereArgs: [idOrderOption],
    );

    // Extract tax IDs from the result
    List<String> taxIds = maps.map((map) => map['tax_id'] as String).toList();

    return await _localTaxRepository.getTaxModelsByTaxIds(taxIds);
  }

  @override
  Future<bool> upsertBulk(
    List<OrderOptionTaxModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // Prepare pending changes to track after batch commit
      final List<PendingChangesModel> pendingChanges = [];
      final List<OrderOptionTaxModel> toInsert = [];
      final List<OrderOptionTaxModel> toUpdate = [];

      // Build a set of composite keys already seen in this batch
      final Set<String> seenKeys = {};

      for (OrderOptionTaxModel newModel in list) {
        if (newModel.orderOptionId == null || newModel.taxId == null) continue;

        final compositeKey = '${newModel.orderOptionId}_${newModel.taxId}';

        // Skip if already processed in this batch
        if (seenKeys.contains(compositeKey)) continue;
        seenKeys.add(compositeKey);

        // Query records that need updating (existing and older)
        final List<Map<String, dynamic>> recordsToUpdate = await db.query(
          tableName,
          where: '$cOrderOptionId = ? AND $cTaxId = ? AND $cUpdatedAt < ?',
          whereArgs: [
            newModel.orderOptionId,
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
            where: '$cOrderOptionId = ? AND $cTaxId = ?',
            whereArgs: [newModel.orderOptionId, newModel.taxId],
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
      for (OrderOptionTaxModel model in toInsert) {
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
              modelName: OrderOptionTaxModel.modelName,
              modelId: '${model.orderOptionId}_${model.taxId}',
              data: jsonEncode(modelJson),
            ),
          );
        }
      }

      // Batch update existing records
      for (OrderOptionTaxModel model in toUpdate) {
        model.updatedAt = DateTime.now();
        final modelJson = model.toJson();
        final keys = modelJson.keys.toList();
        final placeholders = keys.map((key) => '$key=?').join(',');

        batch.rawUpdate(
          '''UPDATE $tableName SET $placeholders 
             WHERE $cOrderOptionId = ? AND $cTaxId = ?''',
          [...modelJson.values, model.orderOptionId, model.taxId],
        );

        if (isInsertToPending) {
          pendingChanges.add(
            PendingChangesModel(
              operation: 'updated',
              modelName: OrderOptionTaxModel.modelName,
              modelId: '${model.orderOptionId}_${model.taxId}',
              data: jsonEncode(modelJson),
            ),
          );
        }
      }

      // Commit batch atomically
      await batch.commit(noResult: true);

      // Sync to Hive using composite keys
      final hiveDataMap = <dynamic, Map<dynamic, dynamic>>{};
      for (var model in [...toInsert, ...toUpdate]) {
        if (model.orderOptionId != null && model.taxId != null) {
          final compositeKey = '${model.orderOptionId}_${model.taxId}';
          hiveDataMap[compositeKey] = model.toJson();
        }
      }
      if (hiveDataMap.isNotEmpty) {
        await _hiveBox.putAll(hiveDataMap);
      }

      // Track pending changes AFTER successful batch commit
      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      prints('Error inserting bulk item tax: $e');
      return false;
    }
  }

  @override
  Future<int> upsert(
    OrderOptionTaxModel orderOptionTaxModel, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;

    // set updated at
    orderOptionTaxModel.updatedAt = DateTime.now();

    // Check if the record exists
    List<Map<String, dynamic>> existingRecords = await db.query(
      tableName,
      where: '$cOrderOptionId = ? AND $cTaxId = ?',
      whereArgs: [orderOptionTaxModel.orderOptionId, orderOptionTaxModel.taxId],
    );

    String operation;
    int result;

    if (existingRecords.isNotEmpty) {
      // If the record exists, update it
      operation = 'updated';
      PivotElement firstElement = PivotElement(
        columnName: cOrderOptionId,
        value: orderOptionTaxModel.orderOptionId!,
      );
      PivotElement secondElement = PivotElement(
        columnName: cTaxId,
        value: orderOptionTaxModel.taxId!,
      );

      result = await _dbHelper.updatePivotDb(
        tableName,
        firstElement,
        secondElement,
        orderOptionTaxModel.toJson(),
      );
    } else {
      // If the record doesn't exist, insert it
      operation = 'created';
      // Set the created timestamp for new records
      orderOptionTaxModel.createdAt = DateTime.now();
      result = await _dbHelper.insertDb(
        tableName,
        orderOptionTaxModel.toJson(),
      );
    }

    // Sync to Hive using composite key
    if (result > 0) {
      final compositeKey =
          '${orderOptionTaxModel.orderOptionId}_${orderOptionTaxModel.taxId}';
      await _hiveBox.put(compositeKey, orderOptionTaxModel.toJson());
    }

    // Insert to pending changes if required
    if (isInsertToPending) {
      Map<String, String> pivotData = {
        cOrderOptionId: orderOptionTaxModel.orderOptionId!,
        cTaxId: orderOptionTaxModel.taxId!,
      };

      final pendingChange = PendingChangesModel(
        operation: operation,
        modelName: OrderOptionTaxModel.modelName,
        modelId: jsonEncode(pivotData),
        data: jsonEncode(orderOptionTaxModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    return result;
  }

  @override
  Future<bool> replaceAllData(
    List<OrderOptionTaxModel> newData, {
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

  @override
  Future<int> deleteByColumnName(
    String columnName,
    dynamic value, {
    bool isInsertToPending = false,
  }) async {
    Database db = await _dbHelper.database;
    try {
      if (isInsertToPending) {
        List<Map<String, dynamic>> results = await db.query(
          tableName,
          where: '$columnName = ?',
          whereArgs: [value],
        );

        for (final result in results) {
          final model = OrderOptionTaxModel.fromJson(result);
          Map<String, String> pivotData = {
            cOrderOptionId: model.orderOptionId ?? '',
            cTaxId: model.taxId ?? '',
          };

          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: OrderOptionTaxModel.modelName,
            modelId: jsonEncode(pivotData),
            data: jsonEncode(model.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }

      int result = await db.delete(
        tableName,
        where: '$columnName = ?',
        whereArgs: [value],
      );

      // Delete from Hive - remove all affected composite keys
      if (result > 0) {
        final allKeys = _hiveBox.keys.cast<String>().toList();
        final keysToDelete =
            allKeys.where((key) => key.contains(value.toString())).toList();
        if (keysToDelete.isNotEmpty) {
          await _hiveBox.deleteAll(keysToDelete);
        }
      }

      return result;
    } catch (e) {
      prints('Error deleting records by column $columnName: $e');
      return 0;
    }
  }
}
