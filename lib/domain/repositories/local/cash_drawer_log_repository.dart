import 'package:mts/data/models/cash_drawer_log/cash_drawer_log_model.dart';

abstract class CashDrawerLogRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single cash drawer log record
  Future<int> insert(
    CashDrawerLogModel cashDrawerLogModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing cash drawer log record
  Future<int> update(
    CashDrawerLogModel cashDrawerLogModel, {
    required bool isInsertToPending,
  });

  /// Upserts a cash drawer log record (insert if new, update if exists)
  Future<int> upsert(
    CashDrawerLogModel cashDrawerLogModel, {
    required bool isInsertToPending,
  });

  /// Deletes a cash drawer log record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts/updates multiple cash drawer log records at once
  Future<bool> upsertBulk(
    List<CashDrawerLogModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<CashDrawerLogModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all cash drawer log records
  Future<List<CashDrawerLogModel>> getListCashDrawerLogs();

  // ==================== Delete Operations ====================

  /// Deletes all cash drawer log records
  Future<bool> deleteAll();
}
