import 'package:mts/data/models/permission/permission_model.dart';

abstract class LocalPermissionRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single permission record
  Future<int> insert(PermissionModel model, {required bool isInsertToPending});

  /// Updates an existing permission record
  Future<int> update(PermissionModel model, {required bool isInsertToPending});

  /// Deletes a permission record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple permission records at once
  Future<bool> upsertBulk(
    List<PermissionModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple permission records at once
  Future<bool> deleteBulk(
    List<PermissionModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<PermissionModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all permission records
  Future<List<PermissionModel>> getListPermissions();

  /// Retrieves all permission models
  Future<List<PermissionModel>> getListPermissionModel();

  /// Retrieves a permission by ID
  Future<PermissionModel?> getPermissionById(String idPermission);

  // ==================== Delete Operations ====================

  /// Deletes all permission records
  Future<bool> deleteAll();
}
