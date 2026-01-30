import 'package:mts/core/utils/log_utils.dart';
import 'package:sqflite/sqflite.dart';

/// Centralized service to manage database indexes for optimal query performance.
///
/// This class handles creation of all database indexes that improve performance
/// when single operations update/save multiple tables (10-20 tables).
class DatabaseIndexManager {
  /// Creates all indexes for the MTS database.
  ///
  /// This should be called after all tables are created during database initialization.
  /// Can be called with or without an existing transaction - if called within a transaction,
  /// pass the Database object and it will work correctly (similar to createTable pattern).
  static Future<void> createAllIndexes(Database db) async {
    try {
      // Sales related indexes
      await _createSaleIndexes(db);

      // Sale items and modifiers
      await _createSaleItemIndexes(db);
      await _createSaleModifierIndexes(db);
      await _createSaleModifierOptionIndexes(db);
      await _createSaleVariantOptionIndexes(db);

      // Item related indexes
      await _createItemIndexes(db);
      await _createItemModifierIndexes(db);
      await _createItemTaxIndexes(db);

      // Category indexes
      await _createCategoryIndexes(db);
      await _createCategoryTaxIndexes(db);
      await _createCategoryDiscountIndexes(db);

      // Discount indexes
      await _createDiscountIndexes(db);
      await _createDiscountItemIndexes(db);
      await _createDiscountOutletIndexes(db);

      // Tax indexes
      await _createTaxIndexes(db);
      await _createOutletTaxIndexes(db);
      await _createOrderOptionTaxIndexes(db);

      // Outlet indexes
      await _createOutletIndexes(db);
      await _createOutletPaymentTypeIndexes(db);

      // Modifier indexes
      await _createModifierIndexes(db);
      await _createModifierOptionIndexes(db);

      // Order option indexes
      await _createOrderOptionIndexes(db);

      // Page indexes
      await _createPageIndexes(db);
      await _createPageItemIndexes(db);

      // Payment indexes
      await _createPaymentTypeIndexes(db);

      // Receipt indexes
      await _createReceiptIndexes(db);
      await _createReceiptItemIndexes(db);

      // Customer indexes
      await _createCustomerIndexes(db);

      // Pending changes indexes (critical for sync)
      await _createPendingChangesIndexes(db);

      // Staff and user indexes
      await _createStaffIndexes(db);
      await _createUserIndexes(db);

      // Table and shift indexes
      await _createTableIndexes(db);
      await _createTableSectionIndexes(db);
      await _createShiftIndexes(db);

      // Other important indexes
      await _createInventoryIndexes(db);
      await _createInventoryTransactionIndexes(db);
      await _createPredefinedOrderIndexes(db);
      await _createPrinterSettingIndexes(db);
      await _createDepartmentPrinterIndexes(db);

      prints('[DatabaseIndexManager] ✓ All indexes created successfully');
    } catch (e) {
      prints('[DatabaseIndexManager] ✗ Error creating indexes: $e');
      rethrow;
    }
  }

  /// Safely creates an index, silently skipping if the table doesn't exist.
  ///
  /// This is useful for development/testing scenarios where not all tables
  /// may be present, or for resilience against schema changes.
  static Future<void> _safeCreateIndex(
    DatabaseExecutor db,
    String indexSql,
  ) async {
    try {
      await db.execute(indexSql);
    } catch (e) {
      // Silently skip if table doesn't exist
      if (e.toString().contains('no such table')) {
        // Log at debug level if needed, but don't fail
        return;
      }
      // Re-throw other errors
      rethrow;
    }
  }

  // ============================================================================
  // SALES RELATED INDEXES
  // ============================================================================

  static Future<void> _createSaleIndexes(Database db) async {
    // Index for filtering sales by outlet
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_sales_outlet_id 
      ON sales(outlet_id)
    ''');

    // Index for filtering sales by staff
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_sales_staff_id 
      ON sales(staff_id)
    ''');

