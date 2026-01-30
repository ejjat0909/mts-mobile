import 'package:mts/data/models/shift/shift_model.dart';

abstract class LocalShiftRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single shift record
  Future<int> insert(ShiftModel shift, {required bool isInsertToPending});

  /// Updates an existing shift record
  Future<int> update(ShiftModel shift, {required bool isInsertToPending});

  /// Deletes a shift record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple shift records at once
  Future<bool> upsertBulk(
    List<ShiftModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple shift records at once
  Future<bool> deleteBulk(
    List<ShiftModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<ShiftModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all shift records
  Future<List<ShiftModel>> getListShiftModel();

  /// Retrieves shifts for history
  Future<List<ShiftModel>> getListShiftForHistory();

  /// Retrieves the latest shift
  Future<ShiftModel> getLatestShift();

  /// Retrieves shift where closed by staff and device
  Future<ShiftModel> getShiftWhereClosedBy(String staffId, String idPosDevice);

  /// Checks if shift exists
  Future<bool> hasShift();

  /// Gets the latest expected cash
  Future<double> getLatestExpectedCash();

  // ==================== Stream Operations ====================

  /// Stream for latest expected amount
  Stream<double> get getLatestExpectedAmountStream;

  /// Notifies listeners of changes
  Future<void> notifyChanges();

  /// Emits latest expected amount
  Future<void> emitLatestExpectedAmount();

  // ==================== Delete Operations ====================

  /// Deletes all shift records
  Future<bool> deleteAll();
}
