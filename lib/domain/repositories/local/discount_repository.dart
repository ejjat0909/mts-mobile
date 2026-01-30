import 'package:mts/data/models/discount/discount_model.dart';

abstract class LocalDiscountRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single discount record
  Future<int> insert(
    DiscountModel discountModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing discount record
  Future<int> update(
    DiscountModel discountModel, {
    required bool isInsertToPending,
  });

  /// Deletes a discount record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple discount records at once
  Future<bool> upsertBulk(
    List<DiscountModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple discount records at once
  Future<bool> deleteBulk(
    List<DiscountModel> listDiscount, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<DiscountModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all discount records
  Future<List<DiscountModel>> getListDiscountModel();

  /// Retrieves discount models by item ID
  Future<List<DiscountModel>> getDiscountModelByItemId(String itemId);

  /// Retrieves discount models by list of discount IDs
  Future<List<DiscountModel>> getDiscountModelsByDiscountIds(
    List<String> discountIds,
  );

  // ==================== Delete Operations ====================

  /// Deletes all discount records
  Future<bool> deleteAll();
}
