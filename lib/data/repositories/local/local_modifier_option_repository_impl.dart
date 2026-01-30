import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/domain/repositories/local/modifier_option_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mts/core/storage/hive_box_manager.dart';

final modifierOptionBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(ModifierOptionModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final modifierOptionLocalRepoProvider = Provider<LocalModifierOptionRepository>(
  (ref) {
    return LocalModifierOptionRepositoryImpl(
      dbHelper: ref.read(databaseHelpersProvider),
      pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
      hiveBox: ref.read(modifierOptionBoxProvider),
    );
  },
);

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalModifierOptionRepository] that uses local database
class LocalModifierOptionRepositoryImpl
    implements LocalModifierOptionRepository {
  final IDatabaseHelpers _dbHelper;
  final LocalPendingChangesRepository _pendingChangesRepository;
  final Box<Map> _hiveBox;

  /// Database table and column names
  static const String cId = 'id';
  static const String modifierId = 'modifier_id';
  static const String name = 'name';
  static const String price = 'price';
  static const String cost = 'cost';
  static const String orderColumn = 'order_column';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String tableName = 'modifier_options';

  /// Constructor
  LocalModifierOptionRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required Box<Map> hiveBox,
    required LocalPendingChangesRepository pendingChangesRepository,
  }) : _dbHelper = dbHelper,
       _pendingChangesRepository = pendingChangesRepository,
       _hiveBox = hiveBox;

  /// Create the modifier option table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $modifierId TEXT NULL,
      $name TEXT NULL,
      $price FLOAT NULL,
      $cost FLOAT NULL,
      $orderColumn INTEGER NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  @override
  Future<int> insert(
    ModifierOptionModel model, {
    required bool isInsertToPending,
  }) async {
    model.id ??= IdUtils.generateUUID().toString();
    model.createdAt = DateTime.now();
    model.updatedAt = DateTime.now();

    try {
      // Insert to SQLite
      int result = await _dbHelper.insertDb(tableName, model.toJson());

      // Sync to Hive
      if (result > 0) {
        await _hiveBox.put(model.id!, model.toJson());
      }

      // Insert to pending changes if required
      if (isInsertToPending && result > 0) {
        final pendingChange = PendingChangesModel(
          operation: 'created',
          modelName: ModifierOptionModel.modelName,
          modelId: model.id,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } catch (e) {
      await LogUtils.error('Error inserting modifier option', e);
      rethrow;
    }
  }

  @override
  Future<int> update(
    ModifierOptionModel modifierOptionModel, {
    required bool isInsertToPending,
  }) async {
    modifierOptionModel.updatedAt = DateTime.now();

    // Write to SQLite database
    int result = await _dbHelper.updateDb(
      tableName,
      modifierOptionModel.toJson(),
    );

    // Sync to Hive
    if (result > 0) {
      await _hiveBox.put(modifierOptionModel.id!, modifierOptionModel.toJson());
    }

    // Insert to pending changes if required
    if (isInsertToPending && result > 0) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: ModifierOptionModel.modelName,
        modelId: modifierOptionModel.id,
        data: jsonEncode(modifierOptionModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    return result;
  }

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
      final model = ModifierOptionModel.fromJson(results.first);

      // Delete the record from SQLite
      int result = await _dbHelper.deleteDb(tableName, id);

      // Delete from Hive
      if (result > 0) {
        await _hiveBox.delete(id);
      }

      // Insert to pending changes if required
      if (isInsertToPending) {
        final pendingChange = PendingChangesModel(
          operation: 'deleted',
          modelName: ModifierOptionModel.modelName,
          modelId: model.id,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No modifier option record found with id: $id');
      return 0;
    }
  }

  @override
  Future<List<ModifierOptionModel>> getListModifierOptionModel() async {
    List<ModifierOptionModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: ModifierOptionModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list;
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return ModifierOptionModel.fromJson(maps[index]);
    });
  }

  @override
  Future<bool> upsertBulk(
    List<ModifierOptionModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    try {
      // First, collect all existing IDs in a single query to check for creates vs updates
      final idsToInsert = list.map((m) => m.id).whereType<String>().toList();

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
      Batch batch = db.batch();

      for (ModifierOptionModel mom in list) {
        if (mom.id == null) continue;

        final isExisting = existingIds.contains(mom.id);
        final modelJson = mom.toJson();

        if (isExisting) {
          // Only update if new item is newer than existing one
          batch.update(
            tableName,
            modelJson,
            where: '$cId = ? AND ($updatedAt IS NULL OR $updatedAt <= ?)',
            whereArgs: [mom.id, DateTimeUtils.getDateTimeFormat(mom.updatedAt)],
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'updated',
                modelName: ModifierOptionModel.modelName,
                modelId: mom.id!,
                data: jsonEncode(modelJson),
              ),
            );
          }
        } else {
          // New item - use INSERT OR IGNORE for atomic conflict resolution
          batch.rawInsert(
            '''INSERT OR IGNORE INTO $tableName (${modelJson.keys.join(',')})
               VALUES (${List.filled(modelJson.length, '?').join(',')})''',
            modelJson.values.toList(),
          );

          if (isInsertToPending) {
            pendingChanges.add(
              PendingChangesModel(
                operation: 'created',
                modelName: ModifierOptionModel.modelName,
                modelId: mom.id!,
                data: jsonEncode(modelJson),
              ),
            );
          }
        }
      }

      // Commit batch atomically
      await batch.commit(noResult: true);

      // Sync to Hive
      final hiveDataMap = <dynamic, Map<dynamic, dynamic>>{};
      for (var model in list) {
        if (model.id != null) {
          hiveDataMap[model.id!] = model.toJson();
        }
      }
      if (hiveDataMap.isNotEmpty) {
        await _hiveBox.putAll(hiveDataMap);
      }

      // Track pending changes AFTER successful batch commit
      await Future.wait(
        pendingChanges.map(
          (pendingChange) => _pendingChangesRepository.insert(pendingChange),
        ),
      );

      return true;
    } catch (e) {
      prints('Error inserting bulk modifier option: $e');
      return false;
    }
  }

  @override
  Future<List<ModifierOptionModel>> getListModifierOptionsByModifierId(
    String idModifier,
  ) async {
    List<ModifierOptionModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: ModifierOptionModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list.where((element) => element.modifierId == idModifier).toList();
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$modifierId = ?',
      whereArgs: [idModifier],
    );

    return List.generate(maps.length, (i) {
      return ModifierOptionModel.fromJson(maps[i]);
    });
  }

  @override
  Future<List<String>> getListModifierIdsByModifierOptionIds(
    List<String> modOptIds,
  ) async {
    if (modOptIds.isEmpty) {
      return []; // Return empty list if modOptIds is empty to prevent SQL syntax errors.
    }

    List<ModifierOptionModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: ModifierOptionModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list
          .where((element) => modOptIds.contains(element.id))
          .map((e) => e.modifierId ?? '')
          .toList();
    }

    Database db = await _dbHelper.database;

    // Join the IDs, ensuring each one is surrounded by quotes to handle string IDs.
    final String ids = modOptIds.map((id) => "'$id'").join(', ');

    // Query the database
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId IN ($ids)',
    );

    // Generate and return the list of modifier IDs
    return List.generate(maps.length, (i) {
      return maps[i]['modifier_id'] as String;
    });
  }

  @override
  Future<String> getModifierOptionNameFromListIds(List<String> listIds) async {
    // Ensure the list of IDs is not empty
    if (listIds.isEmpty) {
      return ''; // Return an empty string if the list is empty
    }

    List<ModifierOptionModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: ModifierOptionModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list
          .where((element) => listIds.contains(element.id))
          .map((e) => e.name ?? '')
          .toList()
          .join(', ');
    }

    // Get database instance
    Database db = await _dbHelper.database;

    // Convert listIds to a format suitable for SQL IN clause
    String ids = listIds.map((id) => "'$id'").join(',');

    // Query the names from the table
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT name FROM $tableName WHERE $cId IN ($ids)',
    );

    // Extract the names from the result
    List<String> names = result.map((row) => row['name'] as String).toList();

    // Join the names with a comma separator
    return names.join(', ');
  }

  @override
  Future<List<ModifierOptionModel>> getModifierOptionModelFromListIds(
    List<String> listIds,
  ) async {
    if (listIds.isEmpty) {
      return [];
    }

    List<ModifierOptionModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: ModifierOptionModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list.where((element) => listIds.contains(element.id)).toList();
    }

    Database db = await _dbHelper.database;
    final String ids = listIds.map((id) => "'$id'").join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId IN ($ids)',
    );
    if (maps.isEmpty) {
      return [];
    } else {
      return List.generate(maps.length, (i) {
        return ModifierOptionModel.fromJson(maps[i]);
      });
    }
  }

  @override
  Future<bool> deleteBulk(
    List<ModifierOptionModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    Batch batch = db.batch();

    try {
      for (ModifierOptionModel modifierOption in list) {
        // If we need to insert to pending changes, we need to get the model first
        if (isInsertToPending) {
          List<Map<String, dynamic>> results = await db.query(
            tableName,
            where: '$cId = ?',
            whereArgs: [modifierOption.id],
          );

          if (results.isNotEmpty) {
            final model = ModifierOptionModel.fromJson(results.first);

            // Insert to pending changes
            final pendingChange = PendingChangesModel(
              operation: 'deleted',
              modelName: ModifierOptionModel.modelName,
              modelId: model.id,
              data: jsonEncode(model.toJson()),
            );
            await _pendingChangesRepository.insert(pendingChange);
          }
        }

        batch.delete(
          tableName,
          where: '$cId = ?',
          whereArgs: [modifierOption.id],
        );
      }
      await batch.commit(noResult: true);

      // Delete from Hive
      final ids = list.map((e) => e.id!).toList();
      await _hiveBox.deleteAll(ids);

      return true;
    } catch (e) {
      prints('Error deleting bulk modifier options: $e');
      return false;
    }
  }

  @override
  Future<bool> replaceAllData(
    List<ModifierOptionModel> newData, {
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

  /// Delete all modifier options from Hive box and SQLite
  @override
  Future<bool> deleteAll() async {
    try {
      Database db = await _dbHelper.database;
      await db.delete(tableName);
      await _hiveBox.clear();
      return true;
    } catch (e) {
      await LogUtils.error('Error deleting all modifier options', e);
      return false;
    }
  }
}
