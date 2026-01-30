import 'package:mts/data/models/user/user_model.dart';

abstract class LocalUserRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single user record
  Future<int> insert(UserModel user, {required bool isInsertToPending});

  /// Updates an existing user record
  Future<int> update(UserModel user, {required bool isInsertToPending});

  /// Deletes a user record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple user records at once
  Future<bool> upsertBulk(
    List<UserModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple user records at once
  Future<bool> deleteBulk(
    List<UserModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<UserModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all user records
  Future<List<UserModel>> getListUserModels();

  /// Retrieves a user by user ID
  Future<UserModel?> getUserModelByIdUser(int userId);

  /// Retrieves a user by staff ID
  Future<UserModel?> getUserModelFromStaffId(String staffId);

  // ==================== Delete Operations ====================

  /// Deletes all user records
  Future<bool> deleteAll();
}
