import 'package:mts/data/models/discount_sale_item/discount_sale_item_model.dart';

abstract class LocalDiscountSaleItemRepository {
  // ==================== CRUD Operations ====================

  /// Inserts or updates a discount sale item record
  Future<int> upsert(
    DiscountSaleItemModel discountSaleItemModel, {
    required bool isInsertToPending,
  });

  /// Deletes a discount sale item pivot
  Future<int> deletePivot(
    DiscountSaleItemModel discountSaleItemModel, {
    required bool isInsertToPending,
  });

  // ==================== Bulk Operations ====================

  /// Inserts multiple discount sale item records at once
  Future<bool> upsertBulk(
    List<DiscountSaleItemModel> list, {
    required bool isInsertToPending,
  });

  // ==================== Query Operations ====================

  /// Retrieves all discount sale item records
  Future<List<DiscountSaleItemModel>> getListDiscountSaleItem();
}
