import 'package:mts/data/datasources/local/pivot_element.dart';
import 'package:sqflite/sqflite.dart';

/// Interface for database helper methods.
///
/// This interface defines the contract for database operations that can be
/// implemented by concrete database helper classes.
abstract class IDatabaseHelpers {
  /// Returns the database instance, creating it if it doesn't exist.
  Future<Database> get database;

  /// Creates a new table in the database.
  ///
  /// [tableName] is the name of the table to create.
  /// [rows] is the SQL definition of the table columns.
  /// [db] is the database instance to use.
  static Future<void> createTable(
    String tableName,
    String rows,
    Database db,
  ) async {
    try {
      final sql = 'CREATE TABLE IF NOT EXISTS $tableName ($rows)';
      await db.execute(sql);
    } catch (e) {
      throw Exception('Failed to create table $tableName: $e');
    }
  }

  /// Inserts a new row into a table.
  ///
  /// [tableName] is the name of the table.
  /// [row] is a map of column names to values.
  /// Returns the ID of the inserted row.
  Future<int> insertDb(String tableName, Map<String, dynamic> row);

  /// Retrieves a row from a table by its ID.
  ///
  /// [tableName] is the name of the table.
  /// [id] is the ID of the row to retrieve.
  /// Returns the row as a map, or null if not found.
  Future<Map<String, dynamic>?> readDbById(String tableName, dynamic id);

  /// Retrieves a row from a table based on multiple conditions.
  ///
  /// [tableName] is the name of the table.
  /// [conditions] is a map of column names to values to match.
  /// Returns the first matching row as a map, or null if not found.
  Future<Map<String, dynamic>?> readDbWithConditions(
    String tableName,
    Map<String, dynamic> conditions,
  );

  /// Retrieves all rows from a table.
  ///
  /// [tableName] is the name of the table.
  /// Returns a list of all rows as maps.
  Future<List<Map<String, dynamic>>> readDb(String tableName);

  /// Updates a row in a table by its ID.
  ///
  /// [tableName] is the name of the table.
  /// [row] is a map of column names to new values, must include an 'id' key.
  /// Returns the number of rows affected (1 for success, 0 for failure).
  Future<int> updateDb(String tableName, Map<String, dynamic> row);

  /// Updates a row in a pivot table based on two column conditions.
  ///
  /// [tableName] is the name of the table.
  /// [firstElement] is the first column and value to match.
  /// [secondElement] is the second column and value to match.
  /// [updates] is a map of column names to new values.
  /// Returns the number of rows affected.
  Future<int> updatePivotDb(
    String tableName,
    PivotElement firstElement,
    PivotElement secondElement,
    Map<String, dynamic> updates,
  );

  /// Deletes a row from a table by its ID.
  ///
  /// [tableName] is the name of the table.
  /// [id] is the ID of the row to delete.
  /// Returns the number of rows affected.
  Future<int> deleteDb(String tableName, dynamic id);

  /// Deletes rows from a table based on multiple conditions.
  ///
  /// [tableName] is the name of the table.
  /// [conditions] is a map of column names to values to match.
  /// Returns the number of rows affected.
  Future<int> deleteDbWithConditions(
    String tableName,
    Map<String, dynamic> conditions,
  );

  /// Deletes a row from a pivot table based on two column conditions.
  ///
  /// [tableName] is the name of the table.
  /// [firstElement] is the first column and value to match.
  /// [secondElement] is the second column and value to match.
  /// Returns the number of rows affected.
  Future<int> deletePivotDb(
    String tableName,
    PivotElement firstElement,
    PivotElement secondElement,
  );

  /// Retrieves rows from a table based on a custom WHERE clause.
  ///
  /// [tableName] is the name of the table.
  /// [where] is the SQL WHERE clause.
  /// [whereArgs] are the arguments for the WHERE clause placeholders.
  /// Returns a list of matching rows as maps.
  Future<List<Map<String, dynamic>>> readDbWhere(
    String tableName, {
    required String where,
    required List<dynamic> whereArgs,
  });

  /// Executes a raw SQL query and returns the results.
  ///
  /// [sql] is the SQL query to execute.
  /// [arguments] are the arguments for the SQL query placeholders.
  /// Returns a list of rows as maps.
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]);

  /// Executes a batch of operations in a single transaction.
  ///
  /// [operations] is a function that receives a batch object to add operations to.
  /// Returns the results of the batch operations.
  Future<List<dynamic>> batch(Future<void> Function(Batch batch) operations);

  /// Closes a database connection.
  ///
  /// [db] is the database connection to close.
  Future<void> closeDb({required Database db});

  /// Opens a database connection.
  ///
  /// Returns a new database connection.
  Future<Database> openDb();

  /// Deletes a table from the database.
  ///
  /// [tableName] is the name of the table to delete.
  Future<void> deleteTable(String tableName);

  /// Drops all tables from the database.
  ///
  /// This is useful for completely resetting the database.
  Future<void> dropAllTables();

  /// Completely deletes the database file.
  ///
  /// This removes the database file from disk and resets the database instance.
  Future<void> dropDb();

  /// Checks if the database file exists.
  ///
  /// Returns true if the database file exists, false otherwise.
  Future<bool> dbExists();

  /// Performs a database backup.
  ///
  /// [backupPath] is the path where the backup should be saved.
  /// Returns true if the backup was successful.
  Future<bool> backupDatabase(String backupPath);

  /// Restores a database from a backup.
  ///
  /// [backupPath] is the path to the backup file.
  /// Returns true if the restore was successful.
  Future<bool> restoreDatabase(String backupPath);

  Future<void> initializeDatabaseWithMigrations();
}
