import 'package:hive_flutter/hive_flutter.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/cash_drawer_log/cash_drawer_log_model.dart';
import 'package:mts/data/models/cash_management/cash_management_model.dart';
import 'package:mts/data/models/category/category_model.dart';
import 'package:mts/data/models/category_discount/category_discount_model.dart';
import 'package:mts/data/models/category_tax/category_tax_model.dart';
import 'package:mts/data/models/city/city_model.dart';
import 'package:mts/data/models/country/country_model.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/data/models/deleted_sale_item/deleted_sale_item_model.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';
import 'package:mts/data/models/discount/discount_model.dart';
import 'package:mts/data/models/discount_item/discount_item_model.dart';
import 'package:mts/data/models/discount_outlet/discount_outlet_model.dart';
import 'package:mts/data/models/division/division_model.dart';
import 'package:mts/data/models/downloaded_file/downloaded_file_model.dart';
import 'package:mts/data/models/error_log/error_log_model.dart';
import 'package:mts/data/models/feature/feature_model.dart';
import 'package:mts/data/models/feature/feature_company_model.dart';
import 'package:mts/data/models/inventory/inventory_model.dart';
import 'package:mts/data/models/inventory_outlet/inventory_outlet_model.dart';
import 'package:mts/data/models/inventory_transaction/inventory_transaction_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/item_modifier/item_modifier_model.dart';
import 'package:mts/data/models/item_representation/item_representation_model.dart';
import 'package:mts/data/models/item_tax/item_tax_model.dart';
import 'package:mts/data/models/modifier/modifier_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/order_option_tax/order_option_tax_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/outlet_payment_type/outlet_payment_type_model.dart';
import 'package:mts/data/models/outlet_tax/outlet_tax_model.dart';
import 'package:mts/data/models/page/page_model.dart';
import 'package:mts/data/models/page_item/page_item_model.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/data/models/permission/permission_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/models/printing_log/printing_log_model.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:mts/data/models/receipt_setting/receipt_settings_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/sale_variant_option/sale_variant_option_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/supplier/supplier_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/models/table_section/table_section_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/data/models/time_card/timecard_model.dart';
import 'package:mts/data/models/user/user_model.dart';

/// ================================
/// SINGLE SOURCE OF TRUTH FOR ALL HIVE BOXES
/// ================================
///
/// This manager provides:
/// 1. Single list of all box names (no duplication)
/// 2. Centralized initialization
/// 3. Runtime validation
/// 4. Generic provider factory
///
/// Benefits:
/// - Add a new model? Just add modelBoxName to the list below
/// - Automatic validation ensures no missing boxes
/// - No need to manually create providers
/// - Compile-time safety with type checking
class HiveBoxManager {
  /// ================================
  /// SINGLE SOURCE OF TRUTH
  /// Add new models here ONLY - everything else is automatic
  /// ================================
  static final List<String> allBoxNames = [
    // Core business models
    CustomerModel.modelBoxName,
    ItemModel.modelBoxName,
    ItemRepresentationModel.modelBoxName,
    ItemModifierModel.modelBoxName,
    ItemTaxModel.modelBoxName,
    SaleModel.modelBoxName,
    SaleItemModel.modelBoxName,
    SaleModifierModel.modelBoxName,
    SaleModifierOptionModel.modelBoxName,
    SaleVariantOptionModel.modelBoxName,

    // Category & Organization
    CategoryModel.modelBoxName,
    CategoryTaxModel.modelBoxName,
    CategoryDiscountModel.modelBoxName,
    StaffModel.modelBoxName,
    UserModel.modelBoxName,
    SupplierModel.modelBoxName,

    // Pricing & Payments
    PaymentTypeModel.modelBoxName,
    DiscountModel.modelBoxName,
    DiscountItemModel.modelBoxName,
    DiscountOutletModel.modelBoxName,
    TaxModel.modelBoxName,
    OutletTaxModel.modelBoxName,
    OutletPaymentTypeModel.modelBoxName,

    // Configuration Models
    ModifierModel.modelBoxName,
    ModifierOptionModel.modelBoxName,
    OrderOptionModel.modelBoxName,
    OrderOptionTaxModel.modelBoxName,
    PermissionModel.modelBoxName,

    // Outlet & Locations
    OutletModel.modelBoxName,
    PosDeviceModel.modelBoxName,

    // Display & Pages
    PageModel.modelBoxName,
    PageItemModel.modelBoxName,
    SlideshowModel.modelBoxName,

    // Receipt & Printing
    ReceiptModel.modelBoxName,
    ReceiptItemModel.modelBoxName,
    ReceiptSettingsModel.modelBoxName,
    PrinterSettingModel.modelBoxName,
    DepartmentPrinterModel.modelBoxName,
    PrintingLogModel.modelBoxName,
    PrintReceiptCacheModel.modelBoxName,

    // Shift Management
    ShiftModel.modelBoxName,
    TimecardModel.modelBoxName,

    // Tables
    TableModel.modelBoxName,
    TableSectionModel.modelBoxName,

    // Inventory
    InventoryModel.modelBoxName,
    InventoryOutletModel.modelBoxName,
    InventoryTransactionModel.modelBoxName,

    // Predefined Orders
    PredefinedOrderModel.modelBoxName,

    // Geography
    CountryModel.modelBoxName,
    CityModel.modelBoxName,
    DivisionModel.modelBoxName,

    // System & Features
    FeatureModel.modelBoxName,
    FeatureCompanyModel.modelBoxName,
    DeletedSaleItemModel.modelBoxName,

    // Utility Models
    CashManagementModel.modelBoxName,
    CashDrawerLogModel.modelBoxName,
    DownloadedFileModel.modelBoxName,
    ErrorLogModel.modelBoxName,
    PendingChangesModel.modelBoxName,
  ];

