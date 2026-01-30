import 'package:mts/data/models/division/division_model.dart';

abstract class LocalDivisionRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single division record
  Future<int> insert(
    DivisionModel divisionModel, {
    required bool isInsertToPending,
  });

  /// Updates an existing division record
  Future<int> update(
    DivisionModel divisionModel, {
    required bool isInsertToPending,
  });

  /// Deletes a division record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple division records at once
  Future<bool> upsertBulk(
    List<DivisionModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple division records at once
  Future<bool> deleteBulk(
    List<DivisionModel> listDivision, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<DivisionModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all division records
  Future<List<DivisionModel>> getListDivisionModel();

  /// Retrieves a division by ID
  Future<DivisionModel?> getDivisionModelById(String divisionId);
}
