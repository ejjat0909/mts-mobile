import 'package:mts/core/interfaces/i_database_adapter.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

/// SQLite implementation of IDatabaseAdapter
class SqfliteDatabaseAdapter implements IDatabaseAdapter {
  final sqflite.Database _db;

  SqfliteDatabaseAdapter(this._db);

  @override
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
  }) {
    return _db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    String? conflictAlgorithm,
  }) {
    return _db.insert(
      table,
      values,
      conflictAlgorithm: _mapConflictAlgorithm(conflictAlgorithm),
    );
  }

  @override
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    return _db.update(table, values, where: where, whereArgs: whereArgs);
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) {
    return _db.delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) {
    return _db.rawInsert(sql, arguments);
  }

  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) {
    return _db.rawDelete(sql, arguments);
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(IDatabaseAdapter txn) action,
  ) async {
    return await _db.transaction((txn) async {
      final adapter = _SqfliteTransactionAdapter(txn);
      return await action(adapter);
    });
  }

  @override
  DatabaseBatch batch() {
    return _SqfliteBatchAdapter(_db.batch());
  }

  sqflite.ConflictAlgorithm? _mapConflictAlgorithm(String? algorithm) {
    if (algorithm == null) return null;
    switch (algorithm.toLowerCase()) {
      case 'replace':
        return sqflite.ConflictAlgorithm.replace;
      case 'rollback':
        return sqflite.ConflictAlgorithm.rollback;
      case 'abort':
        return sqflite.ConflictAlgorithm.abort;
      case 'fail':
        return sqflite.ConflictAlgorithm.fail;
      case 'ignore':
        return sqflite.ConflictAlgorithm.ignore;
      default:
        return null;
    }
  }
}

/// Adapter for SQLite transactions
class _SqfliteTransactionAdapter implements IDatabaseAdapter {
  final sqflite.Transaction _txn;

  _SqfliteTransactionAdapter(this._txn);

  @override
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
  }) {
    return _txn.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    String? conflictAlgorithm,
  }) {
    return _txn.insert(
      table,
      values,
      conflictAlgorithm: _mapConflictAlgorithm(conflictAlgorithm),
    );
  }

  @override
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    return _txn.update(table, values, where: where, whereArgs: whereArgs);
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) {
    return _txn.delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) {
    return _txn.rawInsert(sql, arguments);
  }

  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) {
    return _txn.rawDelete(sql, arguments);
  }

  @override
  Future<T> transaction<T>(Future<T> Function(IDatabaseAdapter txn) action) {
    throw UnsupportedError('Nested transactions are not supported');
  }

  @override
  DatabaseBatch batch() {
    return _SqfliteBatchAdapter(_txn.batch());
  }

  sqflite.ConflictAlgorithm? _mapConflictAlgorithm(String? algorithm) {
    if (algorithm == null) return null;
    switch (algorithm.toLowerCase()) {
      case 'replace':
        return sqflite.ConflictAlgorithm.replace;
      case 'rollback':
        return sqflite.ConflictAlgorithm.rollback;
      case 'abort':
        return sqflite.ConflictAlgorithm.abort;
      case 'fail':
        return sqflite.ConflictAlgorithm.fail;
      case 'ignore':
        return sqflite.ConflictAlgorithm.ignore;
      default:
        return null;
    }
  }
}

/// Adapter for SQLite batch operations
class _SqfliteBatchAdapter implements DatabaseBatch {
  final sqflite.Batch _batch;

  _SqfliteBatchAdapter(this._batch);

  @override
  void insert(
    String table,
    Map<String, dynamic> values, {
    String? conflictAlgorithm,
  }) {
    _batch.insert(
      table,
      values,
      conflictAlgorithm: _mapConflictAlgorithm(conflictAlgorithm),
    );
  }

  @override
  void rawInsert(String sql, [List<Object?>? arguments]) {
    _batch.rawInsert(sql, arguments);
  }

  @override
  void delete(String table, {String? where, List<Object?>? whereArgs}) {
    _batch.delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  Future<List<Object?>> commit({bool? noResult}) {
    return _batch.commit(noResult: noResult ?? false);
  }

  sqflite.ConflictAlgorithm? _mapConflictAlgorithm(String? algorithm) {
    if (algorithm == null) return null;
    switch (algorithm.toLowerCase()) {
      case 'replace':
        return sqflite.ConflictAlgorithm.replace;
      case 'rollback':
        return sqflite.ConflictAlgorithm.rollback;
      case 'abort':
        return sqflite.ConflictAlgorithm.abort;
      case 'fail':
        return sqflite.ConflictAlgorithm.fail;
      case 'ignore':
        return sqflite.ConflictAlgorithm.ignore;
      default:
        return null;
    }
  }
}
