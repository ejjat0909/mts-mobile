import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/constants/pending_change_operation.dart';
import 'package:mts/core/services/crud_config.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/pivot_element.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';

/// Service for handling common CRUD operations across repositories
/// Eliminates code duplication for insert, update, delete, upsert operations
/// Now uses dependency injection with abstractions for better testing
/// FIXED: Hive operations moved outside transactions for proper atomicity
/// FIXED: Race conditions eliminated with atomic operations
class RepositoryCrudService {
  /// Standard chunk size for bulk operations (500 records per chunk)
  static const int defaultChunkSize = 500;

  // ==================== SINGLE RECORD OPERATIONS (REGULAR TABLES) ====================

  /// Insert a single record into regular table
  /// FIXED: Cache update moved outside transaction for proper atomicity
  Future<int> insert<T>(CrudConfig<T> config, T model) async {
    assert(config.tableName.isNotEmpty, 'tableName cannot be empty');
    assert(config.modelName.isNotEmpty, 'modelName cannot be empty');

    // Generate ID if null using proper UUID
    var id = config.getId(model);
    if (id == null) {
      id = IdUtils.generateUUID();
      config.setId(model, id);
    }

    // Set timestamps
    config.setTimestamps(model);

    final modelJson = config.toJson(model);

    // Use transaction for SQL atomicity only
    final result = await config.db.transaction((txn) async {
      try {
        // Insert to SQLite
        return await txn.insert(
          config.tableName,
          modelJson,
          conflictAlgorithm: 'replace',
        );
      } catch (e) {
        await LogUtils.error('Error inserting ${config.modelName}', e);
        rethrow;
      }
    });

    // FIXED: Update cache AFTER successful transaction (not inside)
    // Cache failure won't rollback the database insert
    if (config.cache != null) {
      try {
        await config.cache!.put(id, modelJson);
      } catch (e) {
        await LogUtils.error(
          'Cache update failed for ${config.modelName}, continuing',
          e,
        );
      }
    }

    // Track pending changes
    if (config.trackPendingChanges && config.pendingChangesTracker != null) {
      try {
        await config.pendingChangesTracker!.track(
          PendingChangesModel(
            operation: PendingChangeOperation.created,
            modelName: config.modelName,
            modelId: id,
            data: jsonEncode(modelJson),
          ),
        );
      } catch (e) {
        await LogUtils.error(
          'Failed to track pending changes for ${config.modelName}',
          e,
        );
      }
    }

    return result;
  }

  /// Update a single record in regular table
  /// FIXED: Cache update moved outside transaction
  Future<int> update<T>(CrudConfig<T> config, T model) async {
    assert(config.tableName.isNotEmpty, 'tableName cannot be empty');
    assert(config.modelName.isNotEmpty, 'modelName cannot be empty');
    assert(config.idColumn.isNotEmpty, 'idColumn cannot be empty');

    final id = config.getId(model);
    if (id == null) {
      throw Exception('Cannot update ${config.modelName}: ID is null');
    }

    // Update timestamp
    config.updateTimestamp(model);

    final modelJson = config.toJson(model);

    // Use transaction for SQL atomicity only
    final result = await config.db.transaction((txn) async {
      try {
        // Update SQLite
        return await txn.update(
          config.tableName,
          modelJson,
          where: '${config.idColumn} = ?',
          whereArgs: [id],
        );
      } catch (e) {
        await LogUtils.error('Error updating ${config.modelName}', e);
        rethrow;
      }
    });

    // FIXED: Update cache AFTER successful transaction
    if (config.cache != null) {
      try {
        await config.cache!.put(id, modelJson);
      } catch (e) {
        await LogUtils.error('Cache update failed for ${config.modelName}', e);
      }
    }

    // Track pending changes
    if (config.trackPendingChanges && config.pendingChangesTracker != null) {
      try {
        await config.pendingChangesTracker!.track(
          PendingChangesModel(
            operation: PendingChangeOperation.updated,
            modelName: config.modelName,
            modelId: id,
            data: jsonEncode(modelJson),
          ),
        );
      } catch (e) {
        await LogUtils.error(
          'Failed to track pending changes for ${config.modelName}',
          e,
        );
      }
    }

    return result;
  }