  /// ================================
  /// INITIALIZATION (Call in main.dart)
  /// ================================
  static Future<void> initializeAllBoxes() async {
    try {
      prints('Starting Hive box initialization...');

      // Open all boxes
      await Future.wait(allBoxNames.map((name) => _openBox(name)));

      prints(
        '✅ Hive initialization complete. Opened ${allBoxNames.length} boxes',
      );

      // Validate in debug mode
      assert(() {
        validateAllBoxes();
        return true;
      }());
    } catch (e) {
      prints('❌ Error initializing Hive boxes: $e');
      rethrow;
    }
  }

  /// Open a single box with error handling
  static Future<void> _openBox(String boxName) async {
    try {
      final box = await Hive.openBox<Map>(boxName);
      prints('  ✓ Opened: $boxName (${box.length} entries)');
    } catch (e) {
      prints('  ⚠ Already open: $boxName');
    }
  }

  /// ================================
  /// RUNTIME VALIDATION
  /// ================================
  /// Checks that all boxes are properly opened
  /// Call this in debug mode after initialization
  static void validateAllBoxes() {
    final notOpen = <String>[];

    for (final boxName in allBoxNames) {
      if (!Hive.isBoxOpen(boxName)) {
        notOpen.add(boxName);
      }
    }

    if (notOpen.isNotEmpty) {
      final errorMsg = '''
❌ HIVE BOX VALIDATION FAILED!
The following boxes are NOT open:
${notOpen.map((name) => '  - $name').join('\n')}

This means:
1. Box might not be in HiveBoxManager.allBoxNames list
2. Box failed to open in initializeAllBoxes()
3. Box was closed prematurely

Fix: Ensure all boxes are in HiveBoxManager.allBoxNames and initialized in main.dart
''';
      prints(errorMsg);
      throw StateError(errorMsg);
    }

    prints('✅ All ${allBoxNames.length} Hive boxes validated successfully');
  }

