import 'package:mts/data/models/feature/feature_company_model.dart';
import 'package:mts/data/models/inventory_outlet/inventory_outlet_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/item_representation/item_representation_model.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_model.dart';
import 'package:mts/data/models/receipt_setting/receipt_settings_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/data/models/modifier/modifier_model.dart';
import 'package:mts/data/models/item_tax/item_tax_model.dart';
import 'package:mts/data/models/item_modifier/item_modifier_model.dart';
import 'package:mts/data/models/discount/discount_model.dart';
import 'package:mts/data/models/discount_item/discount_item_model.dart';
import 'package:mts/data/models/discount_outlet/discount_outlet_model.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/data/models/time_card/timecard_model.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:mts/data/models/page/page_model.dart';
import 'package:mts/data/models/page_item/page_item_model.dart';
import 'package:mts/data/models/category/category_model.dart';
import 'package:mts/data/models/category_discount/category_discount_model.dart';
import 'package:mts/data/models/category_tax/category_tax_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_variant_option/sale_variant_option_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/cash_management/cash_management_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/order_option_tax/order_option_tax_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/outlet_tax/outlet_tax_model.dart';
import 'package:mts/data/models/outlet_payment_type/outlet_payment_type_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/data/models/table_section/table_section_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/models/feature/feature_model.dart';
import 'package:mts/data/models/city/city_model.dart';
import 'package:mts/data/models/country/country_model.dart';
import 'package:mts/data/models/division/division_model.dart';
import 'package:mts/data/models/inventory/inventory_model.dart';
import 'package:mts/data/models/inventory_transaction/inventory_transaction_model.dart';
import 'package:mts/data/models/permission/permission_model.dart';
import 'package:mts/data/models/supplier/supplier_model.dart';
import 'package:mts/data/models/printing_log/printing_log_model.dart';
import 'package:mts/data/models/cash_drawer_log/cash_drawer_log_model.dart';
import 'package:mts/data/models/deleted_sale_item/deleted_sale_item_model.dart';

class SSKey {
  /// [SSKey = Secured Storage Key]
  // static const String itemMeta = 'item_meta';
  // static const String itemRepresentationMeta = 'item_representation_meta';
  // static const String taxMeta = 'tax_meta';
  // static const String modifierMeta = 'modifier_meta';
  // static const String itemTaxMeta = 'item_tax_meta';
  // static const String itemModifierMeta = 'item_modifier_meta';
  // static const String discountMeta = 'discount_meta';
  // static const String discountItemMeta = 'discount_item_meta';
  // static const String variantOptionMeta = 'variant_option_meta';
  // static const String receiptSettingMeta = 'receipt_setting_meta';
  // static const String paymentTypeMeta = 'payment_type_meta';
  // static const String timecardMeta = 'time_card_meta';
  // static const String receiptMeta = 'receipt_meta';
  // static const String receiptItemMeta = 'receipt_item_meta';
  // static const String pageMeta = 'page_meta';
  // static const String pageItemMeta = 'page_item_meta';
  // static const String categoryMeta = 'category_meta';
  // static const String categoryDiscountMeta = 'category_discount_meta';
  // static const String categoryTaxMeta = 'category_tax_meta';
  // static const String staffMeta = 'staff_meta';
  // static const String customerMeta = 'customer_meta';
  // static const String departmentPrinterMeta = 'department_printer_meta';
  // static const String modifierOptionMeta = 'modifier_option_meta';
  // static const String shiftMeta = 'shift_meta';
  // static const String saleModifierMeta = 'sale_modifier_meta';
  // static const String saleModifierOptionMeta = 'sale_modifier_option_meta';
  // static const String saleItemMeta = 'sale_item_meta';
  // static const String saleMeta = 'sale_meta';
  // static const String cashManagementMeta = 'cash_management_meta';
  // static const String deviceMeta = 'device_meta';
  // static const String orderOptionMeta = 'order_option_meta';
  // static const String orderOptionTaxMeta = 'order_option_tax_meta';
  // static const String outletMeta = 'outlet_meta';
  // static const String outletTaxMeta = 'outlet_tax_meta';
  // static const String outletPaymentTypeMeta = 'outlet_payment_type_meta';
  // static const String printerSettingMeta = 'printer_setting_meta';
  // static const String refundMeta = 'refund_meta';
  // static const String slideshowMeta = 'slide_show_meta';
  // static const String splitOrderMeta = 'split_order_meta';
  // static const String splitPaymentMeta = 'split_payment_meta';
  // static const String tableLayoutMeta = 'table_layout_meta';
  // static const String tableSectionMeta = 'table_section_meta';
  // static const String userMeta = 'user_meta';
  // static const String predefinedOrderMeta = 'predefined_order_meta';
  // static const String tableMeta = 'table_meta';
  // static const String syncAllDataMeta = 'sync_all_data_meta';

