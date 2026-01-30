import 'package:mts/data/models/deleted_sale_item/deleted_sale_item_model.dart';

abstract class LocalDeletedSaleItemRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single deleted sale item record
  Future<int> insert(
    DeletedSaleItemModel deletedSaleItemModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing deleted sale item record
  Future<int> update(
    DeletedSaleItemModel deletedSaleItemModel, {
    required bool isInsertToPending,
  });

  /// Deletes a deleted sale item record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple deleted sale item records at once
  Future<bool> upsertBulk(
    List<DeletedSaleItemModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple deleted sale item records at once
  Future<bool> deleteBulk(
    List<DeletedSaleItemModel> listDeletedSaleItem, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<DeletedSaleItemModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all deleted sale item records
  Future<List<DeletedSaleItemModel>> getListDeletedSaleItemModel();

  // ==================== Delete Operations ====================

  /// Deletes all deleted sale item records
  Future<bool> deleteAll();
}
