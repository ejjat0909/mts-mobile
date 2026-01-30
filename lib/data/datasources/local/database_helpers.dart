import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/services/database_index_manager.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/datasources/local/database_helpers_interface.dart';
import 'package:mts/data/datasources/local/pivot_element.dart';
import 'package:mts/migrations/migration_runner.dart';
import 'package:mts/data/repositories/local/local_cash_drawer_log_repository_impl.dart';
import 'package:mts/data/repositories/local/local_cash_management_repository_impl.dart';
import 'package:mts/data/repositories/local/local_category_repository_impl.dart';
import 'package:mts/data/repositories/local/local_city_repository_impl.dart';
import 'package:mts/data/repositories/local/local_country_repository_impl.dart';
import 'package:mts/data/repositories/local/local_division_repository_impl.dart';
import 'package:mts/data/repositories/local/local_category_discount_repository_impl.dart';
import 'package:mts/data/repositories/local/local_customer_repository_impl.dart';
import 'package:mts/data/repositories/local/local_deleted_sale_item_repository_impl.dart';
import 'package:mts/data/repositories/local/local_error_log_repository_impl.dart';
import 'package:mts/data/repositories/local/local_department_printer_repository_impl.dart';
import 'package:mts/data/repositories/local/local_device_repository_impl.dart';
import 'package:mts/data/repositories/local/local_discount_item_repository_impl.dart';
import 'package:mts/data/repositories/local/local_discount_outlet_repository_impl.dart';
import 'package:mts/data/repositories/local/local_discount_repository_impl.dart';
import 'package:mts/data/repositories/local/local_downloaded_file_repository_impl.dart';
import 'package:mts/data/repositories/local/local_feature_company_repository_impl.dart';
import 'package:mts/data/repositories/local/local_feature_repository_impl.dart';
import 'package:mts/data/repositories/local/local_item_modifier_repository_impl.dart';
import 'package:mts/data/repositories/local/local_inventory_repository_impl.dart';
import 'package:mts/data/repositories/local/local_inventory_outlet_repository_impl.dart';
import 'package:mts/data/repositories/local/local_inventory_transaction_repository_impl.dart';
import 'package:mts/data/repositories/local/local_item_repository_impl.dart';
import 'package:mts/data/repositories/local/local_item_representation_repository_impl.dart';
import 'package:mts/data/repositories/local/local_item_tax_repository_impl.dart';
import 'package:mts/data/repositories/local/local_outlet_payment_type_repository_impl.dart';
import 'package:mts/data/repositories/local/local_outlet_tax_repository_impl.dart';
import 'package:mts/data/repositories/local/local_category_tax_repository_impl.dart';
import 'package:mts/data/repositories/local/local_modifier_option_repository_impl.dart';
import 'package:mts/data/repositories/local/local_modifier_repository_impl.dart';
import 'package:mts/data/repositories/local/local_order_option_repository_impl.dart';
import 'package:mts/data/repositories/local/local_order_option_tax_repository_impl.dart';
import 'package:mts/data/repositories/local/local_outlet_repository_impl.dart';
import 'package:mts/data/repositories/local/local_page_item_repository_impl.dart';
import 'package:mts/data/repositories/local/local_page_repository_impl.dart';
import 'package:mts/data/repositories/local/local_payment_type_repository_impl.dart';
import 'package:mts/data/repositories/local/local_pending_changes_repository_impl.dart';
import 'package:mts/data/repositories/local/local_permission_repository_impl.dart';
import 'package:mts/data/repositories/local/local_predefined_order_repository_impl.dart';
import 'package:mts/data/repositories/local/local_printer_setting_repository_impl.dart';
import 'package:mts/data/repositories/local/local_printing_log_repository_impl.dart';
import 'package:mts/data/repositories/local/local_print_receipt_cache_repository_impl.dart';
import 'package:mts/data/repositories/local/local_receipt_item_repository_impl.dart';
import 'package:mts/data/repositories/local/local_receipt_repository_impl.dart';
import 'package:mts/data/repositories/local/local_receipt_settings_repository_impl.dart';
import 'package:mts/data/repositories/local/local_sale_item_repository_impl.dart';
import 'package:mts/data/repositories/local/local_sale_modifier_option_repository_impl.dart';
import 'package:mts/data/repositories/local/local_sale_modifier_repository_impl.dart';
import 'package:mts/data/repositories/local/local_sale_repository_impl.dart';
import 'package:mts/data/repositories/local/local_sale_variant_option_repository_impl.dart';
import 'package:mts/data/repositories/local/local_shift_repository_impl.dart';
import 'package:mts/data/repositories/local/local_slideshow_repository_impl.dart';
import 'package:mts/data/repositories/local/local_staff_repository_impl.dart';
import 'package:mts/data/repositories/local/local_supplier_repository_impl.dart';
import 'package:mts/data/repositories/local/local_table_repository_impl.dart';
import 'package:mts/data/repositories/local/local_table_section_repository_impl.dart';
import 'package:mts/data/repositories/local/local_tax_repository_impl.dart';
import 'package:mts/data/repositories/local/local_timecard_repository_impl.dart';
import 'package:mts/data/repositories/local/local_user_repository_impl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// ================================
/// Provider for Database Helpers
/// ================================
final databaseHelpersProvider = Provider<IDatabaseHelpers>((ref) {
  return DatabaseHelpers();
});

