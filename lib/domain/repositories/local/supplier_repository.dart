import 'package:mts/data/models/supplier/supplier_model.dart';

abstract class LocalSupplierRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single supplier record
  Future<int> insert(
    SupplierModel supplierModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing supplier record
  Future<int> update(
    SupplierModel supplierModel, {
    required bool isInsertToPending,
  });

  /// Deletes a supplier record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple supplier records at once
  Future<bool> upsertBulk(
    List<SupplierModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple supplier records at once
  Future<bool> deleteBulk(
    List<SupplierModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<SupplierModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all supplier records
  Future<List<SupplierModel>> getListSupplierModel();

  /// Retrieves a supplier by ID
  Future<SupplierModel?> getSupplierModelById(String supplierId);

  // ==================== Delete Operations ====================

  /// Deletes all supplier records
  Future<bool> deleteAll();
}
