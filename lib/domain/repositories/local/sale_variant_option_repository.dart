import 'package:mts/data/models/sale_variant_option/sale_variant_option_model.dart';

abstract class LocalSaleVariantOptionRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single sale variant option record
  Future<int> insert(
    SaleVariantOptionModel saleVariantOption, {
    required bool isInsertToPending,
  });

  /// Updates an existing sale variant option record
  Future<int> update(
    SaleVariantOptionModel saleVariantOption, {
    required bool isInsertToPending,
  });

  /// Deletes a sale variant option record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple sale variant option records at once
  Future<bool> upsertBulk(
    List<SaleVariantOptionModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple sale variant option records at once
  Future<bool> deleteBulk(
    List<SaleVariantOptionModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<SaleVariantOptionModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all sale variant option records
  Future<List<SaleVariantOptionModel>> getListSaleVariantOption();

  // ==================== Delete Operations ====================

  /// Deletes all sale variant option records
  Future<bool> deleteAll();
}