  /// Upsert (insert or update) a single record in regular table
  /// Checks if record exists and validates timestamp before updating
  /// Only updates if incoming data is newer (prevents race conditions)
  /// FIXED: Cache update moved outside transaction
  Future<int> upsert<T>(CrudConfig<T> config, T model) async {
    assert(config.tableName.isNotEmpty, 'tableName cannot be empty');
    assert(config.modelName.isNotEmpty, 'modelName cannot be empty');
    assert(config.idColumn.isNotEmpty, 'idColumn cannot be empty');

    var id = config.getId(model);

    // Generate ID if null using proper UUID
    if (id == null) {
      id = IdUtils.generateUUID();
      config.setId(model, id);
    }

    final hasTimestamp = config.updatedAtColumn != null;
    String? operation;
    bool shouldUpdate = true;
    Map<String, dynamic>? modelJson;

    final result = await config.db.transaction((txn) async {
      try {
        // Check if record exists (and get timestamp if available)
        final queryColumns =
            hasTimestamp
                ? [config.idColumn, config.updatedAtColumn!]
                : [config.idColumn];

        final existingRecords = await txn.query(
          config.tableName,
          where: '${config.idColumn} = ?',
          whereArgs: [id],
          columns: queryColumns,
        );

        int result;

        if (existingRecords.isNotEmpty) {
          // Record exists - validate timestamp before updating (if available)
          operation = PendingChangeOperation.updated;

          // Update timestamp only if table has timestamp column
          if (hasTimestamp) {
            config.updateTimestamp(model);
          }

          modelJson = config.toJson(model);

          if (hasTimestamp) {
            // Validate timestamp to prevent overwriting newer data
            final existingRecord = existingRecords.first;
            final existingUpdatedAtStr =
                existingRecord[config.updatedAtColumn!] as String?;
            final existingUpdatedAt =
                existingUpdatedAtStr != null
                    ? DateTime.tryParse(existingUpdatedAtStr)
                    : null;

            final incomingUpdatedAt = DateTime.tryParse(
              modelJson![config.updatedAtColumn!] as String,
            );

            // IMPORTANT: Only update if incoming data is newer than existing data.
            // This prevents race conditions where older sync data overwrites newer local changes.
            shouldUpdate =
                existingUpdatedAt == null ||
                (incomingUpdatedAt != null &&
                    incomingUpdatedAt.isAfter(existingUpdatedAt));
          } else {
            // No timestamp column - always update
            shouldUpdate = true;
          }

          if (shouldUpdate) {
            result = await txn.update(
              config.tableName,
              modelJson!,
              where: '${config.idColumn} = ?',
              whereArgs: [id],
            );
          } else {
            // Skip update - existing data is newer
            result = 0;
          }
        } else {
          // Insert new record
          operation = PendingChangeOperation.created;

          // Set timestamps only if table has timestamp columns
          if (hasTimestamp) {
            config.setTimestamps(model);
          }

          modelJson = config.toJson(model);
          result = await txn.insert(
            config.tableName,
            modelJson!,
            conflictAlgorithm: 'replace',
          );
        }

        return result;
      } catch (e) {
        await LogUtils.error('Error upserting ${config.modelName}', e);
        rethrow;
      }
    });

    // FIXED: Update cache AFTER successful transaction (only if record changed)
    if (shouldUpdate && modelJson != null && config.cache != null) {
      try {
        await config.cache!.put(id, modelJson!);
      } catch (e) {
        await LogUtils.error('Cache update failed for ${config.modelName}', e);
      }
    }

    // Track pending changes only if record actually changed
    if (shouldUpdate &&
        operation != null &&
        config.trackPendingChanges &&
        config.pendingChangesTracker != null) {
      try {
        await config.pendingChangesTracker!.track(
          PendingChangesModel(
            operation: operation,
            modelName: config.modelName,
            modelId: id,
            data: jsonEncode(config.toJson(model)),
          ),
        );
      } catch (e) {
        await LogUtils.error(
          'Failed to track pending changes for ${config.modelName}',
          e,
        );
      }
    }

    return result;
  }

