import 'package:mts/data/models/cash_management/cash_management_model.dart';

abstract class LocalCashManagementRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single cash management record
  Future<int> insert(
    CashManagementModel cashManagementModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing cash management record
  Future<int> update(
    CashManagementModel cashManagementModel, {
    required bool isInsertToPending,
  });

  /// Deletes a cash management record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple cash management records at once
  Future<bool> upsertBulk(
    List<CashManagementModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple cash management records at once
  Future<bool> deleteBulk(
    List<CashManagementModel> listCMM, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<CashManagementModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all cash management records
  Future<List<CashManagementModel>> getListCashManagementModel();

  /// Retrieves cash management records that are not synced
  Future<List<CashManagementModel>> getListCashManagementNotSynced();

  /// Retrieves cash management records by shift
  Future<List<CashManagementModel>> getCashManagementListByShift();

  // ==================== Calculation Operations ====================

  // /// Gets the sum of pay-in amounts not synced
  // Future<double> getSumAmountPayInNotSynced();
  // /// Gets the sum of pay-out amounts not synced
  // Future<double> getSumAmountPayOutNotSynced();

  // ==================== Stream Operations ====================

  // /// Stream for sum of pay-out amounts
  // Stream<double> get getSumPayOutStream;

  // /// Stream for sum of pay-in amounts
  // Stream<double> get getSumPayInStream;

  /// Notifies listeners of changes
  // Future<void> notifyChanges();
  /* 
  /// Emits sum of pay-out amounts not synced
  Future<void> emitSumAmountPayOutNotSynced();

  /// Emits sum of pay-in amounts not synced
  Future<void> emitSumAmountPayInNotSynced(); */

  // ==================== Delete Operations ====================

  /// Deletes all cash management records
  Future<bool> deleteAll();
}
