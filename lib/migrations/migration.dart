import 'package:sqflite/sqflite.dart';

/// Base abstract migration class — all migration files should extend this.
abstract class Migration {
  /// Version number for this migration.
  /// Usually use a timestamp to ensure order.
  int get version;

  /// Executes the migration logic (SQL commands, data transforms, etc).
  Future<void> up(Database db);
}
