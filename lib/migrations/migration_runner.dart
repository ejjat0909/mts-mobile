import 'package:mts/core/utils/log_utils.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mts/migrations/migration.dart';
import 'package:mts/migrations/m_1763615792754_add_count_column.dart';
import 'package:mts/migrations/m_1764654510023_create_print_receipt_cache_table.dart';

class MigrationRunner {
  static final List<Migration> _migrations = [
    Migration1763615792754AddCountColumn(),

    Migration1764654510023CreatePrintReceiptCacheTable(),
  ];

  static int getLatestVersion() {
    if (_migrations.isEmpty) return 1;
    return _migrations.fold<int>(
      0,
      (maxVersion, migration) =>
          migration.version > maxVersion ? migration.version : maxVersion,
    );
  }

  static Future<void> runMigrations(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    final migrationsToRun =
        _migrations
            .where(
              (migration) =>
                  migration.version > oldVersion &&
                  migration.version <= newVersion,
            )
            .toList()
          ..sort((a, b) => a.version.compareTo(b.version));

    for (final migration in migrationsToRun) {
      prints(
        '[MigrationRunner] Running migration version ${migration.version}...',
      );
      try {
        await migration.up(db);
        prints(
          '[MigrationRunner] Migration version ${migration.version} completed',
        );
      } catch (e) {
        prints(
          '[MigrationRunner] Migration version ${migration.version} failed: $e',
        );
        rethrow;
      }
    }
  }
}
