import 'package:mts/data/models/inventory_transaction/inventory_transaction_model.dart';

abstract class LocalInventoryTransactionRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single inventory transaction record
  Future<int> insert(
    InventoryTransactionModel inventoryTransactionModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing inventory transaction record
  Future<int> update(
    InventoryTransactionModel inventoryTransactionModel, {
    required bool isInsertToPending,
  });

  /// Deletes an inventory transaction record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple inventory transaction records at once
  Future<bool> upsertBulk(
    List<InventoryTransactionModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple inventory transaction records at once
  Future<bool> deleteBulk(
    List<InventoryTransactionModel> listInventoryTransaction, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<InventoryTransactionModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all inventory transaction records
  Future<List<InventoryTransactionModel>> getListInventoryTransactionModel();

  /// Retrieves an inventory transaction by ID
  Future<InventoryTransactionModel?> getInventoryTransactionModelById(
    String inventoryTransactionId,
  );

  // ==================== Delete Operations ====================

  /// Deletes all inventory transaction records
  Future<bool> deleteAll();
}