/// ================================
/// Database Helpers Implementation
/// ================================
/// Implementation of IDatabaseHelpers that provides helper methods for SQLite database operations.
class DatabaseHelpers implements IDatabaseHelpers {
  /// The name of the SQLite database file.
  static const String databaseName = 'mts.db';

  /// The current database version is determined by the latest migration version.
  /// Database upgrades are handled by migrations in lib/migrations/

  /// The database instance.
  Database? _database;

  /// Lock for database operations to prevent race conditions.
  final _lock = Completer<void>()..complete();

  /// Constructor for DatabaseHelpers.
  DatabaseHelpers();

  /// Returns the database instance, creating it if it doesn't exist.
  ///
  /// This getter ensures that only one database connection is active at a time.
  /// It also validates that the database connection is still open.
  @override
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    _database = null;

    // Use a lock to prevent concurrent database creation
    await _lock.future;

    // Check again in case another call created the database while waiting
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    _database = await _initDB();
    return _database!;
  }

  /// Initialize database and run migrations if database exists
  @override
  Future<void> initializeDatabaseWithMigrations() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, databaseName);
    final databaseFile = File(path);

    if (databaseFile.existsSync()) {
      prints('[DatabaseHelpers] Database exists, checking for migrations...');
      final db = await database;

      final version = await db.getVersion();
      final latestVersion = MigrationRunner.getLatestVersion();

      if (version < latestVersion) {
        prints(
          '[DatabaseHelpers] Running migrations from version $version to $latestVersion...',
        );
        await MigrationRunner.runMigrations(db, version, latestVersion);
        await db.setVersion(latestVersion);
        prints('[DatabaseHelpers] Migrations completed');
      } else {
        prints('[DatabaseHelpers] Database is up to date');
      }
    } else {
      prints('[DatabaseHelpers] Database does not exist yet');
    }
  }

  /// Initializes the database by opening a connection and creating tables if needed.
  ///
  /// This method is called by the [database] getter when the database needs to be created.
  Future<Database> _initDB() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, databaseName);

    return await openDatabase(
      path,
      version: MigrationRunner.getLatestVersion(),
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates all database tables and indexes when the database is first created.
  ///
  /// This method is called by [_initDB] during database creation.
  /// Both table creation and index creation are wrapped in a single transaction
  /// to ensure atomicity: either all tables and indexes are created, or the
  /// transaction is rolled back.
  Future<void> _createTables(Database db, int version) async {
    await db.transaction((txn) async {
      // ============ CREATE ALL TABLES ============

      // downloaded files
      await LocalDownloadedFileRepositoryImpl.createTable(db);

      // Error Logs
      await LocalErrorLogRepositoryImpl.createTable(db);

      // Pending changes
      await LocalPendingChangesRepositoryImpl.createTable(db);
      // Cash management
      await LocalCashManagementRepositoryImpl.createTable(db); //
      // Features
      await LocalFeatureRepositoryImpl.createTable(db); //
      await LocalFeatureCompanyRepositoryImpl.createTable(db); //

      // Categories
      await LocalCategoryRepositoryImpl.createTable(db); //
      await LocalCategoryTaxRepositoryImpl.createTable(db);
      await LocalCategoryDiscountRepositoryImpl.createTable(db);

      // Cities
      await LocalCityRepositoryImpl.createTable(db);

      // Countries
      await LocalCountryRepositoryImpl.createTable(db);

      // Divisions
      await LocalDivisionRepositoryImpl.createTable(db);

      // Customers
      await LocalCustomerRepositoryImpl.createTable(db); //

      // Discounts
      await LocalDiscountRepositoryImpl.createTable(db); //
      await LocalDiscountItemRepositoryImpl.createTable(db); //
      await LocalDiscountOutletRepositoryImpl.createTable(db); //

      // Items and related tables
      await LocalItemRepositoryImpl.createTable(db); //
      await LocalItemRepresentationRepositoryImpl.createTable(db); //
      await LocalItemTaxRepositoryImpl.createTable(db); //
      await LocalOrderOptionTaxRepositoryImpl.createTable(db);
      await LocalItemModifierRepositoryImpl.createTable(db); //

      // Inventory
      await LocalInventoryRepositoryImpl.createTable(db);
      await LocalInventoryOutletRepositoryImpl.createTable(db);
      await LocalInventoryTransactionRepositoryImpl.createTable(db);

      // Outlet related tables
      await LocalOutletTaxRepositoryImpl.createTable(db);
      await LocalOutletPaymentTypeRepositoryImpl.createTable(db);
      // Modifiers
      await LocalModifierRepositoryImpl.createTable(db); //
      await LocalModifierOptionRepositoryImpl.createTable(db); //

      // Order options
      await LocalOrderOptionRepositoryImpl.createTable(db); //

      // Pages
      await LocalPageRepositoryImpl.createTable(db); //
      await LocalPageItemRepositoryImpl.createTable(db); //

      // Payments
      await LocalPaymentTypeRepositoryImpl.createTable(db); //

      // Predefined orders
      await LocalPredefinedOrderRepositoryImpl.createTable(db); //

      // Printers
      await LocalPrinterSettingRepositoryImpl.createTable(db); //
      await LocalDepartmentPrinterRepositoryImpl.createTable(db); //

      // Receipts
      await LocalReceiptRepositoryImpl.createTable(db); //
      await LocalReceiptItemRepositoryImpl.createTable(db); //
      await LocalReceiptSettingsRepositoryImpl.createTable(db); //

      // Sales
      await LocalSaleRepositoryImpl.createTable(db); //
      await LocalSaleItemRepositoryImpl.createTable(db); //
      await LocalSaleModifierRepositoryImpl.createTable(db); //
      await LocalSaleModifierOptionRepositoryImpl.createTable(db); //
      await LocalSaleVariantOptionRepositoryImpl.createTable(db);

      // Staff and users
      await LocalStaffRepositoryImpl.createTable(db); //
      await LocalUserRepositoryImpl.createTable(db); //
      await LocalPermissionRepositoryImpl.createTable(db);

      // Taxes
      await LocalTaxRepositoryImpl.createTable(db); //

      // Outlet and devices
      await LocalOutletRepositoryImpl.createTable(db); //
      await LocalDeviceRepositoryImpl.createTable(db); //

      // Shifts and timecards
      await LocalShiftRepositoryImpl.createTable(db); //
      await LocalTimecardRepositoryImpl.createTable(db); //

      // Display
      await LocalSlideshowRepositoryImpl.createTable(db);

      // Tables
      await LocalTableRepositoryImpl.createTable(db); //
      await LocalTableSectionRepositoryImpl.createTable(db); //

      // Suppliers
      await LocalSupplierRepositoryImpl.createTable(db);

      // Printing Logs
      await LocalPrintingLogRepositoryImpl.createTable(db);

      // Print Receipt Cache
      await LocalPrintReceiptCacheRepositoryImpl.createTable(db);

      // Cash Drawer Logs
      await LocalCashDrawerLogRepositoryImpl.createTable(db);

      // Deleted Sale Items
      await LocalDeletedSaleItemRepositoryImpl.createTable(db);

      // Error Logs
      await LocalErrorLogRepositoryImpl.createTable(db);

      // ============ CREATE ALL INDEXES ============
      // After all tables are created, create indexes for performance optimization.
      // This is within the same transaction to ensure atomicity.
      await DatabaseIndexManager.createAllIndexes(db);
    });
  }

  /// Handles database upgrades when version changes.
  ///
  /// This method is called when the database version is incremented.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    prints(
      '[DatabaseHelpers] Starting database upgrade from version $oldVersion to $newVersion',
    );

    await MigrationRunner.runMigrations(db, oldVersion, newVersion);

    prints('[DatabaseHelpers] Database upgrade completed');
  }

  /// Inserts a new row into a table.
  ///
  /// [tableName] is the name of the table.
  /// [row] is a map of column names to values.
  /// Returns the ID of the inserted row.
  @override
  Future<int> insertDb(String tableName, Map<String, dynamic> row) async {
    try {
      final db = await database;
      return await db.insert(
        tableName,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Failed to insert into $tableName: $e');
    }
  }

  /// Retrieves a row from a table by its ID.
  ///
  /// [tableName] is the name of the table.
  /// [id] is the ID of the row to retrieve.
  /// Returns the row as a map, or null if not found.
  @override
  Future<Map<String, dynamic>?> readDbById(String tableName, dynamic id) async {
    try {
      final db = await database;
      final results = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      throw DatabaseException('Failed to read from $tableName by ID: $e');
    }
  }

  /// Retrieves a row from a table based on multiple conditions.
  ///
  /// [tableName] is the name of the table.
  /// [conditions] is a map of column names to values to match.
  /// Returns the first matching row as a map, or null if not found.
  @override
  Future<Map<String, dynamic>?> readDbWithConditions(
    String tableName,
    Map<String, dynamic> conditions,
  ) async {
    try {
      final db = await database;

      // Build the WHERE clause and whereArgs list
      final whereClause = conditions.keys
          .map((key) => '$key = ?')
          .join(' AND ');
      final whereArgs = conditions.values.toList();

      // Perform the query
      final results = await db.query(
        tableName,
        where: whereClause,
        whereArgs: whereArgs,
        limit: 1,
      );

      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      throw DatabaseException(
        'Failed to read from $tableName with conditions: $e',
      );
    }
  }

  /// Retrieves all rows from a table.
  ///
  /// [tableName] is the name of the table.
  /// Returns a list of all rows as maps.
  @override
  Future<List<Map<String, dynamic>>> readDb(String tableName) async {
    try {
      final db = await database;
      return await db.query(tableName);
    } catch (e) {
      throw DatabaseException('Failed to read all from $tableName: $e');
    }
  }

  /// Updates a row in a table by its ID.
  ///
  /// [tableName] is the name of the table.
  /// [row] is a map of column names to new values, must include an 'id' key.
  /// Returns the number of rows affected (1 for success, 0 for failure).
  @override
  Future<int> updateDb(String tableName, Map<String, dynamic> row) async {
    try {
      final db = await database;

      if (!row.containsKey('id')) {
        throw ArgumentError('The provided row does not contain an id field.');
      }

      final id = row['id'];
      return await db.update(tableName, row, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw DatabaseException('Failed to update $tableName: $e');
    }
  }

  /// Updates a row in a pivot table based on two column conditions.
  ///
  /// [tableName] is the name of the table.
  /// [firstElement] is the first column and value to match.
  /// [secondElement] is the second column and value to match.
  /// [updates] is a map of column names to new values.
  /// Returns the number of rows affected.
  @override
  Future<int> updatePivotDb(
    String tableName,
    PivotElement firstElement,
    PivotElement secondElement,
    Map<String, dynamic> updates,
  ) async {
    try {
      final db = await database;

      // Prepare the update statement
      final whereClause =
          '${firstElement.columnName} = ? AND ${secondElement.columnName} = ?';
      final whereArgs = [firstElement.value, secondElement.value];

      return await db.update(
        tableName,
        updates,
        where: whereClause,
        whereArgs: whereArgs,
      );
    } catch (e) {
      throw DatabaseException('Failed to update pivot table $tableName: $e');
    }
  }

  /// Deletes a row from a table by its ID.
  ///
  /// [tableName] is the name of the table.
  /// [id] is the ID of the row to delete.
  /// Returns the number of rows affected.
  @override
  Future<int> deleteDb(String tableName, dynamic id) async {
    try {
      final db = await database;
      return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw DatabaseException('Failed to delete from $tableName: $e');
    }
  }

  /// Deletes rows from a table based on multiple conditions.
  ///
  /// [tableName] is the name of the table.
  /// [conditions] is a map of column names to values to match.
  /// Returns the number of rows affected.
  @override
  Future<int> deleteDbWithConditions(
    String tableName,
    Map<String, dynamic> conditions,
  ) async {
    try {
      final db = await database;

      // Build the WHERE clause and whereArgs list
      final whereClause = conditions.keys
          .map((key) => '$key = ?')
          .join(' AND ');
      final whereArgs = conditions.values.toList();

      return await db.delete(
        tableName,
        where: whereClause,
        whereArgs: whereArgs,
      );
    } catch (e) {
      throw DatabaseException(
        'Failed to delete from $tableName with conditions: $e',
      );
    }
  }

  /// Deletes a row from a pivot table based on two column conditions.
  ///
  /// [tableName] is the name of the table.
  /// [firstElement] is the first column and value to match.
  /// [secondElement] is the second column and value to match.
  /// Returns the number of rows affected.
  @override
  Future<int> deletePivotDb(
    String tableName,
    PivotElement firstElement,
    PivotElement secondElement,
  ) async {
    try {
      final db = await database;
      return await db.delete(
        tableName,
        where:
            '${firstElement.columnName} = ? AND ${secondElement.columnName} = ?',
        whereArgs: [firstElement.value, secondElement.value],
      );
    } catch (e) {
      throw DatabaseException(
        'Failed to delete from pivot table $tableName: $e',
      );
    }
  }

  /// Retrieves rows from a table based on a custom WHERE clause.
  ///
  /// [tableName] is the name of the table.
  /// [where] is the SQL WHERE clause.
  /// [whereArgs] are the arguments for the WHERE clause placeholders.
  /// Returns a list of matching rows as maps.
  @override
  Future<List<Map<String, dynamic>>> readDbWhere(
    String tableName, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    try {
      final db = await database;
      return await db.query(tableName, where: where, whereArgs: whereArgs);
    } catch (e) {
      throw DatabaseException(
        'Failed to read from $tableName with WHERE clause: $e',
      );
    }
  }

  /// Executes a raw SQL query and returns the results.
  ///
  /// [sql] is the SQL query to execute.
  /// [arguments] are the arguments for the SQL query placeholders.
  /// Returns a list of rows as maps.
  @override
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    try {
      final db = await database;
      return await db.rawQuery(sql, arguments);
    } catch (e) {
      throw DatabaseException('Failed to execute raw query: $e');
    }
  }

  /// Executes a batch of operations in a single transaction.
  ///
  /// [operations] is a function that receives a batch object to add operations to.
  /// Returns the results of the batch operations.
  @override
  Future<List<dynamic>> batch(
    Future<void> Function(Batch batch) operations,
  ) async {
    try {
      final db = await database;
      final batch = db.batch();

      await operations(batch);

      return await batch.commit(noResult: false);
    } catch (e) {
      throw DatabaseException('Failed to execute batch operations: $e');
    }
  }

  /// Closes a database connection.
  ///
  /// [db] is the database connection to close.
  @override
  Future<void> closeDb({required Database db}) async {
    try {
      await db.close();
    } catch (e) {
      throw DatabaseException('Failed to close database: $e');
    }
  }

  /// Opens a database connection.
  ///
  /// Returns a new database connection.
  @override
  Future<Database> openDb() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, databaseName);

      return await openDatabase(
        path,
        version: MigrationRunner.getLatestVersion(),
        onOpen: (db) {
          // Use a logger instead of print in production code
          // Logger.info('Database opened successfully');
        },
      );
    } catch (e) {
      throw DatabaseException('Failed to open database: $e');
    }
  }

  /// Deletes a table from the database.
  ///
  /// [tableName] is the name of the table to delete.
  @override
  Future<void> deleteTable(String tableName) async {
    try {
      final db = await database;
      await db.execute('DROP TABLE IF EXISTS $tableName');
    } catch (e) {
      throw DatabaseException('Failed to delete table $tableName: $e');
    }
  }

  /// Drops all tables from the database.
  ///
  /// This is useful for completely resetting the database.
  @override
  Future<void> dropAllTables() async {
    try {
      final db = await database;

      // Get all table names
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
      );

      // Drop each table in a transaction
      await db.transaction((txn) async {
        for (final table in tables) {
          final tableName = table['name'] as String;
          await txn.execute('DROP TABLE IF EXISTS $tableName');
        }
      });
    } catch (e) {
      throw DatabaseException('Failed to drop all tables: $e');
    }
  }

  /// Completely deletes the database file.
  ///
  /// This removes the database file from disk and resets the database instance.
  @override
  Future<void> dropDb() async {
    try {
      var databasesPath = await getDatabasesPath();
      String path = join(databasesPath, databaseName);

      await deleteDatabase(path);
      _database = null; // Reset the database instance
    } catch (e) {
      throw DatabaseException('Failed to drop database: $e');
    }
  }

  /// Checks if the database file exists.
  ///
  /// Returns true if the database file exists, false otherwise.
  @override
  Future<bool> dbExists() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, databaseName);
      return await File(path).exists();
    } catch (e) {
      throw DatabaseException('Failed to check if database exists: $e');
    }
  }

  /// Performs a database backup.
  ///
  /// [backupPath] is the path where the backup should be saved.
  /// Returns true if the backup was successful.
  @override
  Future<bool> backupDatabase(String backupPath) async {
    try {
      final db = await database;
      await db.close();
      _database = null;

      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, databaseName);

      if (await File(path).exists()) {
        await File(path).copy(backupPath);

        // Reopen the database
        _database = await _initDB();
        return true;
      }
      return false;
    } catch (e) {
      // Make sure to reopen the database even if the backup fails
      _database ??= await _initDB();
      throw DatabaseException('Failed to backup database: $e');
    }
  }

  /// Restores a database from a backup.
  ///
  /// [backupPath] is the path to the backup file.
  /// Returns true if the restore was successful.
  @override
  Future<bool> restoreDatabase(String backupPath) async {
    try {
      // Check if backup file exists
      if (!await File(backupPath).exists()) {
        return false;
      }

      // Close current database
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, databaseName);

      // Delete current database if it exists
      if (await File(path).exists()) {
        await File(path).delete();
      }

      // Copy backup to database location
      await File(backupPath).copy(path);

      // Reopen the database
      _database = await _initDB();
      return true;
    } catch (e) {
      // Make sure to reopen the database even if the restore fails
      _database ??= await _initDB();
      throw DatabaseException('Failed to restore database: $e');
    }
  }
}

/// Custom exception class for database-related errors.
class DatabaseException implements Exception {
  final String message;

  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}
