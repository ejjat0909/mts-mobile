import 'package:mts/data/models/item_tax/item_tax_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';

abstract class LocalItemTaxRepository {
  // ==================== CRUD Operations ====================

  /// Inserts or updates an item tax record
  Future<int> upsert(
    ItemTaxModel itemTaxModel, {
    required bool isInsertToPending,
  });

  /// Deletes an item tax pivot
  Future<int> deletePivot(
    ItemTaxModel itemTaxModel, {
    required bool isInsertToPending,
  });

  // ==================== Bulk Operations ====================

  /// Inserts multiple item tax records at once
  Future<bool> upsertBulk(
    List<ItemTaxModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple item tax records at once
  Future<bool> deleteBulk(
    List<ItemTaxModel> listItemTax, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<ItemTaxModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all item tax records
  Future<List<ItemTaxModel>> getListItemTax();

  /// Retrieves tax models by item ID
  Future<List<TaxModel>> getTaxModelsByItemId(String idItem);

  // ==================== Delete Operations ====================

  /// Deletes all item tax records
  Future<bool> deleteAll();

  /// Deletes records by column name and value
  Future<int> deleteByColumnName(
    String columnName,
    dynamic value, {
    required bool isInsertToPending,
  });
}
