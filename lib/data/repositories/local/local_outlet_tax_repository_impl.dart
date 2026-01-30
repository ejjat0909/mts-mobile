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
import 'package:mts/data/models/outlet_tax/outlet_tax_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/domain/repositories/local/outlet_tax_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/tax_repository.dart';
import 'package:sqflite/sqflite.dart';

/// ================================
/// Provider for Hive Box
/// ================================
final outletTaxBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(OutletTaxModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final outletTaxLocalRepoProvider = Provider<LocalOutletTaxRepository>((ref) {
  return LocalOutletTaxRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    hiveBox: ref.read(outletTaxBoxProvider),
    localTaxRepository: ref.read(taxLocalRepoProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalOutletTaxRepository] that uses local database
class LocalOutletTaxRepositoryImpl implements LocalOutletTaxRepository {
  final IDatabaseHelpers _dbHelper;
  final Box<Map> _hiveBox;
  final LocalTaxRepository _localTaxRepository;
  final LocalPendingChangesRepository _pendingChangesRepository;

  /// Database table and column names
  static const String outletId = 'outlet_id';
  static const String taxId = 'tax_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String tableName = 'outlet_tax';

  // Tax table constants
  static const String taxTableName = 'taxes';

  /// Constructor
  LocalOutletTaxRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required Box<Map> hiveBox,
    required LocalTaxRepository localTaxRepository,
    required LocalPendingChangesRepository pendingChangesRepository,
  }) : _dbHelper = dbHelper,
       _hiveBox = hiveBox,
       _localTaxRepository = localTaxRepository,
       _pendingChangesRepository = pendingChangesRepository;

  /// Create the outlet tax table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $outletId TEXT NULL,
      $taxId TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert or update an outlet tax
  /// If the outlet tax exists (based on outletId and taxId), it will be updated
  /// If the outlet tax doesn't exist, it will be inserted
  @override
  Future<int> upsert(
    OutletTaxModel outletTaxModel, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;

    // Set the updated timestamp
    outletTaxModel.updatedAt = DateTime.now();

    // Check if the record exists
    List<Map<String, dynamic>> existingRecords = await db.query(
      tableName,
      where: '$outletId = ? AND $taxId = ?',
      whereArgs: [outletTaxModel.outletId, outletTaxModel.taxId],
    );

    String operation;
    int result;

    if (existingRecords.isNotEmpty) {
      // If the record exists, update it
      operation = 'updated';
      PivotElement firstElement = PivotElement(
        columnName: outletId,
        value: outletTaxModel.outletId!,
      );
      PivotElement secondElement = PivotElement(
        columnName: taxId,
        value: outletTaxModel.taxId!,
      );

      result = await _dbHelper.updatePivotDb(
        tableName,
        firstElement,
        secondElement,
        outletTaxModel.toJson(),
      );
    } else {
      // If the record doesn't exist, insert it
      operation = 'created';
      // Set the created timestamp for new records
      outletTaxModel.createdAt = DateTime.now();
      result = await _dbHelper.insertDb(tableName, outletTaxModel.toJson());
    }

    // Insert to pending changes if required
    if (isInsertToPending) {
      Map<String, String> pivotData = {
        outletId: outletTaxModel.outletId!,
        taxId: outletTaxModel.taxId!,
      };

      final pendingChange = PendingChangesModel(
        operation: operation,
        modelName: OutletTaxModel.modelName,
        modelId: jsonEncode(pivotData),
        data: jsonEncode(outletTaxModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    // Sync to Hive cache with composite key
    if (result > 0) {
      final compositeKey = '${outletTaxModel.outletId}_${outletTaxModel.taxId}';
      await _hiveBox.put(compositeKey, outletTaxModel.toJson());
    }

    return result;
  }

  // delete pivot
  // usage:
  // OutletTaxModel outletTax = OutletTaxModel(outletId: '1', taxId: '2');
  // int result = await deletePivot(outletTax, true);
  @override
  Future<int> deletePivot(
    OutletTaxModel outletTaxModel, {
    required bool isInsertToPending,
  }) async {
    // Validate required fields
    if (outletTaxModel.outletId == null || outletTaxModel.taxId == null) {
      prints('Cannot delete outlet tax: outletId or taxId is null');
      return 0;
    }

    // Create pivot elements from the model
    PivotElement firstElement = PivotElement(
      columnName: outletId,
      value: outletTaxModel.outletId!,
    );
    PivotElement secondElement = PivotElement(
      columnName: taxId,
      value: outletTaxModel.taxId!,
    );

    // Get the model before deleting it
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$outletId = ? AND $taxId = ?',
      whereArgs: [outletTaxModel.outletId, outletTaxModel.taxId],
    );

    if (results.isNotEmpty) {
      final model = OutletTaxModel.fromJson(results.first);

      // Delete the record
      int result = await _dbHelper.deletePivotDb(
        tableName,
        firstElement,
        secondElement,
      );

      // Delete from Hive cache with composite key
      if (result > 0) {
        final compositeKey = '${model.outletId}_${model.taxId}';
        await _hiveBox.delete(compositeKey);
      }

      // Insert to pending changes if required
      if (isInsertToPending) {
        Map<String, String> pivotData = {
          outletId: model.outletId!,
          taxId: model.taxId!,
        };

        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: OutletTaxModel.modelName,
          modelId: jsonEncode(pivotData),
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints(
        'No outlet tax record found with outletId=${outletTaxModel.outletId} and taxId=${outletTaxModel.taxId}',
      );
      return 0;
    }
  }

  // delete bulk pivot
  @override
  Future<bool> deleteBulk(
    List<OutletTaxModel> listOutletTax, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    try {
      for (OutletTaxModel otm in listOutletTax) {
        // Skip items with null IDs
        if (otm.outletId == null || otm.taxId == null) {
          continue;
        }

        // If we need to insert to pending changes, get the model first
        if (isInsertToPending) {
          List<Map<String, dynamic>> results = await db.query(
            tableName,
            where: '$outletId = ? AND $taxId = ?',
            whereArgs: [otm.outletId, otm.taxId],
          );

          if (results.isNotEmpty) {
            final model = OutletTaxModel.fromJson(results.first);

            // Insert to pending changes
            Map<String, String> pivotData = {
              outletId: model.outletId!,
              taxId: model.taxId!,
            };

            final pendingChange = PendingChangesModel(
              operation: 'deleted',
              modelName: OutletTaxModel.modelName,
              modelId: jsonEncode(pivotData),
              data: jsonEncode(model.toJson()),
            );
            await _pendingChangesRepository.insert(pendingChange);
          }
        }

        // Delete the record using the batch operation
        batch.delete(
          tableName,
          where: '$outletId = ? AND $taxId = ?',
          whereArgs: [otm.outletId, otm.taxId],
        );
      }

      // Execute all delete operations in a single batch
      await batch.commit(noResult: true);

      // Delete from Hive cache with composite keys
      final compositeKeysToDelete =
          listOutletTax
              .where((m) => m.outletId != null && m.taxId != null)
              .map((m) => '${m.outletId}_${m.taxId}')
              .toList();
      if (compositeKeysToDelete.isNotEmpty) {
        await _hiveBox.deleteAll(compositeKeysToDelete);
      }

      return true;
    } catch (e) {
      prints('Error deleting bulk outlet tax: $e');
      return false;
    }
  }

  // delete all
  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await db.delete(tableName);
      await _hiveBox.clear();
      return true;
    } catch (e) {
      prints('Error deleting all outlet tax: $e');
      return false;
    }
  }

  // getListOutletTax
  @override
  Future<List<OutletTaxModel>> getListOutletTax() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return OutletTaxModel.fromJson(maps[index]);
    });
  }

  @override
  Future<List<OutletTaxModel>> getListOutletTaxModel() => getListOutletTax();

  @override
  Future<List<TaxModel>> getTaxModelsByOutletId(String idOutlet) async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$outletId = ?',
      whereArgs: [idOutlet],
    );

    // Extract tax IDs from the result
    List<String> taxIds = maps.map((map) => map['tax_id'] as String).toList();

    return await _localTaxRepository.getTaxModelsByTaxIds(taxIds);
  }

  @override
  Future<bool> upsertBulk(
    List<OutletTaxModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // First, collect all composite keys that need to be processed
      final compositeKeys = <String>{};
      final modelMap = <String, OutletTaxModel>{};

      for (final model in list) {
        if (model.outletId == null || model.taxId == null) continue;
        final key = "${model.outletId}_${model.taxId}";
        compositeKeys.add(key);
        modelMap[key] = model;
      }

      if (compositeKeys.isEmpty) return true;

      // Single pre-flight query: get all existing combinations
      final existingKeys = <String>{};
      if (compositeKeys.isNotEmpty) {
        final subQueries = compositeKeys
            .map((_) => "($outletId = ? AND $taxId = ?)")
            .join(" OR ");
        final whereArgs = <dynamic>[];
        for (final key in compositeKeys) {
          final parts = key.split('_');
          whereArgs.addAll([parts[0], parts[1]]);
        }

        final existingRecords = await db.rawQuery(
          "SELECT $outletId, $taxId FROM $tableName WHERE $subQueries",
          whereArgs,
        );
        for (final record in existingRecords) {
          existingKeys.add("${record[outletId]}_${record[taxId]}");
        }
      }

      // Prepare pending changes to track after batch commit
      final pendingChanges = <PendingChangesModel>[];

      // Use a single batch for all operations (atomic)
      final batch = db.batch();

      for (final key in compositeKeys) {
        final model = modelMap[key]!;
        final isExisting = existingKeys.contains(key);

        if (isExisting) {
          // Only update if new item is newer than existing one
          batch.update(
            tableName,
            model.toJson(),
            where:
                '$outletId = ? AND $taxId = ? AND ($updatedAt IS NULL OR $updatedAt <= ?)',
            whereArgs: [
              model.outletId,
              model.taxId,
              DateTimeUtils.getDateTimeFormat(model.updatedAt),
            ],
          );

          if (isInsertToPending) {
            final pivotData = {outletId: model.outletId!, taxId: model.taxId!};
            pendingChanges.add(
              PendingChangesModel(
                operation: 'updated',
                modelName: OutletTaxModel.modelName,
                modelId: jsonEncode(pivotData),
                data: jsonEncode(model.toJson()),
              ),
            );
          }
        } else {
          // New item - use INSERT OR IGNORE for atomic conflict resolution
          model.createdAt ??= DateTime.now();
          model.updatedAt ??= DateTime.now();

          batch.rawInsert(
            '''INSERT OR IGNORE INTO $tableName (${model.toJson().keys.join(',')})
               VALUES (${List.filled(model.toJson().length, '?').join(',')})''',
            model.toJson().values.toList(),
          );

          if (isInsertToPending) {
            final pivotData = {outletId: model.outletId!, taxId: model.taxId!};
            pendingChanges.add(
              PendingChangesModel(
                operation: 'created',
                modelName: OutletTaxModel.modelName,
                modelId: jsonEncode(pivotData),
                data: jsonEncode(model.toJson()),
              ),
            );
          }
        }
      }

      // Commit batch atomically
      await batch.commit(noResult: true);

      // Sync to Hive cache with composite keys
      final hiveDataMap = <dynamic, Map<dynamic, dynamic>>{};
      for (final key in compositeKeys) {
        final model = modelMap[key]!;
        hiveDataMap[key] = model.toJson();
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
      prints('Error inserting bulk outlet tax: $e');
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<OutletTaxModel> newData, {
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
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;

    if (isInsertToPending) {
      List<Map<String, dynamic>> results = await db.query(
        tableName,
        where: '$columnName = ?',
        whereArgs: [value],
      );

      for (Map<String, dynamic> record in results) {
        final model = OutletTaxModel.fromJson(record);

        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: OutletTaxModel.modelName,
          modelId: jsonEncode({outletId: model.outletId, taxId: model.taxId}),
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }
    }

    int result = await _dbHelper.deleteDbWithConditions(tableName, {
      columnName: value,
    });

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
  }
}