  /// ================================
  /// SAFE BOX ACCESS WITH VALIDATION
  /// ================================
  /// Get a box with automatic validation
  /// Use this inside provider definitions
  ///
  /// Example:
  /// ```dart
  /// final myBoxProvider = Provider<Box<Map>>((ref) {
  ///   return HiveBoxManager.getValidatedBox(MyModel.modelBoxName);
  /// });
  /// ```
  static Box<Map> getValidatedBox(String boxName) {
    // Validate box is in our registry
    if (!allBoxNames.contains(boxName)) {
      throw StateError(
        '❌ Box "$boxName" not found in HiveBoxManager.allBoxNames.\n'
        'Fix: Add "$boxName" to HiveBoxManager.allBoxNames list first!',
      );
    }

    // Validate box is open
    if (!Hive.isBoxOpen(boxName)) {
      throw StateError(
        '❌ Box "$boxName" is not open.\n'
        'Fix: Ensure HiveBoxManager.initializeAllBoxes() is called in main.dart before using providers.',
      );
    }

    return Hive.box<Map>(boxName);
  }

  /// ================================
  /// DIRECT BOX ACCESS (for non-Riverpod code)
  /// ================================
  /// Get a box directly with validation
  /// Use this if you can't use Riverpod providers
  static Box<Map> getBox(String boxName) {
    // Validate box is in registry
    if (!allBoxNames.contains(boxName)) {
      throw StateError(
        'Box "$boxName" not found in HiveBoxManager.allBoxNames',
      );
    }

    // Validate box is open
    if (!Hive.isBoxOpen(boxName)) {
      throw StateError(
        'Box "$boxName" is not open. Call HiveBoxManager.initializeAllBoxes() first',
      );
    }

    return Hive.box<Map>(boxName);
  }

  /// ================================
  /// CLEANUP
  /// ================================
  static Future<void> closeAllBoxes() async {
    try {
      prints('Closing all Hive boxes...');
      await Hive.close();
      prints('✅ All Hive boxes closed');
    } catch (e) {
      prints('❌ Error closing Hive boxes: $e');
    }
  }

  /// Clear all box contents (use on logout)
  static Future<void> clearAllBoxes() async {
    try {
      prints('Clearing all Hive boxes...');

      for (final boxName in allBoxNames) {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box<Map>(boxName);
          await box.clear();
          prints('  ✓ Cleared: $boxName');
        }
      }

      prints('✅ All Hive boxes cleared');
    } catch (e) {
      prints('❌ Error clearing Hive boxes: $e');
    }
  }

  /// Get statistics about all boxes
  static Map<String, int> getBoxStatistics() {
    final stats = <String, int>{};

    for (final boxName in allBoxNames) {
      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box<Map>(boxName);
        stats[boxName] = box.length;
      } else {
        stats[boxName] = -1; // -1 indicates box not open
      }
    }

    return stats;
  }
}

/// ================================
/// RECOMMENDED USAGE PATTERN
/// ================================
///
/// Step 1: Define box provider as top-level final (Riverpod best practice)
/// Step 2: Use in your repository
///
/// Example:
/// ```dart
/// // At top of your repository file:
/// final cashDrawerLogBoxProvider = Provider<Box<Map>>((ref) {
///   return HiveBoxManager.getValidatedBox(CashDrawerLogModel.modelBoxName);
/// });
///
/// // Use in repository provider:
/// final cashDrawerLogLocalRepoProvider = Provider<CashDrawerLogRepository>((ref) {
///   return LocalCashDrawerLogRepositoryImpl(
///     dbHelper: ref.read(databaseHelpersProvider),
///     pendingChangesRepository: ref.read(pendingChangesLocalRepoProvider),
///     hiveBox: ref.read(cashDrawerLogBoxProvider), // ✅ Top-level provider
///   );
/// });
/// ```
///
/// Benefits:
/// ✅ Follows Riverpod best practices (top-level providers)
/// ✅ Single source of truth (HiveBoxManager.allBoxNames)
/// ✅ Automatic validation with clear error messages
/// ✅ Proper provider caching and disposal
/// ✅ Easy to test (override providers in tests)
///
/// Maintenance:
/// - Add new model → Only update HiveBoxManager.allBoxNames
/// - Create box provider → One-liner using getValidatedBox()
/// - Validation is automatic on first access
