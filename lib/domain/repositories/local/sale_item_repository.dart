import 'package:mts/data/models/sale_item/sale_item_model.dart';

abstract class LocalSaleItemRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single sale item record
  Future<int> insert(SaleItemModel saleItem, {required bool isInsertToPending});

  /// Updates an existing sale item record
  Future<int> update(SaleItemModel saleItem, {required bool isInsertToPending});

  /// Deletes a sale item record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple sale item records at once

  Future<bool> upsertBulk(
    List<SaleItemModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple sale item records at once
  Future<bool> deleteBulk(
    List<SaleItemModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<SaleItemModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all sale item records
  Future<List<SaleItemModel>> getListSaleItem();

  /// Retrieves sale items by sale ID with optional filters
  Future<List<SaleItemModel>> getListSaleItemByOneSaleId(
    String idSale,
    bool? isVoided,
    bool? isPrintedKitchen,
    List<String> categoryIds,
  );

  /// Retrieves sale items by list of sale IDs
  Future<List<SaleItemModel>> getListSaleItemBySaleIds(List<String> saleIds);

  /// Retrieves sale items by sale IDs where is voided is true
  Future<List<SaleItemModel>> getListSaleItemBySaleIdWhereIsVoidedTrue(
    List<String> saleIds,
  );

  /// Retrieves sale items based on sale ID
  Future<List<SaleItemModel>> getListSaleItemBasedOnSaleId(String saleId);

  /// Retrieves sale items by predefined order ID
  Future<List<SaleItemModel>> getListSaleItemByPredefinedOrderId(
    String predefinedOrderId,
    bool? isVoided,
    bool? isPrintedKitchen,
    List<String> categoryIds,
  );

  /// Retrieves sale items by predefined order ID filtered with category
  Future<List<SaleItemModel>>
  getListSaleItemByPredefinedOrderIdFilterWithCategory(
    String predefinedOrderId,
    bool isVoided,
    List<String> categoryIds,
  );

  /// Retrieves a sale item by ID
  Future<SaleItemModel> getSaleItemById(String id);

  // ==================== Delete Operations ====================

  /// Deletes all sale item records
  Future<bool> deleteAll();

  /// Deletes sale items by sale ID
  Future<bool> deleteSaleItemWhereSaleId(String saleId);

  /// Deletes sale items where staff ID is null
  Future<int> deleteSaleItemWhereStaffIdNull();
}
