import 'package:mts/data/models/category_discount/category_discount_model.dart';
import 'package:mts/data/models/discount/discount_model.dart';

/// Interface for Local Category Discount Repository
abstract class LocalCategoryDiscountRepository {
  // ==================== CRUD Operations ====================

  /// Insert or update a category discount
  Future<int> upsert(
    CategoryDiscountModel categoryDiscountModel, {
    required bool isInsertToPending,
  });

  /// Delete a category discount pivot
  Future<int> deletePivot(
    CategoryDiscountModel categoryDiscountModel, {
    required bool isInsertToPending,
  });

  // ==================== Bulk Operations ====================

  /// Insert multiple category discounts
  Future<bool> upsertBulk(
    List<CategoryDiscountModel> list, {
    required bool isInsertToPending,
  });

  /// Delete multiple category discounts
  Future<bool> deleteBulk(
    List<CategoryDiscountModel> listCategoryDiscount, {
    required bool isInsertToPending,
  });

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<CategoryDiscountModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Get all category discounts
  Future<List<CategoryDiscountModel>> getListCategoryDiscount();

  /// Get discounts for a category
  Future<List<DiscountModel>> getDiscountModelsByCategoryId(String categoryId);

  // ==================== Delete Operations ====================

  /// Delete all category discounts
  Future<bool> deleteAll();

  /// Delete records by column name and value
  Future<int> deleteByColumnName(
    String columnName,
    dynamic value, {
    required bool isInsertToPending,
  });
}
