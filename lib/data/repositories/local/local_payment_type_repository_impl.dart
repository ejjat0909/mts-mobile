import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/domain/repositories/local/payment_type_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

final paymentTypeBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(PaymentTypeModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final paymentTypeLocalRepoProvider = Provider<LocalPaymentTypeRepository>((
  ref,
) {
  return LocalPaymentTypeRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(paymentTypeBoxProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalPaymentTypeRepository] that uses local database
class LocalPaymentTypeRepositoryImpl implements LocalPaymentTypeRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String cId = 'id';
  static const String name = 'name';
  static const String paymentTypeCategory = 'payment_type_category';
  static const String paymentTypeCategoryId = 'payment_type_category_id';
  static const String autoRounding = 'auto_rounding';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String tableName = 'payment_types';

  /// Constructor
  LocalPaymentTypeRepositoryImpl({
    required Box<Map> hiveBox,
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
  }) : _dbHelper = dbHelper,
       _hiveBox = hiveBox,
       _pendingChangesRepository = pendingChangesRepository;

  /// Create the payment type table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $name TEXT NULL,
      $paymentTypeCategory TEXT NULL,
      $paymentTypeCategoryId TEXT NULL,
      $autoRounding INTEGER DEFAULT 0,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  Future<void> _insertPending(PaymentTypeModel model, String operation) async {
    final pending = PendingChangesModel(
      operation: operation,
      modelName: PaymentTypeModel.modelName,
      modelId: model.id!,
      data: jsonEncode(model.toJson()),
    );
    await _pendingChangesRepository.insert(pending);
  }

  @override
  Future<int> insert(
    PaymentTypeModel model, {
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
      await LogUtils.error('Error inserting payment type', e);
      rethrow;
    }
  }

  @override
  Future<int> update(
    PaymentTypeModel model, {
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
      await LogUtils.error('Error updating payment type', e);
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
          fromJson: (json) => PaymentTypeModel.fromJson(json),
        ) ??
        PaymentTypeModel(id: id);

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
      await LogUtils.error('Error deleting payment type', e);
      rethrow;
    }
  }

  @override
  Future<bool> deleteBulk(
    List<PaymentTypeModel> listCMM, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    List<String> idModels = listCMM.map((e) => e.id!).toList();

    if (idModels.isEmpty) {
      await LogUtils.error(
        'No payment type ids provided for bulk delete',
        null,
      );
      //notifyChanges();
      return false;
    }

    // If we need to insert to pending changes, we need to get the models first
    if (isInsertToPending) {
      for (PaymentTypeModel model in listCMM) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: PaymentTypeModel.modelName,
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

      await LogUtils.info('Successfully deleted payment type ids');
      //notifyChanges();
      return true;
    } catch (e) {
      await LogUtils.error('Error deleting payment type ids', e);
      //notifyChanges();
      return false;
    }
  }

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
      await LogUtils.error('Error deleting all cash managements', e);
      return false;
    }
  }

  List<PaymentTypeModel> sortPayment(List<PaymentTypeModel> list) {
    // Sort the list to put 'cash' (single word only) items first
    list.sort((a, b) {
      bool aIsCashSingleWord = _isCashSingleWord(a.name);
      bool bIsCashSingleWord = _isCashSingleWord(b.name);

      if (aIsCashSingleWord && !bIsCashSingleWord) {
        return -1; // a comes before b
      } else if (!aIsCashSingleWord && bIsCashSingleWord) {
        return 1; // b comes before a
      } else {
        return 0; // maintain original order for items in the same category
      }
    });

    return list;
  }

  @override
  Future<List<PaymentTypeModel>> getListPaymentType() async {
    final list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => PaymentTypeModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return sortPayment(list);
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    List<PaymentTypeModel> paymentTypes = List.generate(maps.length, (index) {
      return PaymentTypeModel.fromJson(maps[index]);
    });

    return sortPayment(paymentTypes);
  }

  bool _isCashSingleWord(String? name) {
    if (name == null || name.trim().isEmpty) {
      return false;
    }

    String trimmedName = name.trim().toLowerCase();
    // Check if it contains 'cash' and has no spaces (single word)
    return trimmedName.contains('cash') && !trimmedName.contains(' ');
  }

  // insert bulk
  @override
  Future<bool> upsertBulk(
    List<PaymentTypeModel> list, {
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

      for (PaymentTypeModel model in list) {
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
                modelName: PaymentTypeModel.modelName,
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
                modelName: PaymentTypeModel.modelName,
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
      prints('Error inserting bulk payment type: $e');
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<PaymentTypeModel> newData, {
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

  @override
  Future<List<PaymentTypeModel>> getPaymentModelByPaymentId(
    List<String> paymentIds,
  ) async {
    final list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => PaymentTypeModel.fromJson(json),
    );

    if (list.isNotEmpty) {
      return list.where((element) => paymentIds.contains(element.id)).toList();
    }

    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$cId IN (${paymentIds.map((id) => '?').join(',')})',
      whereArgs: paymentIds,
    );

    List<PaymentTypeModel> paymentModel =
        results.map((row) => PaymentTypeModel.fromJson(row)).toList();
    return sortPayment(paymentModel);
  }
}
