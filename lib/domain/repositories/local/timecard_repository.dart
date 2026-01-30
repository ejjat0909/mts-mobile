import 'package:mts/data/models/time_card/timecard_model.dart';

abstract class LocalTimecardRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single timecard record
  Future<int> insert(TimecardModel timecard, {required bool isInsertToPending});

  /// Updates an existing timecard record
  Future<int> update(TimecardModel timecard, {required bool isInsertToPending});

  /// Deletes a timecard record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple timecard records at once
  Future<bool> upsertBulk(
    List<TimecardModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple timecard records at once
  Future<bool> deleteBulk(
    List<TimecardModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<TimecardModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all timecard records
  Future<List<TimecardModel>> getListTimeCard();

  /// Retrieves current timecard by staff ID
  Future<TimecardModel> getCurrentTimecard(String staffId);

  // ==================== Delete Operations ====================

  /// Deletes all timecard records
  Future<bool> deleteAll();
}
