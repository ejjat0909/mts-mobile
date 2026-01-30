import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_model.dart';

abstract class LocalPrintReceiptCacheRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single print receipt cache record
  Future<int> insert(
    PrintReceiptCacheModel printReceiptCacheModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing print receipt cache record
  Future<int> update(
    PrintReceiptCacheModel printReceiptCacheModel, {
    required bool isInsertToPending,
  });

  /// Deletes a print receipt cache record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple print receipt cache records at once
  Future<bool> upsertBulk(
    List<PrintReceiptCacheModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple print receipt cache records at once
  Future<bool> deleteBulk(
    List<PrintReceiptCacheModel> listPrintReceiptCache, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<PrintReceiptCacheModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all print receipt cache records
  Future<List<PrintReceiptCacheModel>> getListPrintReceiptCacheModel();

  /// Retrieves print receipt cache records with pending or failed status
  Future<List<PrintReceiptCacheModel>>
  getListPrintReceiptCacheWithPendingOrFailed();

  /// Retrieves print receipt cache records with pending status
  Future<List<PrintReceiptCacheModel>>
  getListPrintReceiptCacheWithPendingStatus();

  /// Retrieves print receipt cache records with processing status
  Future<List<PrintReceiptCacheModel>>
  getListPrintReceiptCacheWithProcessingStatus();

  /// Retrieves model by sale ID
  Future<PrintReceiptCacheModel?> getModelBySaleId(String saleId);

  // ==================== Utility Operations ====================

  /// Checks if table exists
  Future<bool> tableExists();

  /// Only inserts to pending
  Future<bool> onlyInsertToPending(PrintReceiptCacheModel model);

  // ==================== Delete Operations ====================

  /// Deletes all print receipt cache records
  Future<bool> deleteAll();

  /// Deletes by success, cancel status, and failed
  Future<bool> deleteBySuccessAndCancelStatusAndFailed();
}
