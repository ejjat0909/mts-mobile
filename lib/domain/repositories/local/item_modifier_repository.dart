import 'package:mts/data/models/item_modifier/item_modifier_model.dart';

abstract class LocalItemModifierRepository {
  // ==================== CRUD Operations ====================

  /// Inserts or updates an item modifier record
  Future<int> upsert(
    ItemModifierModel itemModifierModel, {
    required bool isInsertToPending,
  });

  /// Deletes an item modifier pivot
  Future<int> deletePivot(
    ItemModifierModel itemModifier, {
    required bool isInsertToPending,
  });

  // ==================== Bulk Operations ====================

  /// Inserts multiple item modifier records at once
  Future<bool> upsertBulk(
    List<ItemModifierModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple item modifier records at once
  Future<bool> deleteBulk(
    List<ItemModifierModel> listItemModifier, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<ItemModifierModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all item modifier records
  Future<List<ItemModifierModel>> getListItemModifier();

  /// Retrieves modifier IDs by item ID
  Future<List<String?>> getModifierIdsByItemId(String id);

  // ==================== Delete Operations ====================

  /// Deletes all item modifier records
  Future<bool> deleteAll();

  /// Deletes records by column name and value
  Future<int> deleteByColumnName(
    String columnName,
    dynamic value, {
    required bool isInsertToPending,
  });
}
