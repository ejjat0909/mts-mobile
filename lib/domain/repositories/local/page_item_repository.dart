import 'package:mts/data/models/page_item/page_item_model.dart';

abstract class LocalPageItemRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single page item record
  Future<int> insert(
    PageItemModel pageItemModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing page item record
  Future<int> update(
    PageItemModel pageItemModel, {
    required bool isInsertToPending,
  });

  /// Deletes a page item record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple page item records at once
  Future<bool> upsertBulk(
    List<PageItemModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple page item records at once
  Future<bool> deleteBulk(
    List<PageItemModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<PageItemModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all page item records
  Future<List<PageItemModel>> getListPageItemModel();

  /// Retrieves page items with conditions
  Future<List<PageItemModel>> getListPageItemsWithConditions(
    Map<String, dynamic> conditions,
  );

  /// Retrieves all page IDs
  Future<List<String>> getAllPageIds();

  // ==================== Delete Operations ====================

  /// Deletes all page item records
  Future<bool> deleteAll();

  /// Deletes page items by page ID
  Future<bool> deletePageItemsByPageId(String pageId);

  /// Deletes records with conditions
  Future<int> deleteDbWithConditions(
    String tableName,
    Map<String, dynamic> conditions, {
    required bool isInsertToPending,
  });
}
