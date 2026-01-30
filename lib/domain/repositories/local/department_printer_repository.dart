import 'package:mts/data/models/department_printer/department_printer_model.dart';

abstract class LocalDepartmentPrinterRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single department printer record
  Future<int> insert(
    DepartmentPrinterModel model, {
    required bool isInsertToPending,
  });

  /// Updates an existing department printer record
  Future<int> update(
    DepartmentPrinterModel model, {
    required bool isInsertToPending,
  });

  /// Deletes a department printer record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple department printer records at once
  Future<bool> upsertBulk(
    List<DepartmentPrinterModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple department printer records at once
  Future<bool> deleteBulk(
    List<DepartmentPrinterModel> list, {
    required bool isInsertToPending,
  });

  // ==================== Query Operations ====================

  /// Retrieves all department printer records
  Future<List<DepartmentPrinterModel>> getListDepartmentPrinter();

  /// Retrieves a department printer by ID
  Future<DepartmentPrinterModel?> getDepartmentPrinterById(String idDP);

  /// Retrieves department printers by list of department IDs
  Future<List<DepartmentPrinterModel>> getListDepartmentPrintersFromIds(
    List<String> departments,
  );
}