    // Index for filtering sales by table
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_sales_table_id 
      ON sales(table_id)
    ''');

    // Composite index for finding charged sales in a timeframe
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_sales_charged_at 
      ON sales(charged_at)
    ''');

    // Composite index for active (uncharged) sales
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_sales_outlet_charged 
      ON sales(outlet_id, charged_at)
    ''');
  }

  // ============================================================================
  // SALE ITEMS AND MODIFIERS INDEXES
  // ============================================================================

  static Future<void> _createSaleItemIndexes(DatabaseExecutor db) async {
    // Primary foreign key - most commonly filtered
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id 
      ON sale_items(sale_id)
    ''');

    // Secondary foreign keys
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_sale_items_item_id 
      ON sale_items(item_id)
    ''');

    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_sale_items_category_id 
      ON sale_items(category_id)
    ''');

    // Status flag indexes
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_sale_items_is_voided 
      ON sale_items(is_voided)
    ''');

    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_sale_items_is_printed_kitchen 
      ON sale_items(is_printed_kitchen)
    ''');

    // Composite indexes for common queries
    // Find active items for a sale
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_sale_items_sale_voided 
      ON sale_items(sale_id, is_voided)
    ''');

    // Find active items by category
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_sale_items_category_voided 
      ON sale_items(category_id, is_voided)
    ''');

    // For kitchen printing
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_sale_items_sale_printed 
      ON sale_items(sale_id, is_printed_kitchen)
    ''');
  }

  static Future<void> _createSaleModifierIndexes(DatabaseExecutor db) async {
    // Primary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_sale_modifiers_sale_item_id 
      ON sale_modifiers(sale_item_id)
    ''');

    // Secondary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_sale_modifiers_modifier_id 
      ON sale_modifiers(modifier_id)
    ''');
  }

  static Future<void> _createSaleModifierOptionIndexes(
    DatabaseExecutor db,
  ) async {
    // Primary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_sale_modifier_options_sale_modifier_id 
      ON sale_modifier_options(sale_modifier_id)
    ''');

    // Secondary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_sale_modifier_options_option_id 
      ON sale_modifier_options(modifier_option_id)
    ''');
  }

  static Future<void> _createSaleVariantOptionIndexes(
    DatabaseExecutor db,
  ) async {
    // Index for variant_option_id lookups
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_sale_variant_options_variant_option_id 
      ON sale_variant_options(variant_option_id)
    ''');
  }

  // ============================================================================
  // ITEM RELATED INDEXES
  // ============================================================================

  static Future<void> _createItemIndexes(DatabaseExecutor db) async {
    // Filter items by category
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_items_category_id 
      ON items(category_id)
    ''');
  }

  static Future<void> _createItemModifierIndexes(DatabaseExecutor db) async {
    // Primary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_item_modifiers_item_id 
      ON item_modifier(item_id)
    ''');

    // Secondary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_item_modifiers_modifier_id 
      ON item_modifier(modifier_id)
    ''');
  }

  static Future<void> _createItemTaxIndexes(DatabaseExecutor db) async {
    // Primary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_item_taxes_item_id 
      ON item_tax(item_id)
    ''');

    // Secondary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_item_taxes_tax_id 
      ON item_tax(tax_id)
    ''');
  }

  // ============================================================================
  // CATEGORY RELATED INDEXES
  // ============================================================================

  static Future<void> _createCategoryIndexes(DatabaseExecutor db) async {
    // Filter categories by company
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_categories_company_id 
      ON categories(company_id)
    ''');
  }

  static Future<void> _createCategoryTaxIndexes(DatabaseExecutor db) async {
    // Primary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_category_taxes_category_id 
      ON category_tax(category_id)
    ''');

    // Secondary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_category_taxes_tax_id 
      ON category_tax(tax_id)
    ''');
  }

  static Future<void> _createCategoryDiscountIndexes(
    DatabaseExecutor db,
  ) async {
    // Primary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_category_discounts_category_id 
      ON category_discount(category_id)
    ''');

    // Secondary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_category_discounts_discount_id 
      ON category_discount(discount_id)
    ''');
  }

  // ============================================================================
  // DISCOUNT RELATED INDEXES
  // ============================================================================

  static Future<void> _createDiscountIndexes(DatabaseExecutor db) async {
    // Discounts table doesn't require direct indexes
    // Indexes on discount_items and discount_outlets handle the relationship filtering
  }

  static Future<void> _createDiscountItemIndexes(DatabaseExecutor db) async {
    // Primary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_discount_items_discount_id 
      ON discount_item(discount_id)
    ''');

    // Secondary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_discount_items_item_id 
      ON discount_item(item_id)
    ''');
  }

  static Future<void> _createDiscountOutletIndexes(DatabaseExecutor db) async {
    // Primary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_discount_outlets_discount_id 
      ON discount_outlet(discount_id)
    ''');

    // Secondary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_discount_outlets_outlet_id 
      ON discount_outlet(outlet_id)
    ''');
  }

  // ============================================================================
  // TAX RELATED INDEXES
  // ============================================================================

  static Future<void> _createTaxIndexes(DatabaseExecutor db) async {
    // Taxes table doesn't require indexes as it has no foreign keys
    // Indexes on outlet_taxes handle the relationship filtering
  }

  static Future<void> _createOutletTaxIndexes(DatabaseExecutor db) async {
    // Primary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_outlet_taxes_outlet_id 
      ON outlet_tax(outlet_id)
    ''');

    // Secondary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_outlet_taxes_tax_id 
      ON outlet_tax(tax_id)
    ''');
  }

  static Future<void> _createOrderOptionTaxIndexes(DatabaseExecutor db) async {
    // Primary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_order_option_taxes_order_option_id 
      ON order_option_tax(order_option_id)
    ''');

    // Secondary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_order_option_taxes_tax_id 
      ON order_option_tax(tax_id)
    ''');
  }

  // ============================================================================
  // OUTLET RELATED INDEXES
  // ============================================================================

  static Future<void> _createOutletIndexes(DatabaseExecutor db) async {
    // Filter outlets by company
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_outlets_company_id 
      ON outlets(company_id)
    ''');
  }

  static Future<void> _createOutletPaymentTypeIndexes(
    DatabaseExecutor db,
  ) async {
    // Primary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_outlet_payment_types_outlet_id 
      ON outlet_payment_type(outlet_id)
    ''');

    // Secondary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_outlet_payment_types_payment_type_id 
      ON outlet_payment_type(payment_type_id)
    ''');
  }

  // ============================================================================
  // MODIFIER INDEXES
  // ============================================================================

  static Future<void> _createModifierIndexes(DatabaseExecutor db) async {
    // Modifiers table doesn't require direct indexes
    // Indexes on modifier_options and item_modifiers handle the relationship filtering
  }

  static Future<void> _createModifierOptionIndexes(DatabaseExecutor db) async {
    // Primary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_modifier_options_modifier_id 
      ON modifier_options(modifier_id)
    ''');
  }

  // ============================================================================
  // ORDER OPTION INDEXES
  // ============================================================================

  static Future<void> _createOrderOptionIndexes(DatabaseExecutor db) async {
    // Filter options by outlet
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_order_options_outlet_id 
      ON order_options(outlet_id)
    ''');
  }

  // ============================================================================
  // PAGE INDEXES
  // ============================================================================

  static Future<void> _createPageIndexes(DatabaseExecutor db) async {
    // Filter pages by outlet
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_pages_outlet_id 
      ON pages(outlet_id)
    ''');
  }

  static Future<void> _createPageItemIndexes(DatabaseExecutor db) async {
    // Primary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_page_items_page_id 
      ON page_items(page_id)
    ''');

    // Index for polymorphic relationship lookups
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_page_items_page_itemable_id 
      ON page_items(page_itemable_id)
    ''');
  }

  // ============================================================================
  // PAYMENT INDEXES
  // ============================================================================

  static Future<void> _createPaymentTypeIndexes(DatabaseExecutor db) async {
    // Payment types are linked to outlets through outlet_payment_types relationship
    // No direct indexes needed on payment_types table
  }

  // ============================================================================
  // RECEIPT INDEXES
  // ============================================================================

  static Future<void> _createReceiptIndexes(DatabaseExecutor db) async {
    // Filter receipts by outlet
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_receipts_outlet_id 
      ON receipts(outlet_id)
    ''');
  }

  static Future<void> _createReceiptItemIndexes(DatabaseExecutor db) async {
    // Primary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_receipt_items_receipt_id 
      ON receipt_items(receipt_id)
    ''');
  }

  // ============================================================================
  // CUSTOMER INDEXES
  // ============================================================================

  static Future<void> _createCustomerIndexes(DatabaseExecutor db) async {
    // Filter customers by company
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_customers_company_id 
      ON customers(company_id)
    ''');
  }

  // ============================================================================
  // PENDING CHANGES INDEXES (CRITICAL FOR SYNC PERFORMANCE)
  // ============================================================================

  static Future<void> _createPendingChangesIndexes(DatabaseExecutor db) async {
    // Find changes by model type
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_pending_changes_model_name 
      ON pending_changes(model_name)
    ''');

    // For cleanup - find old pending changes
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_pending_changes_created_at 
      ON pending_changes(created_at)
    ''');

    // Index for lookup by model_id
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_pending_changes_model_id 
      ON pending_changes(model_id)
    ''');
  }

  // ============================================================================
  // STAFF AND USER INDEXES
  // ============================================================================

  static Future<void> _createStaffIndexes(DatabaseExecutor db) async {
    // Filter staff by company
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_staff_company_id 
      ON staffs(company_id)
    ''');
  }

  static Future<void> _createUserIndexes(DatabaseExecutor db) async {
    // Users table has no foreign keys that require indexing
    // Columns: id, name, email, phone_no, pos_permissions, access_token, password, created_at, updated_at
    // No indexes needed as users are typically accessed by id (primary key)
  }

  // ============================================================================
  // TABLE AND SHIFT INDEXES
  // ============================================================================

  static Future<void> _createTableIndexes(DatabaseExecutor db) async {
    // Filter tables by outlet
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_tables_outlet_id 
      ON tables(outlet_id)
    ''');

    // Filter tables by section
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_tables_table_section_id 
      ON tables(table_section_id)
    ''');
  }

  static Future<void> _createTableSectionIndexes(DatabaseExecutor db) async {
    // Filter sections by outlet
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_table_sections_outlet_id 
      ON table_sections(outlet_id)
    ''');
  }

  static Future<void> _createShiftIndexes(DatabaseExecutor db) async {
    // Filter shifts by outlet
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_shifts_outlet_id 
      ON shifts(outlet_id)
    ''');

    // Shifts table uses opened_by and closed_by (text IDs), not staff_id
    // No additional staff filtering index needed as outlet_id is the primary filter
  }

  // ============================================================================
  // INVENTORY INDEXES
  // ============================================================================

  static Future<void> _createInventoryIndexes(DatabaseExecutor db) async {
    // Filter inventory by company
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_inventories_company_id 
      ON inventories(company_id)
    ''');

    // Filter inventory by category
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_inventories_category_id 
      ON inventories(category_id)
    ''');
  }

  static Future<void> _createInventoryTransactionIndexes(
    DatabaseExecutor db,
  ) async {
    // Primary foreign key
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_inventory_transactions_inventory_id 
      ON inventory_transactions(inventory_id)
    ''');

    // Filter by company
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_inventory_transactions_company_id 
      ON inventory_transactions(company_id)
    ''');

    // Filter by type (in, out, adjustment)
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_inventory_transactions_type 
      ON inventory_transactions(type)
    ''');
  }

  // ============================================================================
  // PREDEFINED ORDERS INDEXES
  // ============================================================================

  static Future<void> _createPredefinedOrderIndexes(DatabaseExecutor db) async {
    // Filter by outlet
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_predefined_orders_outlet_id 
      ON predefined_orders(outlet_id)
    ''');
  }

  // ============================================================================
  // PRINTER INDEXES
  // ============================================================================

  static Future<void> _createPrinterSettingIndexes(DatabaseExecutor db) async {
    // Filter by outlet
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_printer_settings_outlet_id 
      ON printer_settings(outlet_id)
    ''');
  }

  static Future<void> _createDepartmentPrinterIndexes(
    DatabaseExecutor db,
  ) async {
    // Filter by company
    await _safeCreateIndex(db, '''
      CREATE INDEX IF NOT EXISTS idx_department_printers_company_id 
      ON department_printers(company_id)
    ''');
  }
}
