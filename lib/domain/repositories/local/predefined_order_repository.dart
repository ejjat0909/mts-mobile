import 'package:mts/data/models/predefined_order/predefined_order_model.dart';

abstract class LocalPredefinedOrderRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single predefined order record
  Future<int> insert(
    PredefinedOrderModel predefinedOrderModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing predefined order record
  Future<int> update(
    PredefinedOrderModel predefinedOrderModel, {
    required bool isInsertToPending,
  });

  /// Deletes a predefined order record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple predefined order records at once
  Future<bool> upsertBulk(
    List<PredefinedOrderModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple predefined order records at once
  Future<bool> deleteBulk(
    List<PredefinedOrderModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<PredefinedOrderModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all predefined order records
  Future<List<PredefinedOrderModel>> getListPredefinedOrder();

  /// Retrieves predefined orders by list of IDs
  Future<List<PredefinedOrderModel>> getPredefinedOrderByIds(
    List<String?> listId,
  );

  /// Retrieves a predefined order by ID
  Future<PredefinedOrderModel?> getPredefinedOrderById(String? idPredefined);

  /// Retrieves predefined orders where occupied is 0
  Future<List<PredefinedOrderModel>> getListPredefinedOrderWhereOccupied0();

  /// Retrieves predefined orders where occupied is 1
  Future<List<PredefinedOrderModel>> getListPredefinedOrderWhereOccupied1();

  /// Retrieves predefined orders by table IDs
  Future<List<PredefinedOrderModel>> getListPoByTableIds(List<String> tableIds);

  /// Retrieves custom predefined orders that have table
  Future<List<PredefinedOrderModel>> getCustomPoThatHaveTable();

  /// Retrieves predefined orders that have no table and are occupied
  Future<List<PredefinedOrderModel>>
  getPredefinedOrderThatHaveNoTableAndOccupied();

  /// Gets the latest column order
  Future<int> getLatestColumnOrder();

  // ==================== Status Operations ====================

  /// Marks a predefined order as occupied
  Future<bool> makeIsOccupied(String idModel);

  /// Marks a predefined order as unoccupied
  Future<bool> unOccupied(String idModel);

  /// Marks all non-custom predefined orders as unoccupied
  Future<bool> unOccupiedAllNotCustom();

  // ==================== Delete Operations ====================

  /// Deletes all predefined order records
  Future<bool> deleteAll();

  /// Deletes all custom predefined orders
  Future<bool> deleteAllCustomPO();

  /// Deletes records where ID is null
  Future<int> deleteWhereIdIsNull();

  /// Clears table reference by table ID
  Future<bool> clearTableReferenceByTableId(String targetTableId);
}
