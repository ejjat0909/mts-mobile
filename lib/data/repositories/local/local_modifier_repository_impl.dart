import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/services/hive_sync_helper.dart';
import 'package:mts/core/storage/hive_box_manager.dart';
import 'package:mts/data/datasources/local/database_helpers.dart';
import 'package:mts/data/repositories/local/local_modifier_option_repository_impl.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/models/modifier/modifier_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/modifier_option_repository.dart';
import 'package:mts/domain/repositories/local/modifier_repository.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';
import 'package:sqflite/sqflite.dart';

/// ================================
/// Hive Box Provider
/// ================================
final modifierBoxProvider = Provider<Box<Map>>((ref) {
  return HiveBoxManager.getValidatedBox(ModifierModel.modelBoxName);
});

/// ================================
/// Provider for Local Repository
/// ================================
final modifierLocalRepoProvider = Provider<LocalModifierRepository>((ref) {
  return LocalModifierRepositoryImpl(
    dbHelper: ref.read(databaseHelpersProvider),
    hiveBox: ref.read(modifierBoxProvider),
    localModifierOptionRepository: ref.read(modifierOptionLocalRepoProvider),
    pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
  );
});

/// ================================
/// Local Repository Implementation
/// ================================
/// Implementation of [LocalModifierRepository] that uses local database
class LocalModifierRepositoryImpl implements LocalModifierRepository {
  final IDatabaseHelpers _dbHelper;
  final Box<Map> _hiveBox;
  final LocalModifierOptionRepository _localModifierOptionRepository;
  final LocalPendingChangesRepository _pendingChangesRepository;

  /// Database table and column names
  static const String cId = 'id';
  static const String name = 'name';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String tableName = 'modifier';

  // Modifier option table constants
  static const String modifierOptionTableName = 'modifier_options';
  static const String modifierId = 'modifier_id';

  /// Constructor
  LocalModifierRepositoryImpl({
    required IDatabaseHelpers dbHelper,
    required Box<Map> hiveBox,
    required LocalModifierOptionRepository localModifierOptionRepository,
    required LocalPendingChangesRepository pendingChangesRepository,
  }) : _dbHelper = dbHelper,
       _hiveBox = hiveBox,
       _localModifierOptionRepository = localModifierOptionRepository,
       _pendingChangesRepository = pendingChangesRepository;

  /// Create the modifier table in the database
  static Future<void> createTable(Database db) async {
    String rows = '''
      $cId TEXT PRIMARY KEY,
      $name TEXT NULL,
      $createdAt TIMESTAMP DEFAULT NULL,
      $updatedAt TIMESTAMP DEFAULT NULL
    ''';
    await IDatabaseHelpers.createTable(tableName, rows, db);
  }

