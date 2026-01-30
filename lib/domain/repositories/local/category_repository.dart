import 'package:mts/data/models/category/category_model.dart';

/// Interface for Local Category Repository
abstract class LocalCategoryRepository {
  // ==================== CRUD Operations ====================

  /// Insert a new category
  Future<int> insert(
    CategoryModel categoryModel, {
    required bool isInsertToPending,
  });

  /// Delete a category by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Insert multiple categories

  Future<bool> upsertBulk(
    List<CategoryModel> list, {
    required bool isInsertToPending,
  });

  /// Delete multiple categories
  Future<bool> deleteBulk(
    List<CategoryModel> listCategory, {
    required bool isInsertToPending,
  });

  /// Replace all data in the table with new data
  Future<bool> replaceAllData(
    List<CategoryModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Get all categories
  Future<List<CategoryModel>> getListCategoryModel();

  // ==================== Delete Operations ====================

  /// Delete all categories
  Future<bool> deleteAll();
}
