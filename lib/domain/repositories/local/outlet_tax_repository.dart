import 'package:mts/data/models/outlet_tax/outlet_tax_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';

abstract class LocalOutletTaxRepository {
  // ==================== CRUD Operations ====================

  /// Inserts or updates an outlet tax record
  Future<int> upsert(
    OutletTaxModel outletTaxModel, {
    required bool isInsertToPending,
  });

  /// Deletes an outlet tax pivot
  Future<int> deletePivot(
    OutletTaxModel outletTaxModel, {
    required bool isInsertToPending,
  });

  // ==================== Bulk Operations ====================

  /// Inserts multiple outlet tax records at once
  Future<bool> upsertBulk(
    List<OutletTaxModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple outlet tax records at once
  Future<bool> deleteBulk(
    List<OutletTaxModel> listOutletTax, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<OutletTaxModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all outlet tax records
  Future<List<OutletTaxModel>> getListOutletTax();

  /// Retrieves all outlet tax models
  Future<List<OutletTaxModel>> getListOutletTaxModel();

  /// Retrieves tax models by outlet ID
  Future<List<TaxModel>> getTaxModelsByOutletId(String idOutlet);

  // ==================== Delete Operations ====================

  /// Deletes all outlet tax records
  Future<bool> deleteAll();

  /// Deletes records by column name and value
  Future<int> deleteByColumnName(
    String columnName,
    dynamic value, {
    required bool isInsertToPending,
  });
}