  /// Delete a single record from regular table
  /// Fetches model from cache or database for pending changes tracking
  /// FIXED: Cache delete moved outside transaction
  Future<int> delete<T>(CrudConfig<T> config, String id) async {
    assert(config.tableName.isNotEmpty, 'tableName cannot be empty');
    assert(config.modelName.isNotEmpty, 'modelName cannot be empty');
    assert(config.idColumn.isNotEmpty, 'idColumn cannot be empty');
    assert(id.isNotEmpty, 'id cannot be empty');

    T? modelToDelete;

    // Get model for pending changes tracking BEFORE delete
    if (config.trackPendingChanges && config.pendingChangesTracker != null) {
      // Try cache first
      if (config.cache != null) {
        final cachedJson = config.cache!.get(id);
        if (cachedJson != null) {
          modelToDelete = config.fromJson(cachedJson);
        }
      }

      // Fallback to database
      if (modelToDelete == null) {
        final results = await config.db.query(
          config.tableName,
          where: '${config.idColumn} = ?',
          whereArgs: [id],
        );
        if (results.isNotEmpty) {
          modelToDelete = config.fromJson(results.first);
        }
      }
    }

    // Delete from database in transaction
    final result = await config.db.transaction((txn) async {
      try {
        return await txn.delete(
          config.tableName,
          where: '${config.idColumn} = ?',
          whereArgs: [id],
        );
      } catch (e) {
        await LogUtils.error('Error deleting ${config.modelName}', e);
        rethrow;
      }
    });

    // FIXED: Delete from cache AFTER successful transaction
    if (config.cache != null) {
      try {
        await config.cache!.delete(id);
      } catch (e) {
        await LogUtils.error('Cache delete failed for ${config.modelName}', e);
      }
    }

    // Track pending changes
    if (config.trackPendingChanges &&
        config.pendingChangesTracker != null &&
        modelToDelete != null) {
      try {
        await config.pendingChangesTracker!.track(
          PendingChangesModel(
            operation: PendingChangeOperation.deleted,
            modelName: config.modelName,
            modelId: id,
            data: jsonEncode(config.toJson(modelToDelete)),
          ),
        );
      } catch (e) {
        await LogUtils.error(
          'Failed to track pending changes for ${config.modelName}',
          e,
        );
      }
    }

    return result;
  }

  /// Upsert multiple records in bulk (regular table)
  /// Currently loops through individual upserts for timestamp validation
  /// Future optimization: batch operations with timestamp comparison
  Future<bool> upsertBulk<T>(CrudConfig<T> config, List<T> models) async {
    assert(config.tableName.isNotEmpty, 'tableName cannot be empty');
    assert(config.modelName.isNotEmpty, 'modelName cannot be empty');

    if (models.isEmpty) return true;

    try {
      for (var model in models) {
        await upsert(config, model);
      }
      return true;
    } catch (e) {
      await LogUtils.error('Error in bulk upsert for ${config.modelName}', e);
      return false;
    }
  }

