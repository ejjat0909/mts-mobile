import 'package:mts/data/models/inventory_outlet/inventory_outlet_model.dart';

abstract class LocalInventoryOutletRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single inventory outlet record
  Future<int> insert(
    InventoryOutletModel inventoryOutletModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing inventory outlet record
  Future<int> update(
    InventoryOutletModel inventoryOutletModel, {
    required bool isInsertToPending,
  });

  /// Deletes an inventory outlet record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple inventory outlet records at once
  Future<bool> upsertBulk(
    List<InventoryOutletModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple inventory outlet records at once
  Future<bool> deleteBulk(
    List<InventoryOutletModel> listInventoryOutlet, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<InventoryOutletModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all inventory outlet records
  Future<List<InventoryOutletModel>> getListInventoryOutletModel();

  // ==================== Delete Operations ====================

  /// Deletes all inventory outlet records
  Future<bool> deleteAll();
}
