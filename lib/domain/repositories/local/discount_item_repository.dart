import 'package:mts/data/models/discount/discount_model.dart';
import 'package:mts/data/models/discount_item/discount_item_model.dart';

abstract class LocalDiscountItemRepository {
  // ==================== CRUD Operations ====================

  /// Inserts or updates a discount item record
  Future<int> upsert(DiscountItemModel row, {required bool isInsertToPending});

  /// Deletes a discount item pivot
  Future<int> deletePivot(
    DiscountItemModel discountItemModel, {
    required bool isInsertToPending,
  });

  // ==================== Bulk Operations ====================

  /// Inserts multiple discount item records at once
  Future<bool> upsertBulk(
    List<DiscountItemModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple discount item records at once
  Future<bool> deleteBulk(
    List<DiscountItemModel> listDiscountItem, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<DiscountItemModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all discount item records
  Future<List<DiscountItemModel>> getListDiscountItem();

  /// Retrieves valid discount models by item ID
  Future<List<DiscountModel>> getValidDiscountModelsByItemId(String idItem);

  // ==================== Delete Operations ====================

  /// Deletes all discount item records
  Future<bool> deleteAll();

  /// Deletes records by column name and value
  Future<int> deleteByColumnName(
    String columnName,
    dynamic value, {
    required bool isInsertToPending,
  });
}
