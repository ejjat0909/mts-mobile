import 'package:mts/data/models/sale/sale_model.dart';

abstract class LocalSaleRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single sale record
  Future<int> insert(SaleModel sale, {required bool isInsertToPending});

  /// Updates an existing sale record
  Future<String> update(SaleModel sale, {required bool isInsertToPending});

  /// Deletes a sale record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple sale records at once
  Future<bool> upsertBulk(
    List<SaleModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple sale records at once
  Future<bool> deleteBulk(
    List<SaleModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<SaleModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all sale records
  Future<List<SaleModel>> getListSaleModel();

  /// Retrieves sales based on staff ID and charged at
  Future<List<SaleModel>> getListSalesBasedOnStaffIdAndChargedAt();

  /// Retrieves sales where staff ID is null
  Future<List<SaleModel>> getListSalesWhereStaffIdNull();

  /// Retrieves saved orders by predefined order IDs
  Future<List<SaleModel>> getSavedOrdersByPredefinedOrderIds(
    List<String> predefinedOrderIds,
  );

  /// Retrieves a sale by sale ID
  Future<SaleModel?> getSaleModelBySaleId(String saleId);

  /// Retrieves a sale by predefined order ID
  Future<SaleModel?> getSaleModelByPredefinedOrderId(String? predefinedOrderId);

  /// Gets the latest running number
  Future<int> getLatestRunningNumber();

  // ==================== Update Operations ====================

  /// Updates charged at for a sale
  Future<int> updateChargedAt(String saleId);

  /// Uncharges a sale
  Future<bool> unChargeSale(SaleModel saleModel);

  /// Clears table reference by table ID
  Future<bool> clearTableReferenceByTableId(String targetTableId);

  // ==================== Delete Operations ====================

  /// Deletes all sale records
  Future<bool> deleteAll();

  /// Deletes sales where staff ID is null
  Future<int> deleteSaleWhereStaffIdNull();
}
