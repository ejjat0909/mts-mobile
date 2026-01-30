import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/user/user_model.dart';

abstract class LocalStaffRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single staff record
  Future<int> insert(StaffModel staff, {required bool isInsertToPending});

  /// Updates an existing staff record
  Future<int> update(StaffModel staff, {required bool isInsertToPending});

  /// Deletes a staff record by ID
  Future<int> delete(String id, {required bool isInsertToPending});

  // ==================== Bulk Operations ====================

  /// Inserts multiple staff records at once
  Future<bool> upsertBulk(
    List<StaffModel> list, {
    required bool isInsertToPending,
  });

  /// Deletes multiple staff records at once
  Future<bool> deleteBulk(
    List<StaffModel> list, {
    required bool isInsertToPending,
  });

  /// Replaces all existing data with new data
  Future<bool> replaceAllData(
    List<StaffModel> newData, {
    bool isInsertToPending = false,
  });

  // ==================== Query Operations ====================

  /// Retrieves all staff records
  Future<List<StaffModel>> getListStaffModel();

  /// Retrieves staff by shift not null
  Future<List<StaffModel>> getListStaffByShiftNotNull();

  /// Retrieves staff by current shift ID
  Future<List<StaffModel>> getListStaffByCurrentShiftId(String idShift);

  /// Retrieves a staff by ID
  Future<StaffModel?> getStaffModelById(String? staffId);

  /// Retrieves a staff by PIN
  Future<StaffModel?> getStaffModelByPin(String? staffPin);

  /// Retrieves a staff by user ID
  Future<StaffModel> getStaffModelByUserId(String userId);

  /// Retrieves a user model by staff ID
  Future<UserModel> getUserModelByStaffId(String staffId);

  /// Validates staff PIN
  Future<StaffModel> isStaffPinValid(String pinNumber);

  /// Gets first company ID
  Future<String?> getFirstCompanyId();

  /// Gets current shift from staff ID
  Future<String> getCurrentShiftFromStaffId(String staffId);

  // ==================== Delete Operations ====================

  /// Deletes all staff records
  Future<bool> deleteAll();

  /// Deletes staff where ID is null
  Future<int> deleteStaffWhereIdNull();
}
