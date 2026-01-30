import 'package:mts/data/models/printing_log/printing_log_model.dart';

abstract class LocalPrintingLogRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single printing log record
  Future<int> insert(
    PrintingLogModel printingLogModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing printing log record
  Future<int> update(
    PrintingLogModel printingLogModel, {
    required bool isInsertToPending,
  });

  /// Deletes a printing log record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple printing log records at once
  Future<bool> upsertBulk(
    List<PrintingLogModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple printing log records at once
  Future<bool> deleteBulk(
    List<PrintingLogModel> listPrintingLog, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<PrintingLogModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all printing log records
  Future<List<PrintingLogModel>> getListPrintingLogModel();

  // ==================== Delete Operations ====================

  /// Deletes all printing log records
  Future<bool> deleteAll();
}
