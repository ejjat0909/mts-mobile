import 'package:mts/data/models/order_option_tax/order_option_tax_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';

abstract class LocalOrderOptionTaxRepository {
  // ==================== CRUD Operations ====================

  /// Inserts or updates an order option tax record
  Future<int> upsert(
    OrderOptionTaxModel orderOptionTaxModel, {
    required bool isInsertToPending,
  });

  /// Deletes an order option tax record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  /// Deletes an order option tax pivot
  Future<int> deletePivot(
    OrderOptionTaxModel orderOptionTaxModel, {
    required bool isInsertToPending,
  });

  // ==================== Bulk Operations ====================

  /// Inserts multiple order option tax records at once
  Future<bool> upsertBulk(
    List<OrderOptionTaxModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple order option tax records at once
  Future<bool> deleteBulk(
    List<OrderOptionTaxModel> listOrderOptionTax, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<OrderOptionTaxModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all order option tax records
  Future<List<OrderOptionTaxModel>> getListOrderOptionTax();

  /// Retrieves tax models by order option ID
  Future<List<TaxModel>> getTaxModelsByOrderOptionId(String idOrderOption);

  // ==================== Delete Operations ====================

  /// Deletes all order option tax records
  Future<bool> deleteAll();

  /// Deletes records by column name and value
  Future<int> deleteByColumnName(
    String columnName,
    dynamic value, {
    bool isInsertToPending = false,
  });
}
