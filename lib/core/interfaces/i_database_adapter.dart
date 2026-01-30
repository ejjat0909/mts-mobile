/// Abstraction for database operations
/// Allows different database implementations (SQLite, PostgreSQL, etc.)
abstract class IDatabaseAdapter {
  /// Execute a query and return results
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  });

  /// Insert a record and return the row ID
  Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    String? conflictAlgorithm,
  });

  /// Update records and return the number of rows affected
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  });

  /// Delete records and return the number of rows affected
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs});

  /// Execute a raw SQL query
  Future<int> rawInsert(String sql, [List<Object?>? arguments]);

  /// Execute a raw SQL delete
  Future<int> rawDelete(String sql, [List<Object?>? arguments]);

  /// Execute operations in a transaction
  Future<T> transaction<T>(Future<T> Function(IDatabaseAdapter txn) action);

  /// Create a batch for bulk operations
  DatabaseBatch batch();
}

/// Abstraction for database batch operations
abstract class DatabaseBatch {
  /// Add an insert operation to the batch
  void insert(
    String table,
    Map<String, dynamic> values, {
    String? conflictAlgorithm,
  });

  /// Add a raw insert operation to the batch
  void rawInsert(String sql, [List<Object?>? arguments]);

  /// Add a delete operation to the batch
  void delete(String table, {String? where, List<Object?>? whereArgs});

  /// Commit all batch operations
  Future<List<Object?>> commit({bool? noResult});
}