  /// Delete multiple records in bulk from regular table
  /// FIXED: Cache operations moved outside transaction
  Future<bool> deleteBulk<T>(CrudConfig<T> config, List<T> models) async {
    assert(config.tableName.isNotEmpty, 'tableName cannot be empty');
    assert(config.modelName.isNotEmpty, 'modelName cannot be empty');

    if (models.isEmpty) return true;

    try {
      final idsToDelete = <String>[];
      final pendingChanges = <PendingChangesModel>[];

      // Collect IDs and prepare pending changes
      for (var model in models) {
        final id = config.getId(model);
        if (id != null) {
          idsToDelete.add(id);

          if (config.trackPendingChanges) {
            pendingChanges.add(
              PendingChangesModel(
                operation: PendingChangeOperation.deleted,
                modelName: config.modelName,
                modelId: id,
                data: jsonEncode(config.toJson(model)),
              ),
            );
          }
        }
      }

      // Delete from database in transaction
      await config.db.transaction((txn) async {
        final batch = txn.batch();

        for (var id in idsToDelete) {
          batch.delete(
            config.tableName,
            where: '${config.idColumn} = ?',
            whereArgs: [id],
          );
        }

        await batch.commit(noResult: true);
      });

      // FIXED: Delete from cache AFTER successful transaction
      if (config.cache != null) {
        try {
          for (var id in idsToDelete) {
            await config.cache!.delete(id);
          }
        } catch (e) {
          await LogUtils.error(
            'Cache bulk delete failed for ${config.modelName}',
            e,
          );
        }
      }

      // Track pending changes
      if (config.trackPendingChanges && config.pendingChangesTracker != null) {
        try {
          await config.pendingChangesTracker!.trackBatch(pendingChanges);
        } catch (e) {
          await LogUtils.error(
            'Failed to track bulk pending changes for ${config.modelName}',
            e,
          );
        }
      }

      return true;
    } catch (e) {
      await LogUtils.error('Error deleting bulk ${config.modelName}', e);
      rethrow;
    }
  }

  /// Delete all records from table
  /// FIXED: Cache clear moved outside transaction
  Future<bool> deleteAll<T>(CrudConfig<T> config) async {
    assert(config.tableName.isNotEmpty, 'tableName cannot be empty');

    try {
      // Delete from database
      await config.db.delete(config.tableName);

      // FIXED: Clear cache AFTER successful database operation
      if (config.cache != null) {
        try {
          await config.cache!.clear();
        } catch (e) {
          await LogUtils.error('Cache clear failed for ${config.modelName}', e);
        }
      }

      return true;
    } catch (e) {
      await LogUtils.error('Error deleting all from ${config.tableName}', e);
      rethrow;
    }
  }

  /// Get a single record by ID from cache or database with cache population
  Future<T?> getById<T>(CrudConfig<T> config, String id) async {
    assert(config.tableName.isNotEmpty, 'tableName cannot be empty');
    assert(config.idColumn.isNotEmpty, 'idColumn cannot be empty');
    assert(id.isNotEmpty, 'id cannot be empty');

    // Try cache first
    if (config.cache != null) {
      final cachedJson = config.cache!.get(id);
      if (cachedJson != null) {
        return config.fromJson(cachedJson);
      }
    }

    // Fallback to database and populate cache
    final results = await config.db.query(
      config.tableName,
      where: '${config.idColumn} = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      final model = config.fromJson(results.first);
      // Populate cache
      if (config.cache != null) {
        try {
          await config.cache!.put(id, results.first);
        } catch (e) {
          await LogUtils.error('Failed to populate cache', e);
        }
      }
      return model;
    }

    return null;
  }

  /// Get all records from regular table (cache-first, fallback to database)
  /// Returns list from cache if available, otherwise queries database and populates cache
  Future<List<T>> getList<T>(CrudConfig<T> config) async {
    assert(config.tableName.isNotEmpty, 'tableName cannot be empty');

    // Try cache first
    if (config.cache != null && config.cache!.length > 0) {
      final cacheData = config.cache!.getAll();
      if (cacheData.isNotEmpty) {
        return cacheData.values.map((json) => config.fromJson(json)).toList();
      }
    }

    // Fallback to database and populate cache for future reads
    final maps = await config.db.query(config.tableName);
    final models = maps.map((json) => config.fromJson(json)).toList();

    // Populate cache to avoid future database queries
    if (config.cache != null && models.isNotEmpty) {
      try {
        final cacheMap = <String, Map<String, dynamic>>{};
        for (var model in models) {
          final id = config.getId(model);
          if (id != null) {
            cacheMap[id] = config.toJson(model);
          }
        }
        await config.cache!.putAll(cacheMap);
      } catch (e) {
        await LogUtils.error(
          'Failed to populate cache for ${config.modelName}',
          e,
        );
      }
    }

    return models;
  }

