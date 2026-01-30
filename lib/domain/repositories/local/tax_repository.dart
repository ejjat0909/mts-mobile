import 'package:mts/data/models/tax/tax_model.dart';

abstract class LocalTaxRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single tax record
  Future<int> insert(TaxModel tax, {required bool isInsertToPending});

  /// Updates an existing tax record
  Future<int> update(TaxModel tax, {required bool isInsertToPending});

  /// Deletes a tax record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple tax records at once
  Future<bool> upsertBulk(
    List<TaxModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple tax records at once
  Future<bool> deleteBulk(
    List<TaxModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<TaxModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all tax records
  Future<List<TaxModel>> getListTaxModel();

  /// Retrieves rates by list of tax IDs
  Future<List<double>> getRatesByTaxIds(List<String> taxIds);

  /// Retrieves tax models by list of tax IDs
  Future<List<TaxModel>> getTaxModelsByTaxIds(List<String> taxIds);

  /// Retrieves tax models by item ID
  Future<List<TaxModel>> getTaxModelsByItemId(String itemId);

  // ==================== Delete Operations ====================

  /// Deletes all tax records
  Future<bool> deleteAll();
}
