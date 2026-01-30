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
import 'package:mts/data/models/deleted_sale_item/deleted_sale_item_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/deleted_sale_item_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

final deletedSaleItemBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(DeletedSaleItemModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final deletedSaleItemLocalRepoProvider =
    Provider<LocalDeletedSaleItemRepository>((ref) {
      return LocalDeletedSaleItemRepositoryImpl(
        dbHelper: ref.read(databaseHelpersProvider),
        pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
        hiveBox: ref.read(deletedSaleItemBoxProvider),
      );
    });

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalDeletedSaleItemRepository] that uses local database
class LocalDeletedSaleItemRepositoryImpl
    implements LocalDeletedSaleItemRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String cId = 'id';
  static const String cStaffName = 'staff_name';
  static const String cOrderNumber = 'order_number';
  static const String cItemQuantity = 'item_quantity';
  static const String cItemPrice = 'item_price';
  static const String cItemTotalPrice = 'item_total_price';
  static const String cItemName = 'item_name';
  static const String cItemSku = 'item_sku';
  static const String cItemModifiers = 'item_modifiers';
  static const String cItemVariant = 'item_variant';
  static const String cPosDeviceName = 'pos_device_name';
  static const String cPosDeviceCode = 'pos_device_code';
  static const String cOutletName = 'outlet_name';
  static const String cOutletId = 'outlet_id';
  static const String cCompanyId = 'company_id';
  static const String cCreatedAt = 'created_at';
  static const String cUpdatedAt = 'updated_at';
  static const String tableName = 'deleted_sale_items';

  /// Constructor
  LocalDeletedSaleItemRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the deleted sale item table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $cStaffName TEXT NULL,
      $cOrderNumber TEXT NULL,
      $cItemQuantity TEXT NULL,
      $cItemPrice TEXT NULL,
      $cItemTotalPrice TEXT NULL,
      $cItemName TEXT NULL,
      $cItemSku TEXT NULL,
      $cItemModifiers TEXT NULL,
      $cItemVariant TEXT NULL,
      $cPosDeviceName TEXT NULL,
      $cPosDeviceCode TEXT NULL,
      $cOutletName TEXT NULL,
      $cOutletId TEXT NULL,
      $cCompanyId TEXT NULL,
      $cCreatedAt TIMESTAMP DEFAULT NULL,
      $cUpdatedAt TIMESTAMP DEFAULT NULL
    ''';

    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  @override
  Future<int> insert(
    DeletedSaleItemModel deletedSaleItemModel, {
    required bool isInsertToPending,
  }) async {
    deletedSaleItemModel.id ??= IdUtils.generateUUID();
    deletedSaleItemModel.createdAt = DateTime.now();
    deletedSaleItemModel.updatedAt = DateTime.now();

    try {
      // Insert to SQLite
      int result = await _dbHelper.insertDb(
        tableName,
        deletedSaleItemModel.toJson(),
      );

      // Insert to Hive
      await _hiveBox.put(
        deletedSaleItemModel.id!,
        deletedSaleItemModel.toJson(),
      );

      if (isInsertToPending) {
        await _insertPending(deletedSaleItemModel, 'created');
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error inserting deleted sale item', e);
      rethrow;
    }
  }

  @override
  Future<int> update(
    DeletedSaleItemModel deletedSaleItemModel, {
    required bool isInsertToPending,
  }) async {
    deletedSaleItemModel.updatedAt = DateTime.now();

    try {
      // Update SQLite
      int result = await _dbHelper.updateDb(
        tableName,
        deletedSaleItemModel.toJson(),
      );

      // Update Hive
      await _hiveBox.put(
        deletedSaleItemModel.id!,
        deletedSaleItemModel.toJson(),
      );

      if (isInsertToPending) {
        await _insertPending(deletedSaleItemModel, 'updated');
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error updating deleted sale item', e);
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
          fromJson: (json) => DeletedSaleItemModel.fromJson(json),
        ) ??
        DeletedSaleItemModel(id: id);

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
      await LogUtils.error('Error deleting deleted sale item', e);
      rethrow;
    }
  }

  // ==================== Bulk Operations ====================

  @override
  Future<bool> upsertBulk(
    List<DeletedSaleItemModel> listDeletedSaleItem, {
    required bool isInsertToPending,
  }) async {
    try {
      Database db = await _dbHelper.database;
      final batch = db.batch();
      final List<PendingChangesModel> pendingList = [];

      for (var model in listDeletedSaleItem) {
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
              modelName: DeletedSaleItemModel.modelName,
              modelId: model.id!,
              data: jsonEncode(model.toJson()),
            ),
          );
        }
      }

      await batch.commit(noResult: true);

      // Bulk insert to Hive
      final dataMap = <dynamic, Map<dynamic, dynamic>>{};
      for (var model in listDeletedSaleItem) {
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
      await LogUtils.error('Error bulk inserting deleted sale items', e);
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<DeletedSaleItemModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(tableName); // Delete all rows from SQLite
      await _hiveBox.clear(); // Clear Hive
      return await upsertBulk(newData, isInsertToPending: isInsertToPending);
    } catch (e) {
      await LogUtils.error('Error replacing all deleted sale items', e);
      return false;
    }
  }

  // ==================== Query Operations ====================

  Future<List<DeletedSaleItemModel>> getListDeletedSaleItems() async {
    // Try Hive cache first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => DeletedSaleItemModel.fromJson(json),
    );
    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final maps = await _dbHelper.readDb(tableName);
    return maps.map((json) => DeletedSaleItemModel.fromJson(json)).toList();
  }

  /// Get single model by ID (Hive-first, fallback to SQLite)
  Future<DeletedSaleItemModel?> getById(String id) async {
    // Try Hive cache first
    final hiveModel = HiveSyncHelper.getById(
      box: _hiveBox,
      id: id,
      fromJson: (json) => DeletedSaleItemModel.fromJson(json),
    );
    if (hiveModel != null) {
      return hiveModel;
    }

    // Fallback to SQLite
    final map = await _dbHelper.readDbById(tableName, id);
    if (map != null) {
      return DeletedSaleItemModel.fromJson(map);
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
      await LogUtils.error('Error deleting all deleted sale items', e);
      return false;
    }
  }

  // ==================== Helper Methods ====================

  Future<void> _insertPending(
    DeletedSaleItemModel model,
    String operation,
  ) async {
    final pending = PendingChangesModel(
      operation: operation,
      modelName: DeletedSaleItemModel.modelName,
      modelId: model.id!,
      data: jsonEncode(model.toJson()),
    );
    await _pendingChangesRepository.insert(pending);
  }

  @override
  Future<bool> deleteBulk(
    List<DeletedSaleItemModel> listDeletedSaleItem, {
    required bool isInsertToPending,
  }) async {
    try {
      for (var city in listDeletedSaleItem) {
        if (city.id != null) {
          await delete(
            city.id.toString(),
            isInsertToPending: isInsertToPending,
          );
        }
      }
      return true;
    } catch (e) {
      await LogUtils.error('Error deleting bulk cities', e);
      return false;
    }
  }

  @override
  Future<List<DeletedSaleItemModel>> getListDeletedSaleItemModel() async {
    // ✅ Try Hive first
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => DeletedSaleItemModel.fromJson(json),
    );

    if (hiveList.isNotEmpty) {
      return hiveList;
    }

    // Fallback to SQLite
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return DeletedSaleItemModel.fromJson(maps[index]);
    });
  }
}
