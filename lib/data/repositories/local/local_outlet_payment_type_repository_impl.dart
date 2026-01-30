import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/data/repositories/local/local_payment_type_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/datasources/local/pivot_element.dart';
import 'package:mts/data/models/outlet_payment_type/outlet_payment_type_model.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/outlet_payment_type_repository.dart';
import 'package:mts/domain/repositories/local/payment_type_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

/// ================================
/// Hive Box Provider
/// ================================
final outletPaymentTypeBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(OutletPaymentTypeModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final outletPaymentTypeLocalRepoProvider =
    Provider<LocalOutletPaymentTypeRepository>((ref) {
      return LocalOutletPaymentTypeRepositoryImpl(
        dbHelper: ref.read(databaseHelpersProvider),
        hiveBox: ref.read(outletPaymentTypeBoxProvider),
        pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
        localPaymentTypeRepository: ref.read(paymentTypeLocalRepoProvider),
      );
    });

/// ================================
/// Local Repository Implementation
/// ================================
class LocalOutletPaymentTypeRepositoryImpl
    implements LocalOutletPaymentTypeRepository {
  final IDatabaseHelpers _dbHelper;
  final Box<Map> _hiveBox;
  final LocalPaymentTypeRepository _localPaymentTypeRepository;
  final LocalPendingChangesRepository _pendingChangesRepository;

  LocalOutletPaymentTypeRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required Box<Map> hiveBox,
    required LocalPaymentTypeRepository localPaymentTypeRepository,
    required LocalPendingChangesRepository pendingChangesRepository,
  }) : _dbHelper = dbHelper,
       _hiveBox = hiveBox,
       _localPaymentTypeRepository = localPaymentTypeRepository,
       _pendingChangesRepository = pendingChangesRepository;

  static const String outletId = 'outlet_id';
  static const String paymentTypeId = 'payment_type_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String tableName = 'outlet_payment_type';

  static Future<void> createTable(Database db) async {
    String rows = '''
        $outletId TEXT NULL,
        $paymentTypeId TEXT NULL,
        $createdAt TIMESTAMP DEFAULT NULL,
        $updatedAt TIMESTAMP DEFAULT NULL
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
      prints('Error deleting all outlet tax: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteBulk(
    List<OutletPaymentTypeModel> listOutletPaymentType, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    try {
      for (OutletPaymentTypeModel opt in listOutletPaymentType) {
        if (opt.outletId == null || opt.paymentTypeId == null) {
          continue;
        }

        if (isInsertToPending) {
          List<Map<String, dynamic>> results = await db.query(
            tableName,
            where: '$outletId = ? AND $paymentTypeId = ?',
            whereArgs: [opt.outletId, opt.paymentTypeId],
          );

          if (results.isNotEmpty) {
            final model = OutletPaymentTypeModel.fromJson(results.first);

            // Insert to pending changes
            Map<String, String> pivotData = {
              outletId: model.outletId!,
              paymentTypeId: model.paymentTypeId!,
            };
            final pendingChange = PendingChangesModel(
              operation: 'deleted',
              modelName: OutletPaymentTypeModel.modelName,
              modelId: jsonEncode(pivotData),
              data: jsonEncode(model.toJson()),
            );
            await _pendingChangesRepository.insert(pendingChange);
          }
        }

        batch.delete(
          tableName,
          where: '$outletId = ? AND $paymentTypeId = ?',
          whereArgs: [opt.outletId!, opt.paymentTypeId!],
        );
      }
      await batch.commit(noResult: true);

      // Delete from Hive using composite keys
      final compositeKeys =
          listOutletPaymentType
              .where((opt) => opt.outletId != null && opt.paymentTypeId != null)
              .map((opt) => '${opt.outletId}_${opt.paymentTypeId}')
              .toList();
      if (compositeKeys.isNotEmpty) {
        await _hiveBox.deleteAll(compositeKeys);
      }

      return true;
    } catch (e) {
      prints('Error deleting bulk outlet payment type: $e');
      return false;
    }
  }

  @override
  Future<int> deletePivot(
    OutletPaymentTypeModel outletPaymentTypeModel, {
    required bool isInsertToPending,
  }) async {
    if (outletPaymentTypeModel.outletId == null ||
        outletPaymentTypeModel.paymentTypeId == null) {
      return 0;
    }

    PivotElement firstElement = PivotElement(
      columnName: outletId,
      value: outletPaymentTypeModel.outletId!,
    );
    PivotElement secondElement = PivotElement(
      columnName: paymentTypeId,
      value: outletPaymentTypeModel.paymentTypeId!,
    );

    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where:
          '$outletId = ? AND $paymentTypeId = ?', // Use the correct column names here
      whereArgs: [
        outletPaymentTypeModel.outletId!,
        outletPaymentTypeModel.paymentTypeId!,
      ],
    );

    if (results.isNotEmpty) {
      final model = OutletPaymentTypeModel.fromJson(results.first);

      int result = await _dbHelper.deletePivotDb(
        tableName,
        firstElement,
        secondElement,
      );

      // Delete from Hive using composite key
      if (result > 0) {
        final compositeKey = '${model.outletId}_${model.paymentTypeId}';
        await _hiveBox.delete(compositeKey);
      }

      if (isInsertToPending) {
        // Insert to pending changes
        Map<String, String> pivotData = {
          outletId: model.outletId!,
          paymentTypeId: model.paymentTypeId!,
        };
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: OutletPaymentTypeModel.modelName,
          modelId: jsonEncode(pivotData),
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      return 0;
    }
  }

  @override
  Future<List<OutletPaymentTypeModel>> getListOutletPaymentType() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return OutletPaymentTypeModel.fromJson(maps[index]);
    });
  }

  @override
  Future<List<OutletPaymentTypeModel>> getListOutletPaymentTypeModel() =>
      getListOutletPaymentType();

  @override
  Future<List<PaymentTypeModel>> getPaymentTypeModelsByOutletId(
    String idOutlet,
  ) async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$outletId = ?',
      whereArgs: [idOutlet],
    );

    List<String> paymentTypeIds =
        maps.map((map) => map[paymentTypeId] as String).toList();

    return await _localPaymentTypeRepository.getPaymentModelByPaymentId(
      paymentTypeIds,
    );
  }

  @override
  Future<bool> upsertBulk(
    List<OutletPaymentTypeModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      final List<PendingChangesModel> pendingChanges = [];
      final List<OutletPaymentTypeModel> toInsert = [];
      final List<OutletPaymentTypeModel> toUpdate = [];

      final Set<String> seenKeys = {};

      for (OutletPaymentTypeModel newModel in list) {
        if (newModel.outletId == null || newModel.paymentTypeId == null) {
          continue;
        }

        final compositeKey = '${newModel.outletId}_${newModel.paymentTypeId}';

        if (seenKeys.contains(compositeKey)) {
          continue;
        }
        seenKeys.add(compositeKey);

        final List<Map<String, dynamic>> recordsToUpdate = await db.query(
          tableName,
          where: '$outletId = ? AND $paymentTypeId = ? AND $updatedAt < ?',
          whereArgs: [
            newModel.outletId,
            newModel.paymentTypeId,
            DateTimeUtils.getDateTimeFormat(newModel.updatedAt),
          ],
        );

        if (recordsToUpdate.isNotEmpty) {
          toUpdate.add(newModel);
        } else {
          final List<Map<String, dynamic>> existingRecords = await db.query(
            tableName,
            where: '$outletId = ? AND $paymentTypeId = ?',
            whereArgs: [newModel.outletId, newModel.paymentTypeId],
          );

          if (existingRecords.isEmpty) {
            toInsert.add(newModel);
          }
        }
      }

      Batch batch = db.batch();

      for (OutletPaymentTypeModel model in toInsert) {
        final modelJson = model.toJson();
        batch.rawInsert(
          '''INSERT INTO $tableName (${modelJson.keys.join(',')})
             VALUES (${List.filled(modelJson.length, '?').join(',')})''',
          modelJson.values.toList(),
        );

        if (isInsertToPending) {
          final compositeKey = '${model.outletId}_${model.paymentTypeId}';
          pendingChanges.add(
            PendingChangesModel(
              operation: 'created',
              modelName: OutletPaymentTypeModel.modelName,
              modelId: compositeKey,
              data: jsonEncode(modelJson),
            ),
          );
        }
      }

      for (OutletPaymentTypeModel model in toUpdate) {
        model.updatedAt = DateTime.now();
        final modelJson = model.toJson();
        final keys = modelJson.keys.toList();
        final placeholders = keys.map((key) => '$key=?').join(',');

        batch.rawUpdate(
          '''UPDATE $tableName SET $placeholders 
             WHERE $outletId = ? AND $paymentTypeId = ?''',
          [...modelJson.values, model.outletId, model.paymentTypeId],
        );

        if (isInsertToPending) {
          final compositeKey = '${model.outletId}_${model.paymentTypeId}';
          pendingChanges.add(
            PendingChangesModel(
              operation: 'updated',
              modelName: OutletPaymentTypeModel.modelName,
              modelId: compositeKey,
              data: jsonEncode(modelJson),
            ),
          );
        }
      }

      await batch.commit(noResult: true);

      // Sync to Hive using composite keys
      final hiveDataMap = <dynamic, Map<dynamic, dynamic>>{};
      for (var model in [...toInsert, ...toUpdate]) {
        if (model.outletId != null && model.paymentTypeId != null) {
          final compositeKey = '${model.outletId}_${model.paymentTypeId}';
          hiveDataMap[compositeKey] = model.toJson();
        }
      }
      if (hiveDataMap.isNotEmpty) {
        await _hiveBox.putAll(hiveDataMap);
      }

      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      prints('Error inserting bulk outlet payment type: $e');
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<OutletPaymentTypeModel> newData, {
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
  Future<int> upsert(
    OutletPaymentTypeModel outletPaymentTypeModel, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;

    // Set the updated timestamp
    outletPaymentTypeModel.updatedAt = DateTime.now();

    // Check if the record exists
    List<Map<String, dynamic>> existingRecords = await db.query(
      tableName,
      where: '$outletId = ? AND $paymentTypeId = ?',
      whereArgs: [
        outletPaymentTypeModel.outletId,
        outletPaymentTypeModel.paymentTypeId,
      ],
    );

    String operation;
    int result;

    if (existingRecords.isNotEmpty) {
      // If the record exists, update it
      operation = 'updated';
      PivotElement firstElement = PivotElement(
        columnName: outletId,
        value: outletPaymentTypeModel.outletId!,
      );
      PivotElement secondElement = PivotElement(
        columnName: paymentTypeId,
        value: outletPaymentTypeModel.paymentTypeId!,
      );

      result = await _dbHelper.updatePivotDb(
        tableName,
        firstElement,
        secondElement,
        outletPaymentTypeModel.toJson(),
      );
    } else {
      // If the record doesn't exist, insert it
      operation = 'created';
      // Set the created timestamp for new records
      outletPaymentTypeModel.createdAt = DateTime.now();
      result = await _dbHelper.insertDb(
        tableName,
        outletPaymentTypeModel.toJson(),
      );
    }

    // Sync to Hive using composite key
    if (result > 0) {
      final compositeKey =
          '${outletPaymentTypeModel.outletId}_${outletPaymentTypeModel.paymentTypeId}';
      await _hiveBox.put(compositeKey, outletPaymentTypeModel.toJson());
    }

    // Insert to pending changes if required
    if (isInsertToPending) {
      Map<String, String> pivotData = {
        outletId: outletPaymentTypeModel.outletId!,
        paymentTypeId: outletPaymentTypeModel.paymentTypeId!,
      };

      final pendingChange = PendingChangesModel(
        operation: operation,
        modelName: OutletPaymentTypeModel.modelName,
        modelId: jsonEncode(pivotData),
        data: jsonEncode(outletPaymentTypeModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    return result;
  }

  /// Upsert bulk items with timestamp validation into Hive cache
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
        final model = OutletPaymentTypeModel.fromJson(record);

        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: OutletPaymentTypeModel.modelName,
          modelId: jsonEncode({
            outletId: model.outletId,
            paymentTypeId: model.paymentTypeId,
          }),
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
