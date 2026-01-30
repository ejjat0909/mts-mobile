import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/discount/discount_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/repositories/local/local_discount_item_repository_impl.dart';
import 'package:mts/domain/repositories/local/discount_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

final discountBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(DiscountModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final discountLocalRepoProvider = Provider<LocalDiscountRepository>((ref) {
  return LocalDiscountRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(discountBoxProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalDiscountRepository] that uses local database
class LocalDiscountRepositoryImpl implements LocalDiscountRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String cId = 'id';
  static const String name = 'name';
  static const String type = 'type';
  static const String value = 'value';
  static const String option = 'option';
  static const String validFrom = 'valid_from';
  static const String validTo = 'valid_to';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String tableName = 'discounts';

  // Discount item table constants
  static const String discountItemTableName = 'discount_item';
  static const String discountId = 'discount_id';
  static const String itemId = 'item_id';

  /// Constructor
  LocalDiscountRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the discount table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $name TEXT NULL,
      $type INTEGER NULL,
      $value FLOAT NULL,
      $option INTEGER NULL,
      $validFrom TIMESTAMP NULL,
      $validTo TIMESTAMP NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';

    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  @override
  Future<int> insert(
    DiscountModel discountModel, {
    required bool isInsertToPending,
  }) async {
    discountModel.id ??= IdUtils.generateUUID();
    discountModel.createdAt = DateTime.now();
    discountModel.updatedAt = DateTime.now();

    try {
      // Insert to SQLite
      int result = await _dbHelper.insertDb(tableName, discountModel.toJson());

      // Insert to Hive
      await _hiveBox.put(discountModel.id!, discountModel.toJson());

      if (isInsertToPending) {
        await _insertPending(discountModel, 'created');
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error inserting discount', e);
      rethrow;
    }
  }

  @override
  Future<int> update(
    DiscountModel discountModel, {
    required bool isInsertToPending,
  }) async {
    discountModel.updatedAt = DateTime.now();

    try {
      // Update SQLite
      int result = await _dbHelper.updateDb(tableName, discountModel.toJson());

      // Update Hive
      await _hiveBox.put(discountModel.id!, discountModel.toJson());

      if (isInsertToPending) {
        await _insertPending(discountModel, 'updated');
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error updating discount', e);
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
          fromJson: (json) => DiscountModel.fromJson(json),
        ) ??
        DiscountModel(id: id);

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
      await LogUtils.error('Error deleting discount', e);
      rethrow;
    }
  }

  // ==================== Bulk Operations ====================

  @override
  Future<bool> upsertBulk(
    List<DiscountModel> listDiscount, {
    required bool isInsertToPending,
  }) async {
    try {
      Database db = await _dbHelper.database;
      final batch = db.batch();
      final List<PendingChangesModel> pendingList = [];

      for (var model in listDiscount) {
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
              modelName: DiscountModel.modelName,
              modelId: model.id!,
              data: jsonEncode(model.toJson()),
            ),
          );
        }
      }

      await batch.commit(noResult: true);

      // Bulk insert to Hive
      final dataMap = <dynamic, Map<dynamic, dynamic>>{};
      for (var model in listDiscount) {
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
      await LogUtils.error('Error bulk inserting discounts', e);
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<DiscountModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(tableName); // Delete all rows from SQLite
      await _hiveBox.clear(); // Clear Hive
      return await upsertBulk(newData, isInsertToPending: isInsertToPending);
    } catch (e) {
      await LogUtils.error('Error replacing all discounts', e);
      return false;
    }
  }

  // ==================== Query Operations ====================

  Future<List<DiscountModel>> getListDiscounts() async {
    // Try Hive cache first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => DiscountModel.fromJson(json),
    );
    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final maps = await _dbHelper.readDb(tableName);
    return maps.map((json) => DiscountModel.fromJson(json)).toList();
  }

  /// Get single model by ID (Hive-first, fallback to SQLite)
  Future<DiscountModel?> getById(String id) async {
    // Try Hive cache first
    final hiveModel = HiveSyncHelper.getById(
      box: _hiveBox,
      id: id,
      fromJson: (json) => DiscountModel.fromJson(json),
    );
    if (hiveModel != null) {
      return hiveModel;
    }

    // Fallback to SQLite
    final map = await _dbHelper.readDbById(tableName, id);
    if (map != null) {
      return DiscountModel.fromJson(map);
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
      await LogUtils.error('Error deleting all discounts', e);
      return false;
    }
  }

  // ==================== Helper Methods ====================

  Future<void> _insertPending(DiscountModel model, String operation) async {
    final pending = PendingChangesModel(
      operation: operation,
      modelName: DiscountModel.modelName,
      modelId: model.id!,
      data: jsonEncode(model.toJson()),
    );
    await _pendingChangesRepository.insert(pending);
  }

  List<DiscountModel> sortDiscount(List<DiscountModel> discounts) {
    discounts.sort((a, b) => a.name!.compareTo(b.name!));

    return discounts;
  }

  @override
  Future<List<DiscountModel>> getListDiscountModel() async {
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => DiscountModel.fromJson(json),
    );
    if (hiveList.isNotEmpty) {
      return sortDiscount(hiveList);
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return DiscountModel.fromJson(maps[index]);
    });
  }

  // delete bulk
  @override
  Future<bool> deleteBulk(
    List<DiscountModel> listDiscount, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    try {
      for (DiscountModel cm in listDiscount) {
        if (cm.id == null) continue;

        batch.delete(tableName, where: '$cId = ?', whereArgs: [cm.id]);

        // Insert to pending changes if required
        if (isInsertToPending) {
          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: DiscountModel.modelName,
            modelId: cm.id,
            data: jsonEncode(cm.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }

      await batch.commit(noResult: true);

      // Delete from Hive
      for (DiscountModel cm in listDiscount) {
        if (cm.id != null) {
          await _hiveBox.delete(cm.id!);
        }
      }

      return true;
    } catch (e) {
      await LogUtils.error('Error deleting bulk discount', e);
      return false;
    }
  }

  /// Get discount models by item ID
  @override
  Future<List<DiscountModel>> getDiscountModelByItemId(String itemId) async {
    try {
      Database db = await _dbHelper.database;

      // Get current date and time
      DateTime now = DateTime.now();

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT d.* FROM $discountItemTableName di
        INNER JOIN $tableName d ON di.$discountId = d.$cId
        WHERE di.$LocalDiscountItemRepositoryImpl.itemId = ?
        AND (d.$validFrom IS NULL OR d.$validFrom <= ?)
        AND (d.$validTo IS NULL OR d.$validTo >= ?)
        ''',
        [itemId, now.toIso8601String(), now.toIso8601String()],
      );

      return maps.map((map) => DiscountModel.fromJson(map)).toList();
    } catch (e) {
      await LogUtils.error('Error getting discount models by item ID', e);
      return [];
    }
  }

  /// Get discount models by list of discount IDs
  @override
  Future<List<DiscountModel>> getDiscountModelsByDiscountIds(
    List<String> discountIds,
  ) async {
    if (discountIds.isEmpty) return [];

    try {
      // Try to get from Hive first
      final List<DiscountModel> hiveModels = [];
      final List<String> missingIds = [];

      for (String id in discountIds) {
        final hiveModel = HiveSyncHelper.getById(
          box: _hiveBox,
          id: id,
          fromJson: (json) => DiscountModel.fromJson(json),
        );
        if (hiveModel != null) {
          hiveModels.add(hiveModel);
        } else {
          missingIds.add(id);
        }
      }

      // If all found in Hive, return them
      if (missingIds.isEmpty) {
        return hiveModels;
      }

      // Fallback to SQLite for missing IDs
      Database db = await _dbHelper.database;
      final placeholders = List.filled(missingIds.length, '?').join(',');
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: '$cId IN ($placeholders)',
        whereArgs: missingIds,
      );

      final sqliteModels =
          maps.map((map) => DiscountModel.fromJson(map)).toList();

      // Combine results
      return [...hiveModels, ...sqliteModels];
    } catch (e) {
      await LogUtils.error('Error getting discount models by IDs', e);
      return [];
    }
  }
}
