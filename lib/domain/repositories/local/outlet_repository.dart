import 'package:mts/data/models/outlet/outlet_model.dart';

abstract class LocalOutletRepository {
  // ==================== CRUD Operations ====================

  /// Deletes an outlet record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple outlet records at once
  Future<bool> upsertBulk(
    List<OutletModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple outlet records at once
  Future<bool> deleteBulk(
    List<OutletModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<OutletModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all outlet records
  Future<List<OutletModel>> getListOutletModel();

  /// Retrieves an outlet by ID
  Future<OutletModel> getOutletModelById(String idOutlet);

  /// Retrieves the latest outlet model
  Future<OutletModel> getLatestOutletModel();

  // ==================== Delete Operations ====================

  /// Deletes all outlet records
  Future<bool> deleteAll();
}
