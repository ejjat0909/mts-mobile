import 'package:mts/data/models/inventory/inventory_model.dart';

abstract class LocalInventoryRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single inventory record
  Future<int> insert(
    InventoryModel inventoryModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing inventory record
  Future<int> update(
    InventoryModel inventoryModel, {
    required bool isInsertToPending,
  });

  /// Deletes an inventory record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple inventory records at once
  Future<bool> upsertBulk(
    List<InventoryModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple inventory records at once
  Future<bool> deleteBulk(
    List<InventoryModel> listInventory, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<InventoryModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all inventory records
  Future<List<InventoryModel>> getListInventoryModel();

  /// Retrieves inventory models by list of inventory IDs
  Future<List<InventoryModel>> getListInventoryModelByInvIds(
    List<String?> invIds,
  );

  /// Retrieves an inventory by ID
  Future<InventoryModel?> getInventoryModelById(String inventoryId);

  // ==================== Delete Operations ====================

  /// Deletes all inventory records
  Future<bool> deleteAll();
}
