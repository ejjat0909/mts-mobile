import 'package:mts/data/models/error_log/error_log_model.dart';

abstract class LocalErrorLogRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single error log record
  Future<int> insert(
    ErrorLogModel errorLogModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing error log record
  Future<int> update(
    ErrorLogModel errorLogModel, {
    required bool isInsertToPending,
  });

  /// Deletes an error log record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple error log records at once
  Future<bool> upsertBulk(
    List<ErrorLogModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple error log records at once
  Future<bool> deleteBulk(
    List<ErrorLogModel> listErrorLog, {
    required bool isInsertToPending,
  });

  // ==================== Query Operations ====================

  /// Retrieves all error log records
  Future<List<ErrorLogModel>> getListErrorLogModel();

  // ==================== Delete Operations ====================

  /// Deletes all error log records
  Future<bool> deleteAll();

  // ==================== Utility Operations ====================

  /// Creates and inserts an error log with message
  Future<void> createAndInsertErrorLog(String message);
}
