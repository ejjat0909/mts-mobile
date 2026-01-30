import 'package:mts/data/repositories/local/local_print_receipt_cache_repository_impl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mts/migrations/migration.dart';

/// Migration: create_print_receipt_cache_table
/// Generated at: 2025-12-02 13:48:30.027713

class Migration1764654510023CreatePrintReceiptCacheTable extends Migration {
  @override
  int get version => 1764654510023;

  @override
  Future<void> up(Database db) async {
    await LocalPrintReceiptCacheRepositoryImpl.createTable(db);
  }
}