  // ==================== PIVOT TABLE OPERATIONS ====================

  /// Upsert a single pivot record
  /// FIXED: Cache update moved outside transaction
  /// FIXED: Handles tables without updated_at column gracefully
  Future<int> upsertPivot<T>(PivotCrudConfig<T> config, T model) async {
    assert(config.tableName.isNotEmpty, 'tableName cannot be empty');
    assert(config.modelName.isNotEmpty, 'modelName cannot be empty');

    final compositeKey = config.getCompositeKey(model);
    final keyColumns = config.getKeyColumns(model);
    final hasTimestamp = config.updatedAtColumn != null;

    String? operation;
    bool shouldUpdate = true;
    Map<String, dynamic>? modelJson;

    final result = await config.db.transaction((txn) async {
      try {
        final whereClause = keyColumns.keys.map((k) => '$k = ?').join(' AND ');
        final whereArgs = keyColumns.values.toList();

        // Check if record exists (and get timestamp if available)
        final queryColumns =
            hasTimestamp
                ? [config.updatedAtColumn!, ...keyColumns.keys]
                : [...keyColumns.keys];

        final existingRecords = await txn.query(
          config.tableName,
          where: whereClause,
          whereArgs: whereArgs,
          columns: queryColumns,
        );

        int result;

        if (existingRecords.isNotEmpty) {
          // Record exists - validate timestamp before updating (if available)
          operation = PendingChangeOperation.updated;

          // Set timestamps only if table has timestamp columns
          if (hasTimestamp) {
            config.setTimestamps(model);
          }
          modelJson = config.toJson(model);

          if (hasTimestamp) {
            // Validate timestamp to prevent overwriting newer data
            final existingRecord = existingRecords.first;
            final existingUpdatedAtStr =
                existingRecord[config.updatedAtColumn!] as String?;
            final existingUpdatedAt =
                existingUpdatedAtStr != null
                    ? DateTime.tryParse(existingUpdatedAtStr)
                    : null;

            final incomingUpdatedAt = DateTime.tryParse(
              modelJson![config.updatedAtColumn!] as String,
            );

            // IMPORTANT: Only update if incoming data is newer than existing data
            shouldUpdate =
                existingUpdatedAt == null ||
                (incomingUpdatedAt != null &&
                    incomingUpdatedAt.isAfter(existingUpdatedAt));
          } else {
            // No timestamp column - always update
            shouldUpdate = true;
          }

          if (shouldUpdate) {
            result = await txn.update(
              config.tableName,
              modelJson!,
              where: whereClause,
              whereArgs: whereArgs,
            );
          } else {
            // Skip update - existing data is newer
            result = 0;
          }
        } else {
          // Insert new record
          operation = PendingChangeOperation.created;

          // Set timestamps only if table has timestamp columns
          if (hasTimestamp) {
            config.setTimestamps(model);
          }

          modelJson = config.toJson(model);
          result = await txn.insert(
            config.tableName,
            modelJson!,
            conflictAlgorithm: 'replace',
          );
        }

        return result;
      } catch (e) {
        await LogUtils.error('Error upserting pivot ${config.modelName}', e);
        rethrow;
      }
    });

    // FIXED: Update cache AFTER successful transaction (only if record changed)
    if (shouldUpdate && modelJson != null && config.cache != null) {
      try {
        await config.cache!.put(compositeKey, modelJson!);
      } catch (e) {
        await LogUtils.error(
          'Cache update failed for pivot ${config.modelName}',
          e,
        );
      }
    }

    // Track pending changes only if record actually changed
    if (shouldUpdate &&
        operation != null &&
        config.trackPendingChanges &&
        config.pendingChangesTracker != null) {
      try {
        await config.pendingChangesTracker!.track(
          PendingChangesModel(
            operation: operation,
            modelName: config.modelName,
            modelId: compositeKey,
            data: jsonEncode(modelJson!),
          ),
        );
      } catch (e) {
        await LogUtils.error(
          'Failed to track pending changes for pivot ${config.modelName}',
          e,
        );
      }
    }

    return result;
  }