  /// [DONT FORGRT TO ADD NEW KEY INTO THIS LIST]
  static const List<String> allKeys = [
    // Downloaded files
    // DownloadedFileModel.modelName,
    // Error logs
    // ErrorLogModel.modelName,

    // Cash management
    CashManagementModel.modelName,
    // Features
    FeatureModel.modelName,
    FeatureCompanyModel.modelName,
    // Categories
    CategoryModel.modelName,
    CategoryTaxModel.modelName,
    CategoryDiscountModel.modelName,
    // Cities
    CityModel.modelName,
    // Countries
    CountryModel.modelName,
    // Divisions
    DivisionModel.modelName,
    // Customers
    CustomerModel.modelName,
    // Discounts
    DiscountModel.modelName,
    DiscountItemModel.modelName,
    DiscountOutletModel.modelName,
    // Items and related
    ItemModel.modelName,
    ItemRepresentationModel.modelName,
    ItemTaxModel.modelName,
    OrderOptionTaxModel.modelName,
    ItemModifierModel.modelName,
    // Inventory
    InventoryModel.modelName,
    InventoryTransactionModel.modelName,
    InventoryOutletModel.modelName,
    // Outlet related
    OutletTaxModel.modelName,
    OutletPaymentTypeModel.modelName,
    // Modifiers
    ModifierModel.modelName,
    ModifierOptionModel.modelName,
    // Order options
    OrderOptionModel.modelName,
    // Pages
    PageModel.modelName,
    PageItemModel.modelName,
    // Payments
    PaymentTypeModel.modelName,
    // Predefined orders
    PredefinedOrderModel.modelName,
    // Printers
    PrinterSettingModel.modelName,
    DepartmentPrinterModel.modelName,
    // Receipts
    ReceiptModel.modelName,
    ReceiptItemModel.modelName,
    ReceiptSettingsModel.modelName,
    // Sales
    SaleModel.modelName,
    SaleItemModel.modelName,
    SaleModifierModel.modelName,
    SaleModifierOptionModel.modelName,
    SaleVariantOptionModel.modelName,
    // Staff and users
    StaffModel.modelName,
    UserModel.modelName,
    PermissionModel.modelName,
    // Taxes
    TaxModel.modelName,
    // Outlet and devices
    OutletModel.modelName,
    PosDeviceModel.modelName,
    // Shifts and timecards
    ShiftModel.modelName,
    TimecardModel.modelName,
    // Display
    SlideshowModel.modelName,
    // Tables
    TableModel.modelName,
    TableSectionModel.modelName,
    // Suppliers
    SupplierModel.modelName,
    // Printing logs
    PrintingLogModel.modelName,
    // Cash drawer logs
    CashDrawerLogModel.modelName,
    // Deleted sale items
    DeletedSaleItemModel.modelName,

    // Variant options
    // VariantOptionModel.modelName,
    PrintReceiptCacheModel.modelName,
  ];
}
