import 'package:mts/data/models/table_section/table_section_model.dart';

abstract class LocalTableSectionRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single table section record
  Future<int> insert(
    TableSectionModel section, {
    required bool isInsertToPending,
  });

  /// Updates an existing table section record
  Future<int> update(
    TableSectionModel section, {
    required bool isInsertToPending,
  });

  /// Deletes a table section record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple table section records at once
  Future<bool> upsertBulk(
    List<TableSectionModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple table section records at once
  Future<bool> deleteBulk(
    List<TableSectionModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<TableSectionModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all table section records
  Future<List<TableSectionModel>> getTableSections();

  /// Retrieves a table section by ID
  Future<TableSectionModel?> getTableSectionById(String sectionId);

  // ==================== Delete Operations ====================

  /// Deletes all table section records
  Future<bool> deleteAll();
}