  /// Upsert multiple pivot records in bulk
  /// Currently loops through individual upserts for timestamp validation
  /// Future optimization: batch operations with timestamp comparison
  Future<bool> upsertBulkPivot<T>(
    PivotCrudConfig<T> config,
    List<T> models,
  ) async {
    assert(config.tableName.isNotEmpty, 'tableName cannot be empty');
    assert(config.modelName.isNotEmpty, 'modelName cannot be empty');

    if (models.isEmpty) return true;

    try {
      for (var model in models) {
        await upsertPivot(config, model);
      }
      return true;
    } catch (e) {
      await LogUtils.error(
        'Error in bulk upsert for pivot ${config.modelName}',
        e,
      );
      return false;
    }
  }

  /// Delete a single pivot record
  /// FIXED: Cache delete moved outside transaction
  Future<int> deletePivot<T>(
    PivotCrudConfig<T> config,
    String compositeKey,
    Map<String, dynamic> keyColumns,
  ) async {
    assert(config.tableName.isNotEmpty, 'tableName cannot be empty');
    assert(config.modelName.isNotEmpty, 'modelName cannot be empty');
    assert(compositeKey.isNotEmpty, 'compositeKey cannot be empty');

    T? modelToDelete;

    // Get model for pending changes tracking BEFORE delete
    if (config.trackPendingChanges && config.pendingChangesTracker != null) {
      // Try cache first
      if (config.cache != null) {
        final cachedJson = config.cache!.get(compositeKey);
        if (cachedJson != null) {
          modelToDelete = config.fromJson(cachedJson);
        }
      }

      // Fallback to database
      if (modelToDelete == null) {
        final whereClause = keyColumns.keys.map((k) => '$k = ?').join(' AND ');
        final whereArgs = keyColumns.values.toList();

        final results = await config.db.query(
          config.tableName,
          where: whereClause,
          whereArgs: whereArgs,
        );
        if (results.isNotEmpty) {
          modelToDelete = config.fromJson(results.first);
        }
      }
    }

    // Delete from database in transaction
    final result = await config.db.transaction((txn) async {
      try {
        final whereClause = keyColumns.keys.map((k) => '$k = ?').join(' AND ');
        final whereArgs = keyColumns.values.toList();

        return await txn.delete(
          config.tableName,
          where: whereClause,
          whereArgs: whereArgs,
        );
      } catch (e) {
        await LogUtils.error('Error deleting pivot ${config.modelName}', e);
        rethrow;
      }
    });

    // FIXED: Delete from cache AFTER successful transaction
    if (config.cache != null) {
      try {
        await config.cache!.delete(compositeKey);
      } catch (e) {
        await LogUtils.error(
          'Cache delete failed for pivot ${config.modelName}',
          e,
        );
      }
    }

    // Track pending changes
    if (config.trackPendingChanges &&
        config.pendingChangesTracker != null &&
        modelToDelete != null) {
      try {
        await config.pendingChangesTracker!.track(
          PendingChangesModel(
            operation: PendingChangeOperation.deleted,
            modelName: config.modelName,
            modelId: compositeKey,
            data: jsonEncode(config.toJson(modelToDelete)),
          ),
        );
      } catch (e) {
        await LogUtils.error(
          'Failed to track pending changes for pivot ${config.modelName}',
          e,
        );
      }
    }

    return result;
  }

