import 'package:mts/data/models/page/page_model.dart';

abstract class LocalPageRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single page record
  Future<int> insert(PageModel pageModel, {required bool isInsertToPending});

  /// Updates an existing page record
  Future<int> update(PageModel pageModel, {required bool isInsertToPending});

  /// Deletes a page record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple page records at once
  Future<bool> upsertBulk(
    List<PageModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple page records at once
  Future<bool> deleteBulk(
    List<PageModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<PageModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all page records
  Future<List<PageModel>> getListPage();

  /// Retrieves the first page
  Future<PageModel> getFirstPage();

  // ==================== Delete Operations ====================

  /// Deletes all page records
  Future<bool> deleteAll();
}
