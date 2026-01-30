import 'package:mts/data/models/table/table_model.dart';

abstract class LocalTableRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single table record
  Future<int> insert(TableModel table, {required bool isInsertToPending});

  /// Updates an existing table record
  Future<int> update(TableModel table, {required bool isInsertToPending});

  /// Deletes a table record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple table records at once
  Future<bool> upsertBulk(
    List<TableModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple table records at once
  Future<bool> deleteBulk(
    List<TableModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<TableModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all table records
  Future<List<TableModel>> getTables();

  /// Retrieves a table by ID
  Future<TableModel?> getTableById(String tableId);

  // ==================== Delete Operations ====================

  /// Deletes all table records
  Future<bool> deleteAll();
}
