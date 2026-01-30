import 'package:mts/data/repositories/local/local_sale_item_repository_impl.dart';
import 'package:mts/data/repositories/local/local_sale_modifier_repository_impl.dart';
import 'package:mts/data/repositories/local/local_sale_repository_impl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mts/migrations/migration.dart';

/// Migration: add_count_column
/// Generated at: 2025-11-20 13:16:32.758858

class Migration1763615792754AddCountColumn extends Migration {
  @override
  int get version => 1763615792754;

  String tableSaleItem = LocalSaleItemRepositoryImpl.tableName;
  String cSaleModifierCount = LocalSaleItemRepositoryImpl.saleModifierCount;

  String tableSaleModifier = LocalSaleModifierRepositoryImpl.tableName;
  String cSaleModifierOptionCount =
      LocalSaleModifierRepositoryImpl.cSaleModifierOptionCount;

  String tableSale = LocalSaleRepositoryImpl.tableName;
  String cSaleItemIdsToPrint = LocalSaleRepositoryImpl.saleItemIdsToPrint;
  String cSaleItemIdsToPrintVoid = LocalSaleRepositoryImpl.saleItemIdsToPrintVoid;

  @override
  Future<void> up(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info($tableSaleItem)');
    bool hasSaleModifierCount = info.any((col) => col['name'] == cSaleModifierCount);
    if (!hasSaleModifierCount) {
      await db.execute(
        'ALTER TABLE $tableSaleItem ADD COLUMN $cSaleModifierCount INTEGER NULL',
      );
    }

    final modifierInfo = await db.rawQuery('PRAGMA table_info($tableSaleModifier)');
    bool hasSaleModifierOptionCount = modifierInfo.any((col) => col['name'] == cSaleModifierOptionCount);
    if (!hasSaleModifierOptionCount) {
      await db.execute(
        'ALTER TABLE $tableSaleModifier ADD COLUMN $cSaleModifierOptionCount INTEGER NULL',
      );
    }

    final saleInfo = await db.rawQuery('PRAGMA table_info($tableSale)');
    bool hasSaleItemIdsToPrint = saleInfo.any((col) => col['name'] == cSaleItemIdsToPrint);
    if (!hasSaleItemIdsToPrint) {
      await db.execute(
        'ALTER TABLE $tableSale ADD COLUMN $cSaleItemIdsToPrint TEXT NULL',
      );
    }

    bool hasSaleItemIdsToPrintVoid = saleInfo.any((col) => col['name'] == cSaleItemIdsToPrintVoid);
    if (!hasSaleItemIdsToPrintVoid) {
      await db.execute(
        'ALTER TABLE $tableSale ADD COLUMN $cSaleItemIdsToPrintVoid TEXT NULL',
      );
    }
  }
}
