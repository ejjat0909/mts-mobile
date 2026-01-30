import 'package:mts/data/models/item/item_model.dart';

abstract class LocalItemRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single item record
  Future<int> insert(ItemModel itemModel, {required bool isInsertToPending});

  /// Updates an existing item record
  Future<int> update(ItemModel itemModel, {required bool isInsertToPending});

  /// Deletes an item record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple item records at once
  Future<bool> upsertBulk(
    List<ItemModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple item records at once
  Future<bool> deleteBulk(
    List<ItemModel> listItem, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<ItemModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all item records
  Future<List<ItemModel>> getListItemModel();

  /// Retrieves an item by ID
  Future<ItemModel?> getItemModelById(String itemId);

  /// Retrieves items by list of IDs
  Future<List<ItemModel>> getItemModelsByIds(List<String> itemIds);

  /// Retrieves inventory ID by item ID
  Future<String?> getInventoryIdByItemId(
    String? idItem, {
    required String? variantOptionJson,
  });

  /// Retrieves variant option JSON by item ID
  Future<String?> getVariantOptionJsonByItemId(String idItem);

  // ==================== Delete Operations ====================

  /// Deletes all item records
  Future<bool> deleteAll();
}
