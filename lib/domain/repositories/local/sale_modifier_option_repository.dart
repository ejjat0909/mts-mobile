import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';

abstract class LocalSaleModifierOptionRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single sale modifier option record
  Future<int> insert(
    SaleModifierOptionModel saleModifierOption, {
    required bool isInsertToPending,
  });

  /// Updates an existing sale modifier option record
  Future<int> update(
    SaleModifierOptionModel saleModifierOption, {
    required bool isInsertToPending,
  });

  /// Deletes a sale modifier option record by ID
  Future<bool> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple sale modifier option records at once
  Future<bool> upsertBulk(
    List<SaleModifierOptionModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple sale modifier option records at once
  Future<bool> deleteBulk(
    List<SaleModifierOptionModel> saleModifierOptions, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<SaleModifierOptionModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all sale modifier option records
  Future<List<SaleModifierOptionModel>> getListSaleModifierOption();

  /// Retrieves sale modifier options by list of sale modifier IDs
  Future<List<SaleModifierOptionModel>>
  getListSaleModifierOptionsBySaleModifierIds(List<String> saleModifierIds);

  /// Retrieves sale modifier options by predefined order ID
  Future<List<SaleModifierOptionModel>>
  getListSaleModifierOptionsByPredefinedOrderId(
    String predefinedOrderId, {
    required List<String> categoryIds,
  });

  /// Retrieves sale modifier options by predefined order ID filtered with category
  Future<List<SaleModifierOptionModel>>
  getListSaleModifierOptionsByPredefinedOrderIdFilterWithCategory(
    String predefinedOrderId, {
    required List<String> categoryIds,
    required String? saleModifierId,
  });

  /// Retrieves sale modifier option models by sale ID
  Future<List<SaleModifierOptionModel>> getListSaleModifierOptionModelBySaleId(
    String saleId,
  );

  /// Retrieves list of modifier option IDs
  Future<List<String>> getListModifierOptionIds(List<String> saleModifierIds);

  // ==================== Delete Operations ====================

  /// Deletes all sale modifier option records
  Future<bool> deleteAll();

  /// Soft deletes sale modifier options by predefined order ID
  Future<bool> softDeleteSaleModifierOptionsByPredefinedOrderId(
    String predefinedOrderId,
  );

  /// Deletes sale modifier options by predefined order ID
  Future<bool> deleteSaleModifierOptionsByPredefinedOrderId(
    String predefinedOrderId,
  );
}
