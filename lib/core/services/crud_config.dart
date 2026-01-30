import 'package:mts/core/interfaces/i_cache_store.dart';
import 'package:mts/core/interfaces/i_database_adapter.dart';
import 'package:mts/core/interfaces/i_pending_changes_tracker.dart';

/// Configuration for CRUD operations on regular (non-pivot) tables
/// Reduces method parameters from 10-13 to a single config object
class CrudConfig<T> {
  /// Database adapter for SQL operations
  final IDatabaseAdapter db;

  /// Cache store for Hive/cache operations
  final ICacheStore? cache;

  /// Pending changes tracker for sync operations
  final IPendingChangesTracker? pendingChangesTracker;

  /// Table name in the database
  final String tableName;

  /// Model name for logging and tracking
  final String modelName;

  /// Primary key column name (default: 'id')
  final String idColumn;

  /// Updated timestamp column name (optional, default: 'updated_at')
  /// If null, timestamp validation will be skipped for upsert operations
  final String? updatedAtColumn;

  /// Whether to track pending changes for sync
  final bool trackPendingChanges;

  /// Function to extract ID from model
  final String? Function(T) getId;

  /// Function to set ID on model
  final void Function(T, String) setId;

  /// Function to convert model to JSON
  final Map<String, dynamic> Function(T) toJson;

  /// Function to create model from JSON
  final T Function(Map<String, dynamic>) fromJson;

  /// Function to set created_at and updated_at timestamps
  final void Function(T) setTimestamps;

  /// Function to update only the updated_at timestamp
  final void Function(T) updateTimestamp;

  CrudConfig({
    required this.db,
    this.cache,
    this.pendingChangesTracker,
    required this.tableName,
    required this.modelName,
    this.idColumn = 'id',
    this.updatedAtColumn = 'updated_at',
    this.trackPendingChanges = true,
    required this.getId,
    required this.setId,
    required this.toJson,
    required this.fromJson,
    required this.setTimestamps,
    required this.updateTimestamp,
  });

  /// Create a copy with optional parameter overrides
  CrudConfig<T> copyWith({
    IDatabaseAdapter? db,
    ICacheStore? cache,
    IPendingChangesTracker? pendingChangesTracker,
    String? tableName,
    String? modelName,
    String? idColumn,
    String? updatedAtColumn,
    bool? trackPendingChanges,
    String? Function(T)? getId,
    void Function(T, String)? setId,
    Map<String, dynamic> Function(T)? toJson,
    T Function(Map<String, dynamic>)? fromJson,
    void Function(T)? setTimestamps,
    void Function(T)? updateTimestamp,
  }) {
    return CrudConfig<T>(
      db: db ?? this.db,
      cache: cache ?? this.cache,
      pendingChangesTracker:
          pendingChangesTracker ?? this.pendingChangesTracker,
      tableName: tableName ?? this.tableName,
      modelName: modelName ?? this.modelName,
      idColumn: idColumn ?? this.idColumn,
      updatedAtColumn: updatedAtColumn ?? this.updatedAtColumn,
      trackPendingChanges: trackPendingChanges ?? this.trackPendingChanges,
      getId: getId ?? this.getId,
      setId: setId ?? this.setId,
      toJson: toJson ?? this.toJson,
      fromJson: fromJson ?? this.fromJson,
      setTimestamps: setTimestamps ?? this.setTimestamps,
      updateTimestamp: updateTimestamp ?? this.updateTimestamp,
    );
  }
}

/// Configuration for CRUD operations on pivot tables with composite keys
class PivotCrudConfig<T> {
  /// Database adapter for SQL operations
  final IDatabaseAdapter db;

  /// Cache store for Hive/cache operations
  final ICacheStore? cache;

  /// Pending changes tracker for sync operations
  final IPendingChangesTracker? pendingChangesTracker;

  /// Table name in the database
  final String tableName;

  /// Model name for logging and tracking
  final String modelName;

  /// Updated timestamp column name (optional, default: 'updated_at')
  /// If null, timestamp validation will be skipped for upsert operations
  final String? updatedAtColumn;

  /// Whether to track pending changes for sync
  final bool trackPendingChanges;

  /// Function to generate composite key from model
  final String Function(T) getCompositeKey;

  /// Function to extract key columns for WHERE clause
  final Map<String, dynamic> Function(T) getKeyColumns;

  /// Function to convert model to JSON
  final Map<String, dynamic> Function(T) toJson;

  /// Function to create model from JSON
  final T Function(Map<String, dynamic>) fromJson;

  /// Function to set created_at and updated_at timestamps
  final void Function(T) setTimestamps;

  PivotCrudConfig({
    required this.db,
    this.cache,
    this.pendingChangesTracker,
    required this.tableName,
    required this.modelName,
    this.updatedAtColumn = 'updated_at',
    this.trackPendingChanges = true,
    required this.getCompositeKey,
    required this.getKeyColumns,
    required this.toJson,
    required this.fromJson,
    required this.setTimestamps,
  });

  /// Create a copy with optional parameter overrides
  PivotCrudConfig<T> copyWith({
    IDatabaseAdapter? db,
    ICacheStore? cache,
    IPendingChangesTracker? pendingChangesTracker,
    String? tableName,
    String? modelName,
    String? updatedAtColumn,
    bool? trackPendingChanges,
    String Function(T)? getCompositeKey,
    Map<String, dynamic> Function(T)? getKeyColumns,
    Map<String, dynamic> Function(T)? toJson,
    T Function(Map<String, dynamic>)? fromJson,
    void Function(T)? setTimestamps,
  }) {
    return PivotCrudConfig<T>(
      db: db ?? this.db,
      cache: cache ?? this.cache,
      pendingChangesTracker:
          pendingChangesTracker ?? this.pendingChangesTracker,
      tableName: tableName ?? this.tableName,
      modelName: modelName ?? this.modelName,
      updatedAtColumn: updatedAtColumn ?? this.updatedAtColumn,
      trackPendingChanges: trackPendingChanges ?? this.trackPendingChanges,
      getCompositeKey: getCompositeKey ?? this.getCompositeKey,
      getKeyColumns: getKeyColumns ?? this.getKeyColumns,
      toJson: toJson ?? this.toJson,
      fromJson: fromJson ?? this.fromJson,
      setTimestamps: setTimestamps ?? this.setTimestamps,
    );
  }
}
