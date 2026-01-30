import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';

abstract class LocalSaleModifierRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single sale modifier record
  Future<int> insert(
    SaleModifierModel saleModifier, {
    required bool isInsertToPending,
  });

  /// Updates an existing sale modifier record
  Future<int> update(
    SaleModifierModel saleModifier, {
    required bool isInsertToPending,
  });

  /// Deletes a sale modifier record by ID
  Future<bool> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple sale modifier records at once
  Future<bool> upsertBulk(
    List<SaleModifierModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple sale modifier records at once
  Future<bool> deleteBulk(
    List<SaleModifierModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<SaleModifierModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all sale modifier records
  Future<List<SaleModifierModel>> getListSaleModifierModel();

  /// Retrieves sale modifiers by item ID and timestamp
  Future<List<SaleModifierModel>> getListSaleModifiersByItemIdAndTimestamp(
    String saleItemId,
    DateTime updatedAt,
  );

  /// Retrieves sale modifier IDs by sale item ID
  Future<List<String>> getListSaleModifierIds(String saleItemId);

  /// Retrieves sale modifier models by sale ID
  Future<List<SaleModifierModel>> getListSaleModifierModelBySaleId(
    String saleId,
  );

  /// Retrieves sale modifiers by predefined order ID
  Future<List<SaleModifierModel>> getListSaleModifiersByPredefinedOrderId(
    String predefinedOrderId,
    List<String> categoryIds,
  );

  /// Retrieves sale modifiers by predefined order ID filtered with category
  Future<List<SaleModifierModel>>
  getListSaleModifiersByPredefinedOrderIdFilterWithCategory(
    String predefinedOrderId,
    List<String> categoryIds, {
    required String? saleItemId,
  });

  // ==================== Delete Operations ====================

  /// Deletes all sale modifier records
  Future<bool> deleteAll();

  /// Soft deletes sale modifiers by predefined order ID
  Future<bool> softDeleteSaleModifiersByPredefinedOrderId(
    String predefinedOrderId,
  );

  /// Deletes sale modifiers by predefined order ID
  Future<bool> deleteSaleModifiersByPredefinedOrderId(String predefinedOrderId);
}
