import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/data/repositories/local/local_user_repository_impl.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:mts/domain/repositories/local/staff_repository.dart';
import 'package:mts/domain/repositories/local/user_repository.dart';
import 'package:sqflite/sqflite.dart';

final staffBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(StaffModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final staffLocalRepoProvider = Provider<LocalStaffRepository>((ref) {
  return LocalStaffRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
    hiveBox: ref.read(staffBoxProvider),
    userRepository: ref.read(userLocalRepoProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalStaffRepository] that uses local database
class LocalStaffRepositoryImpl implements LocalStaffRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;
  final LocalUserRepository _userRepository;
  static const String tableName = 'staffs';

  /// Database table and column names
  static const String cId = 'id';
  static const String pin = 'pin';
  static const String userId = 'user_id';

  static const String companyId = 'company_id';
  static const String cCurrentShiftId = 'current_shift_id';
  static const String roleGroupId = 'role_group_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  /// Constructor
  LocalStaffRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required LocalPendingChangesRepository pendingChangesRepository,
    required Box<Map> hiveBox,
    required LocalUserRepository userRepository,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox,
       _userRepository = userRepository;

  /// Create the staff table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $pin TEXT NULL,
      $userId INTEGER NULL,
      $companyId TEXT NULL,
      $cCurrentShiftId TEXT NULL,
      $roleGroupId TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new staff
  @override
  Future<int> insert(
    StaffModel staffModel, {
    required bool isInsertToPending,
  }) async {
    staffModel.id ??= IdUtils.generateUUID().toString();
    staffModel.updatedAt = DateTime.now();
    staffModel.createdAt = DateTime.now();
    int result = await _dbHelper.insertDb(tableName, staffModel.toJson());
    await _hiveBox.put(staffModel.id, staffModel.toJson());

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'created',
        modelName: StaffModel.modelName,
        modelId: staffModel.id,
        data: jsonEncode(staffModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    return result;
  }

  // update
  @override
  Future<int> update(
    StaffModel staffModel, {
    required bool isInsertToPending,
  }) async {
    staffModel.updatedAt = DateTime.now();
    int result = await _dbHelper.updateDb(tableName, staffModel.toJson());
    await _hiveBox.put(staffModel.id, staffModel.toJson());

    // Insert to pending changes if required
    if (isInsertToPending) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: StaffModel.modelName,
        modelId: staffModel.id,
        data: jsonEncode(staffModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    return result;
  }

  // delete using id
  @override
  Future<int> delete(String id, {required bool isInsertToPending}) async {
    // Get the model before deleting it
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> results = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      final model = StaffModel.fromJson(results.first);

      // Delete the record
      await _hiveBox.delete(id);
      int result = await _dbHelper.deleteDb(tableName, id);

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: StaffModel.modelName,
          modelId: model.id,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No staff record found with id: $id');
      return 0;
    }
  }

  // get list staff model
  @override
  Future<List<StaffModel>> getListStaffModel() async {
    final hiveList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => StaffModel.fromJson(json),
    );

    if (hiveList.isNotEmpty) {
      return hiveList;
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return StaffModel.fromJson(maps[index]);
    });
  }

  @override
  Future<bool> upsertBulk(
    List<StaffModel> listStaff, {
    required bool isInsertToPending,
  }) async {
    try {
      // First, collect all existing IDs in a single query to check for creates vs updates
      // This eliminates the race condition: single query instead of per-item checks
      Database db = await _dbHelper.database;
      final idsToInsert =
          listStaff.map((m) => m.id).whereType<String>().toList();

      final existingIds = <String>{};
      if (idsToInsert.isNotEmpty) {
        final placeholders = List.filled(idsToInsert.length, '?').join(',');
        final existingRecords = await db.query(
          tableName,
          where: '$cId IN ($placeholders)',
          whereArgs: idsToInsert,
          columns: [cId],
        );
        existingIds.addAll(existingRecords.map((r) => r[cId] as String));
      }

      // Prepare pending changes to track after batch commit
      final List<PendingChangesModel> pendingChanges = [];

      // Use a single batch for all operations (atomic)
      // Key: Only ONE pre-flight check before batch, not per-item checks
      Batch batch = db.batch();

      for (StaffModel model in listStaff) {
        if (model.id == null) continue;

        final isExisting = existingIds.contains(model.id);
        final modelJson =
            model.toJson()
              ..[updatedAt] = DateTimeUtils.getDateTimeFormat(DateTime.now());

        if (isExisting) {
          // Only update if new item is newer than existing one
          batch.update(
            tableName,
            modelJson,
            where: '$cId = ? AND ($updatedAt IS NULL OR $updatedAt <= ?)',
            whereArgs: [
              model.id,
              DateTimeUtils.getDateTimeFormat(model.updatedAt),
            ],
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'updated',
                modelName: StaffModel.modelName,
                modelId: model.id!,
                data: jsonEncode(modelJson),
              ),
            );
          }
        } else {
          // New item - use INSERT OR IGNORE for atomic conflict resolution
          // If two workers race here, one succeeds, the other is silently ignored
          batch.rawInsert(
            '''INSERT OR IGNORE INTO $tableName (${modelJson.keys.join(',')})
               VALUES (${List.filled(modelJson.length, '?').join(',')})''',
            modelJson.values.toList(),
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'created',
                modelName: StaffModel.modelName,
                modelId: model.id!,
                data: jsonEncode(modelJson),
              ),
            );
          }
        }
      }

      // Commit batch atomically
      await batch.commit(noResult: true);
      // Sync to Hive cache after successful batch commit
      await _hiveBox.putAll(
        Map.fromEntries(
          listStaff
              .where((m) => m.id != null)
              .map((m) => MapEntry(m.id!, m.toJson())),
        ),
      );
      // Track pending changes AFTER successful batch commit
      // This ensures we only track changes that actually succeeded
      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      prints('Error inserting bulk staff: $e');
      return false;
    }
  }

  // Future<bool> insertBulkOverwrite(List<StaffModel> listStaff) async {
  //   Database db = await _dbHelper.database;
  //   Batch batch = db.batch();

  //   try {
  //     for (StaffModel staff in listStaff) {
  //       batch.insert(tableName, staff.toJson(),
  //           conflictAlgorithm:
  //               ConflictAlgorithm.replace // Overwrite on conflict
  //           );
  //     }
  //     await batch.commit(noResult: true);
  //     return true;
  //   } catch (e) {
  //     prints('Error inserting bulk staff: $e');
  //     return false;
  //   }
  // }

  @override
  Future<StaffModel> isStaffPinValid(String pinNumber) async {
    List<StaffModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => StaffModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list.firstWhere(
        (element) => element.pin == pinNumber,
        orElse: () => StaffModel(),
      );
    }
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$pin = ?',
      whereArgs: [pinNumber],
    );
    if (maps.isNotEmpty) {
      return StaffModel.fromJson(maps.first);
    } else {
      return StaffModel();
    }
  }

  @override
  Future<StaffModel> getStaffModelByUserId(String idUser) async {
    List<StaffModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => StaffModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list.firstWhere(
        (element) => element.userId.toString() == idUser,
        orElse: () => StaffModel(),
      );
    }
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$userId = ?',
      whereArgs: [idUser],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return StaffModel.fromJson(maps.first);
    } else {
      return StaffModel();
    }
  }

  // get userModel by staff id
  @override
  Future<UserModel> getUserModelByStaffId(String idStaff) async {
    // Try to get staff from Hive first
    List<StaffModel> staffList = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => StaffModel.fromJson(json),
    );
    if (staffList.isNotEmpty) {
      try {
        // Find the staff with matching id
        final staff = staffList.firstWhere(
          (element) => element.id == idStaff,
          orElse: () => StaffModel(),
        );
        if (staff.id != null && staff.userId != null) {
          // Get users from Hive first
          List<UserModel> userList = await _userRepository.getListUserModels();

          if (userList.isNotEmpty) {
            try {
              // Find the user with matching id
              final user = userList.firstWhere(
                (element) => element.id == int.parse(staff.userId.toString()),
                orElse: () => UserModel(),
              );
              if (user.id != null) return user;
            } catch (e) {
              // User not found in Hive, fall back to SQLite
            }
          }

          // Fallback: Query the user table to get the user model from SQLite
          Database db = await _dbHelper.database;
          List<Map<String, dynamic>> userMaps = await db.query(
            LocalUserRepositoryImpl.tableName,
            where: '${LocalUserRepositoryImpl.cId} = ?',
            whereArgs: [staff.userId.toString()],
            limit: 1,
          );

          if (userMaps.isNotEmpty) {
            return UserModel.fromJson(userMaps.first);
          }
        }
      } catch (e) {
        // Staff not found in Hive, fall back to SQLite
      }
    }

    // Fallback to SQLite approach
    Database db = await _dbHelper.database;

    // Query the staff_table to get the userId based on staffId
    List<Map<String, dynamic>> staffMaps = await db.query(
      LocalStaffRepositoryImpl.tableName,
      columns: [LocalStaffRepositoryImpl.userId],
      where: '${LocalStaffRepositoryImpl.cId} = ?',
      whereArgs: [idStaff],
      limit: 1,
    );

    if (staffMaps.isNotEmpty) {
      String idUser =
          staffMaps.first[LocalStaffRepositoryImpl.userId].toString();

      // Query the user table to get the user model
      List<Map<String, dynamic>> userMaps = await db.query(
        LocalUserRepositoryImpl.tableName,
        where: '${LocalUserRepositoryImpl.cId} = ?',
        whereArgs: [idUser],
        limit: 1,
      );

      if (userMaps.isNotEmpty) {
        return UserModel.fromJson(userMaps.first);
      }
    }

    return UserModel();
  }

  @override
  Future<StaffModel?> getStaffModelById(String? idStaff) async {
    Database db = await _dbHelper.database;
    if (idStaff == null) {
      return null;
    }
    List<StaffModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => StaffModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list.where((element) => element.id == idStaff).firstOrNull;
    }
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [idStaff],
    );
    if (maps.isNotEmpty) {
      return StaffModel.fromJson(maps.first);
    } else {
      return null;
    }
  }

  // Method to get the value of company_id from the first row
  @override
  Future<String?> getFirstCompanyId() async {
    List<StaffModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => StaffModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list.first.companyId;
    }
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: [companyId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first[companyId] as String?;
    } else {
      return null;
    }
  }

  @override
  Future<bool> deleteBulk(
    List<StaffModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    try {
      for (StaffModel staff in list) {
        batch.delete(tableName, where: '$cId = ?', whereArgs: [staff.id]);

        // Insert to pending changes if required
        if (isInsertToPending) {
          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: StaffModel.modelName,
            modelId: staff.id,
            data: jsonEncode(staff.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }

      // Sync deletions to Hive cache
      await _hiveBox.deleteAll(
        list.where((m) => m.id != null).map((m) => m.id!).toList(),
      );
      await batch.commit(noResult: true);
      return true;
    } catch (e) {
      prints('Error deleting bulk staff: $e');
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<StaffModel> newData, {
    bool isInsertToPending = false,
  }) async {
    try {
      // Step 1: Delete all existing data
      Database db = await _dbHelper.database;
      await db.delete(tableName);
      await _hiveBox.clear();

      // Step 2: Insert new data using existing insertBulk method
      if (newData.isNotEmpty) {
        bool insertResult = await upsertBulk(
          newData,
          isInsertToPending: isInsertToPending,
        );
        if (!insertResult) {
          prints('Failed to insert bulk data in $tableName');
          return false;
        }
      }

      // Note: Pending changes for insertion are handled by insertBulk method
      // when isInsertToPending is true

      return true;
    } catch (e) {
      prints('Error replacing all data in $tableName: $e');
      return false;
    }
  }

  @override
  Future<StaffModel?> getStaffModelByPin(String? staffPin) async {
    List<StaffModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => StaffModel.fromJson(json),
    );
    if (staffPin == null) return null;
    if (list.isNotEmpty) {
      return list.where((element) => element.pin == staffPin).firstOrNull;
    }
    Database db = await _dbHelper.database;
    try {
      List<Map<String, dynamic>> results = await db.query(
        tableName,
        where: '$pin = ?',
        whereArgs: [staffPin],
      );
      if (results.isNotEmpty) {
        return StaffModel.fromJson(results.first);
      } else {
        return null;
      }
    } catch (e) {
      prints('Error getting staff by pin: $e');
      return null;
    }
  }

  @override
  Future<List<StaffModel>> getListStaffByShiftNotNull() async {
    List<StaffModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => StaffModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list.where((element) => element.currentShiftId != null).toList();
    }
    Database db = await _dbHelper.database;
    try {
      List<Map<String, dynamic>> results = await db.query(
        tableName,
        where: '$cCurrentShiftId IS NOT NULL',
      );
      return results.map((e) => StaffModel.fromJson(e)).toList();
    } catch (e) {
      prints('Error getting list staff by shift not null: $e');
      return [];
    }
  }

  @override
  Future<List<StaffModel>> getListStaffByCurrentShiftId(String idShift) async {
    List<StaffModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => StaffModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      return list
          .where((element) => element.currentShiftId == idShift)
          .toList();
    }
    Database db = await _dbHelper.database;
    try {
      List<Map<String, dynamic>> results = await db.query(
        tableName,
        where: '$cCurrentShiftId = ?',
        whereArgs: [idShift],
      );
      return results.map((e) => StaffModel.fromJson(e)).toList();
    } catch (e) {
      prints('Error getting list staff by current shift id: $e');
      return [];
    }
  }

  @override
  Future<int> deleteStaffWhereIdNull() async {
    Database db = await _dbHelper.database;

    return await db.delete(tableName, where: '$cId IS NULL');
  }

  /// Delete all staff from Hive box and SQLite
  @override
  Future<bool> deleteAll() async {
    try {
      await _hiveBox.clear();
      Database db = await _dbHelper.database;
      await db.delete(tableName);
      return true;
    } catch (e) {
      await LogUtils.error('Error deleting all staff', e);
      return false;
    }
  }

  @override
  Future<String> getCurrentShiftFromStaffId(String staffId) async {
    List<StaffModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: (json) => StaffModel.fromJson(json),
    );
    if (list.isNotEmpty) {
      String currentShiftId =
          list
              .where((element) => element.id == staffId)
              .map((e) => e.currentShiftId ?? '-2')
              .first;

      return currentShiftId;
    }

    Database db = await _dbHelper.database;
    try {
      List<Map<String, dynamic>> results = await db.query(
        tableName,
        where: '$cId = ?',
        whereArgs: [staffId],
        limit: 1,
      );
      return results
              .map((e) => StaffModel.fromJson(e))
              .toList()
              .first
              .currentShiftId ??
          '';
    } catch (e) {
      prints('Error getting list staff by current shift id: $e');
      return '';
    }
  }
}