  /// Delete multiple pivot records in bulk
  /// FIXED: Cache operations moved outside transaction
  Future<bool> deleteBulkPivot<T>(
    PivotCrudConfig<T> config,
    List<T> models,
  ) async {
    assert(config.tableName.isNotEmpty, 'tableName cannot be empty');
    assert(config.modelName.isNotEmpty, 'modelName cannot be empty');

    if (models.isEmpty) return true;

    try {
      final keysToDelete = <String>[];
      final pendingChanges = <PendingChangesModel>[];

      // Collect keys and prepare pending changes
      for (var model in models) {
        final compositeKey = config.getCompositeKey(model);
        if (compositeKey.isEmpty) continue;

        keysToDelete.add(compositeKey);

        if (config.trackPendingChanges) {
          pendingChanges.add(
            PendingChangesModel(
              operation: PendingChangeOperation.deleted,
              modelName: config.modelName,
              modelId: compositeKey,
              data: jsonEncode(config.toJson(model)),
            ),
          );
        }
      }

      // Delete from database in transaction
      await config.db.transaction((txn) async {
        final batch = txn.batch();

        for (var model in models) {
          final compositeKey = config.getCompositeKey(model);
          if (compositeKey.isEmpty) continue;

          final keyColumns = config.getKeyColumns(model);
          final whereClause = keyColumns.keys
              .map((k) => '$k = ?')
              .join(' AND ');
          final whereArgs = keyColumns.values.toList();

          batch.delete(
            config.tableName,
            where: whereClause,
            whereArgs: whereArgs,
          );
        }

        await batch.commit(noResult: true);
      });

      // FIXED: Delete from cache AFTER successful transaction
      if (config.cache != null) {
        try {
          for (var key in keysToDelete) {
            await config.cache!.delete(key);
          }
        } catch (e) {
          await LogUtils.error(
            'Cache bulk delete failed for pivot ${config.modelName}',
            e,
          );
        }
      }

      // Track pending changes
      if (config.trackPendingChanges && config.pendingChangesTracker != null) {
        try {
          await config.pendingChangesTracker!.trackBatch(pendingChanges);
        } catch (e) {
          await LogUtils.error(
            'Failed to track bulk pending changes for pivot ${config.modelName}',
            e,
          );
        }
      }

      return true;
    } catch (e) {
      await LogUtils.error('Error deleting bulk pivot ${config.modelName}', e);
      rethrow;
    }
  }

  /// Delete records by column name from pivot table
  /// FIXED: Cache operations moved outside transaction
  /// FIXED: Race condition - fetch records for tracking only if needed
  Future<int> deleteByColumnName<T>(
    PivotCrudConfig<T> config,
    String columnName,
    dynamic value,
  ) async {
    assert(config.tableName.isNotEmpty, 'tableName cannot be empty');
    assert(columnName.isNotEmpty, 'columnName cannot be empty');
    assert(config.modelName.isNotEmpty, 'modelName cannot be empty');

    try {
      final modelsToDelete = <T>[];
      final keysToDelete = <String>[];

      // Fetch records BEFORE delete only if we need them for tracking
      if (config.trackPendingChanges && config.pendingChangesTracker != null) {
        final results = await config.db.query(
          config.tableName,
          where: '$columnName = ?',
          whereArgs: [value],
        );

        for (final record in results) {
          final model = config.fromJson(record);
          modelsToDelete.add(model);
          keysToDelete.add(config.getCompositeKey(model));
        }
      }

      // Atomic delete from database
      final deleteCount = await config.db.transaction((txn) async {
        return await txn.delete(
          config.tableName,
          where: '$columnName = ?',
          whereArgs: [value],
        );
      });

      if (deleteCount == 0) {
        return 0;
      }

      // FIXED: Delete from cache AFTER successful transaction
      if (config.cache != null && keysToDelete.isNotEmpty) {
        try {
          for (var key in keysToDelete) {
            await config.cache!.delete(key);
          }
        } catch (e) {
          await LogUtils.error(
            'Cache delete failed for pivot ${config.modelName}',
            e,
          );
        }
      }

      // Track pending changes
      if (config.trackPendingChanges &&
          config.pendingChangesTracker != null &&
          modelsToDelete.isNotEmpty) {
        try {
          final pendingChanges =
              modelsToDelete.map((model) {
                return PendingChangesModel(
                  operation: PendingChangeOperation.deleted,
                  modelName: config.modelName,
                  modelId: config.getCompositeKey(model),
                  data: jsonEncode(config.toJson(model)),
                );
              }).toList();

          await config.pendingChangesTracker!.trackBatch(pendingChanges);
        } catch (e) {
          await LogUtils.error(
            'Failed to track pending changes for pivot ${config.modelName}',
            e,
          );
        }
      }

      return deleteCount;
    } catch (e) {
      await LogUtils.error('Error deleting by column $columnName', e);
      rethrow;
    }
  }

