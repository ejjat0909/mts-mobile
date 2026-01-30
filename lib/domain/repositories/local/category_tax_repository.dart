import 'package:mts/data/models/category_tax/category_tax_model.dart';

/// Interface for Local Category Tax Repository
abstract class LocalCategoryTaxRepository {
  // ==================== CRUD Operations ====================

  /// Insert or update a category tax
  Future<int> upsert(
    CategoryTaxModel categoryTaxModel, {
    required bool isInsertToPending,
  });

  /// Delete a category tax pivot
  Future<int> deletePivot(
    CategoryTaxModel categoryTaxModel, {
    required bool isInsertToPending,
  });

  // ==================== Bulk Operations ====================

  /// Insert multiple category taxes
  Future<bool> upsertBulk(
    List<CategoryTaxModel> list, {
    required bool isInsertToPending,
  });

  /// Delete multiple category taxes
  Future<bool> deleteBulk(
    List<CategoryTaxModel> listCategoryTax, {
    required bool isInsertToPending,
  });

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<CategoryTaxModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Get all category taxes
  Future<List<CategoryTaxModel>> getListCategoryTax();

  // ==================== Delete Operations ====================

  /// Delete all category taxes
  Future<bool> deleteAll();

  /// Delete records by column name
  Future<int> deleteByColumnName(
    String columnName,
    dynamic value, {
    required bool isInsertToPending,
  });
}