  /// Insert a new modifier
  @override
  Future<int> insert(
    ModifierModel modifierModel, {
    required bool isInsertToPending,
  }) async {
    modifierModel.id ??= IdUtils.generateUUID().toString();
    modifierModel.updatedAt = DateTime.now();
    modifierModel.createdAt = DateTime.now();

    // Write to SQLite database
    int result = await _dbHelper.insertDb(tableName, modifierModel.toJson());

    // Sync to Hive
    if (result > 0) {
      await _hiveBox.put(modifierModel.id!, modifierModel.toJson());
    }

    // Insert to pending changes if required
    if (isInsertToPending && result > 0) {
      final pendingChange = PendingChangesModel(
        operation: 'created',
        modelName: ModifierModel.modelName,
        modelId: modifierModel.id,
        data: jsonEncode(modifierModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    return result;
  }

  // update
  @override
  Future<int> update(
    ModifierModel modifierModel, {
    required bool isInsertToPending,
  }) async {
    modifierModel.updatedAt = DateTime.now();

    // Write to SQLite database
    int result = await _dbHelper.updateDb(tableName, modifierModel.toJson());

    // Sync to Hive
    if (result > 0) {
      await _hiveBox.put(modifierModel.id!, modifierModel.toJson());
    }

    // Insert to pending changes if required
    if (isInsertToPending && result > 0) {
      final pendingChange = PendingChangesModel(
        operation: 'updated',
        modelName: ModifierModel.modelName,
        modelId: modifierModel.id,
        data: jsonEncode(modifierModel.toJson()),
      );
      await _pendingChangesRepository.insert(pendingChange);
    }

    return result;
  }

  // delete
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
      final model = ModifierModel.fromJson(results.first);

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
          modelName: ModifierModel.modelName,
          modelId: model.id,
          data: jsonEncode(model.toJson()),
        );
        await _pendingChangesRepository.insert(pendingChange);
      }

      return result;
    } else {
      prints('No modifier record found with id: $id');
      return 0;
    }
  }

  // delete bulk
  @override
  Future<bool> deleteBulk(
    List<ModifierModel> list, {
    required bool isInsertToPending,
  }) async {
    Database db = await _dbHelper.database;
    List<String> ids = list.map((e) => e.id!).toList();
    if (ids.isEmpty) {
      return false;
    }

    // If we need to insert to pending changes, we need to get the models first
    if (isInsertToPending) {
      for (ModifierModel modifier in list) {
        List<Map<String, dynamic>> results = await db.query(
          tableName,
          where: '$cId = ?',
          whereArgs: [modifier.id],
        );

        if (results.isNotEmpty) {
          final model = ModifierModel.fromJson(results.first);

          // Insert to pending changes
          final pendingChange = PendingChangesModel(
            operation: 'deleted',
            modelName: ModifierModel.modelName,
            modelId: model.id,
            data: jsonEncode(model.toJson()),
          );
          await _pendingChangesRepository.insert(pendingChange);
        }
      }
    }

    String whereIn = ids.map((_) => '?').join(',');
    try {
      await db.delete(tableName, where: '$cId IN ($whereIn)', whereArgs: ids);

      // Delete from Hive
      await _hiveBox.deleteAll(ids);

      return true;
    } catch (e) {
      prints('Error deleting bulk modifier: $e');
      return false;
    }
  }

  // delete all
  @override
  Future<bool> deleteAll() async {
    Database db = await _dbHelper.database;
    try {
      await db.delete(tableName);

      // Clear Hive
      await _hiveBox.clear();

      return true;
    } catch (e) {
      prints('Error deleting all modifier: $e');
      return false;
    }
  }

  // getListModifierModel
  @override
  Future<List<ModifierModel>> getListModifierModel() async {
    List<ModifierModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: ModifierModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list;
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.readDb(tableName);
    return List.generate(maps.length, (index) {
      return ModifierModel.fromJson(maps[index]);
    });
  }

  // insert bulk
  @override
  Future<bool> upsertBulk(
    List<ModifierModel> list, {
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

      for (ModifierModel model in list) {
        if (model.id == null) continue;

        final isExisting = existingIds.contains(model.id);
        final modelJson = model.toJson();

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
                modelName: ModifierModel.modelName,
                modelId: model.id!,
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
                modelName: ModifierModel.modelName,
                modelId: model.id!,
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
      prints('Error inserting bulk modifier: $e');
      return false;
    }
  }

  // Get modifiers by their IDs
  @override
  Future<List<ModifierModel>> getModifiersByIds(
    List<String?> modifierIds,
  ) async {
    if (modifierIds.isEmpty) return [];

    List<ModifierModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: ModifierModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list.where((m) => modifierIds.contains(m.id)).toList();
    }

    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId IN (${modifierIds.map((_) => '?').join(',')})',
      whereArgs: modifierIds,
    );
    return List.generate(maps.length, (i) {
      return ModifierModel.fromJson(maps[i]);
    });
  }

  @override
  Future<ModifierModel> getModifierById(String idModifier) async {
    List<ModifierModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: ModifierModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list.where((element) => element.id == idModifier).first;
    }
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId = ?',
      whereArgs: [idModifier],
    );
    return ModifierModel.fromJson(maps.first);
  }

  // get modifier list from list modifier option ids
  @override
  Future<List<ModifierModel>> getModifierListFromListModifierOptionIds(
    List<String> listModifierOptionIds,
  ) async {
    if (listModifierOptionIds.isEmpty) {
      return [];
    }

    List<ModifierOptionModel> listModifierOption =
        await _localModifierOptionRepository.getModifierOptionModelFromListIds(
          listModifierOptionIds,
        );

    // extract modifier ids from modifier option ids
    List<String> listModifierIds =
        listModifierOption.map((e) => e.modifierId!).toList();

    List<ModifierModel> list = HiveSyncHelper.getListFromBox(
      box: _hiveBox,
      fromJson: ModifierModel.fromJson,
    );
    if (list.isNotEmpty) {
      return list.where((m) => listModifierIds.contains(m.id)).toList();
    }
    Database db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$cId IN (${listModifierIds.map((_) => '?').join(',')})',
      whereArgs: listModifierIds,
    );
    return List.generate(maps.length, (index) {
      return ModifierModel.fromJson(maps[index]);
    });
  }

  @override
  Future<bool> replaceAllData(
    List<ModifierModel> newData, {
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
}