  /// Get a single record by composite key from pivot table
  Future<T?> getByIdPivot<T>(
    PivotCrudConfig<T> config,
    String compositeKey,
    List<PivotElement> pivotElements,
  ) async {
    assert(config.tableName.isNotEmpty, 'tableName cannot be empty');
    assert(compositeKey.isNotEmpty, 'compositeKey cannot be empty');

    // Try cache first
    if (config.cache != null) {
      final cachedJson = config.cache!.get(compositeKey);
      if (cachedJson != null) {
        return config.fromJson(cachedJson);
      }
    }

    // Build WHERE clause for composite key query
    final whereClause = pivotElements
        .map((e) => '${e.columnName} = ?')
        .join(' AND ');
    final whereArgs = pivotElements.map((e) => e.value).toList();

    // Fallback to database and populate cache
    final results = await config.db.query(
      config.tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );

    if (results.isNotEmpty) {
      final model = config.fromJson(results.first);
      // Populate cache
      if (config.cache != null) {
        try {
          await config.cache!.put(compositeKey, results.first);
        } catch (e) {
          await LogUtils.error('Failed to populate cache', e);
        }
      }
      return model;
    }

    return null;
  }

  /// Get all records from pivot table (cache-first, fallback to database)
  Future<List<T>> getListPivot<T>(PivotCrudConfig<T> config) async {
    assert(config.tableName.isNotEmpty, 'tableName cannot be empty');

    // Try cache first
    if (config.cache != null && config.cache!.length > 0) {
      final cacheData = config.cache!.getAll();
      if (cacheData.isNotEmpty) {
        return cacheData.values.map((json) => config.fromJson(json)).toList();
      }
    }

    // Fallback to database and populate cache for future reads
    final maps = await config.db.query(config.tableName);
    final models = maps.map((json) => config.fromJson(json)).toList();

    // Populate cache to avoid future database queries
    if (config.cache != null && models.isNotEmpty) {
      try {
        final cacheMap = <String, Map<String, dynamic>>{};
        for (var model in models) {
          final compositeKey = config.getCompositeKey(model);
          if (compositeKey.isNotEmpty) {
            cacheMap[compositeKey] = config.toJson(model);
          }
        }
        await config.cache!.putAll(cacheMap);
      } catch (e) {
        await LogUtils.error(
          'Failed to populate cache for pivot ${config.modelName}',
          e,
        );
      }
    }

    return models;
  }
}

// ==================== RIVERPOD PROVIDER ====================

/// Provider for RepositoryCrudService
/// Inject this into repositories for testable, mockable CRUD operations
final repositoryCrudServiceProvider = Provider<RepositoryCrudService>((ref) {
  return RepositoryCrudService();
});
