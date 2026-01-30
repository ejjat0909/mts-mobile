import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/models/cash_management/cash_management_model.dart';
import 'package:mts/data/models/category/category_model.dart';
import 'package:mts/data/models/category_discount/category_discount_model.dart';
import 'package:mts/data/models/category_tax/category_tax_model.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';
import 'package:mts/data/models/discount/discount_model.dart';
import 'package:mts/data/models/discount_item/discount_item_model.dart';
import 'package:mts/data/models/discount_outlet/discount_outlet_model.dart';
import 'package:mts/data/models/feature/feature_company_model.dart';
import 'package:mts/data/models/feature/feature_model.dart';
import 'package:mts/data/models/inventory/inventory_model.dart';
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
import 'package:mts/data/models/pos_device/pos_device_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_model.dart';
import 'package:mts/data/models/printer_setting/printer_settings_model.dart';
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
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/models/table_layout/table_layout_model.dart';
import 'package:mts/data/models/table_section/table_section_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/data/models/timecard/timecard_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/data/services/sync/sync_handler.dart';

// Import all handler files with providers
import 'package:mts/data/services/sync/category_discount_sync_handler.dart';
import 'package:mts/data/services/sync/category_sync_handler.dart';
import 'package:mts/data/services/sync/category_tax_sync_handler.dart';
import 'package:mts/data/services/sync/customer_sync_handler.dart';
import 'package:mts/data/services/sync/feature_company_sync_handler.dart';
import 'package:mts/data/services/sync/item_modifier_sync_handler.dart';
import 'package:mts/data/services/sync/item_sync_handler.dart';
import 'package:mts/data/services/sync/modifier_option_sync_handler.dart';
import 'package:mts/data/services/sync/modifier_sync_handler.dart';
import 'package:mts/data/services/sync/order_option_tax_sync_handler.dart';
import 'package:mts/data/services/sync/staff_sync_handler.dart';
import 'package:mts/data/services/sync/receipt_setting_sync_handler.dart';
import 'package:mts/data/services/sync/slideshow_sync_handler.dart';
import 'package:mts/data/services/sync/item_representation_sync_handler.dart';

// Import handlers that don't have providers yet (temporary - will be migrated)
import 'package:mts/data/services/sync/device_sync_handler.dart';
import 'package:mts/data/services/sync/cash_management_sync_handler.dart';
import 'package:mts/data/services/sync/department_printer_sync_handler.dart';
import 'package:mts/data/services/sync/discount_item_sync_handler.dart';
import 'package:mts/data/services/sync/discount_outlet_sync_handler.dart';
import 'package:mts/data/services/sync/discount_sync_handler.dart';
import 'package:mts/data/services/sync/feature_sync_handler.dart';
import 'package:mts/data/services/sync/inventory_sync_handler.dart';
import 'package:mts/data/services/sync/inventory_transaction_sync_handler.dart';
import 'package:mts/data/services/sync/item_representation_sync_handler.dart';
import 'package:mts/data/services/sync/item_tax_sync_handler.dart';
import 'package:mts/data/services/sync/order_option_sync_handler.dart';
import 'package:mts/data/services/sync/outlet_payment_type_sync_handler.dart';
import 'package:mts/data/services/sync/outlet_sync_handler.dart';
import 'package:mts/data/services/sync/outlet_tax_sync_handler.dart';
import 'package:mts/data/services/sync/page_item_sync_handler.dart';
import 'package:mts/data/services/sync/page_sync_handler.dart';
import 'package:mts/data/services/sync/payment_type_sync_handler.dart';
import 'package:mts/data/services/sync/predefined_order_sync_handler.dart';
import 'package:mts/data/services/sync/print_receipt_cache_sync_handler.dart';
import 'package:mts/data/services/sync/printer_setting_sync_handler.dart';
import 'package:mts/data/services/sync/receipt_item_sync_handler.dart';
import 'package:mts/data/services/sync/receipt_setting_sync_handler.dart';
import 'package:mts/data/services/sync/receipt_sync_handler.dart';
import 'package:mts/data/services/sync/sale_item_sync_handler.dart';
import 'package:mts/data/services/sync/sale_modifier_option_sync_handler.dart';
import 'package:mts/data/services/sync/sale_modifier_sync_handler.dart';
import 'package:mts/data/services/sync/sale_sync_handler.dart';
import 'package:mts/data/services/sync/sale_variant_option_sync_handler.dart';
import 'package:mts/data/services/sync/shift_sync_handler.dart';
import 'package:mts/data/services/sync/slideshow_sync_handler.dart';
import 'package:mts/data/services/sync/table_layout_sync_handler.dart';
import 'package:mts/data/services/sync/table_section_sync_handler.dart';
import 'package:mts/data/services/sync/table_sync_handler.dart';
import 'package:mts/data/services/sync/tax_sync_handler.dart';
import 'package:mts/data/services/sync/timecard_sync_handler.dart';
import 'package:mts/data/services/sync/user_sync_handler.dart';
import 'package:mts/domain/services/media/asset_download_service.dart';

/// Central map of all sync handlers - Replaces SyncHandlerRegistry singleton
///
/// This provider creates a map of model names to their sync handlers using
/// pure Riverpod dependency injection. No ServiceLocator, no singleton pattern.
///
/// Handlers with providers (fully migrated):
/// - Use ref.read(handlerProvider)
///
/// Handlers without providers yet (temporary):
/// - Create directly with ServiceLocator fallbacks
/// - These will be migrated incrementally
///
/// Usage:
/// ```dart
/// final handler = ref.read(syncHandlerProvider(ItemModel.modelName));
/// await handler?.handleCreated(data);
/// ```
final syncHandlersMapProvider = Provider<Map<String, SyncHandler>>((ref) {
  // Get AssetDownloadService for handlers that need it
  final assetDownloadService = ref.read(assetDownloadServiceProvider);

  return {
    // ✅ Handlers with providers (fully migrated - no ServiceLocator)
    ItemModel.modelName: ref.read(itemSyncHandlerProvider),
    CategoryModel.modelName: ref.read(categorySyncHandlerProvider),
    CustomerModel.modelName: ref.read(customerSyncHandlerProvider),
    StaffModel.modelName: ref.read(staffSyncHandlerProvider),
    ModifierModel.modelName: ref.read(modifierSyncHandlerProvider),
    ModifierOptionModel.modelName: ref.read(modifierOptionSyncHandlerProvider),
    CategoryDiscountModel.modelName: ref.read(
      categoryDiscountSyncHandlerProvider,
    ),
    CategoryTaxModel.modelName: ref.read(categoryTaxSyncHandlerProvider),
    FeatureCompanyModel.modelName: ref.read(featureCompanySyncHandlerProvider),
    ReceiptSettingsModel.modelName: ref.read(receiptSettingSyncHandlerProvider),
    SlideshowModel.modelName: ref.read(slideshowSyncHandlerProvider),
    ItemRepresentationModel.modelName: ref.read(
      itemRepresentationSyncHandlerProvider,
    ),

    // ⏳ Handlers without providers yet (temporary - uses ServiceLocator)
    // These will be migrated to providers incrementally
    PosDeviceModel.modelName: DeviceSyncHandler(),
    ItemModifierModel.modelName: ItemModifierSyncHandler(),
    OrderOptionTaxModel.modelName: OrderOptionTaxSyncHandler(),
    CashManagementModel.modelName: CashManagementSyncHandler(),
    DepartmentPrinterModel.modelName: DepartmentPrinterSyncHandler(),
    DiscountModel.modelName: DiscountSyncHandler(),
    DiscountItemModel.modelName: DiscountItemSyncHandler(),
    DiscountOutletModel.modelName: DiscountOutletSyncHandler(),
    FeatureModel.modelName: FeatureSyncHandler(),
    InventoryModel.modelName: InventorySyncHandler(),
    InventoryTransactionModel.modelName: InventoryTransactionSyncHandler(),
    ItemTaxModel.modelName: ItemTaxSyncHandler(),
    OutletPaymentTypeModel.modelName: OutletPaymentTypeSyncHandler(),
    OutletTaxModel.modelName: OutletTaxSyncHandler(),
    OrderOptionModel.modelName: OrderOptionSyncHandler(),
    OutletModel.modelName: OutletSyncHandler(),
    PageModel.modelName: PageSyncHandler(),
    PageItemModel.modelName: PageItemSyncHandler(),
    PaymentTypeModel.modelName: PaymentTypeSyncHandler(),
    PredefinedOrderModel.modelName: PredefinedOrderSyncHandler(),
    PrinterSettingModel.modelName: PrinterSettingSyncHandler(),
    PrintReceiptCacheModel.modelName: PrintReceiptCacheSyncHandler(),
    ReceiptModel.modelName: ReceiptSyncHandler(),
    ReceiptItemModel.modelName: ReceiptItemSyncHandler(),
    SaleItemModel.modelName: SaleItemSyncHandler(),
    SaleModel.modelName: SaleSyncHandler(),
    SaleModifierModel.modelName: SaleModifierSyncHandler(),
    SaleModifierOptionModel.modelName: SaleModifierOptionSyncHandler(),
    SaleVariantOptionModel.modelName: SaleVariantOptionSyncHandler(),
    ShiftModel.modelName: ShiftSyncHandler(),
    TableModel.modelName: TableSyncHandler(),
    TableLayoutModel.modelName: TableLayoutSyncHandler(),
    TableSectionModel.modelName: TableSectionSyncHandler(),
    TaxModel.modelName: TaxSyncHandler(),
    TimecardModel.modelName: TimecardSyncHandler(),
    UserModel.modelName: UserSyncHandler(),
  };
});

/// Family provider to get a sync handler by model name
///
/// This is the main provider to use throughout the app.
/// Replaces: `SyncHandlerRegistry().getHandler(modelName)`
///
/// Usage:
/// ```dart
/// final handler = ref.read(syncHandlerProvider(ItemModel.modelName));
/// if (handler != null) {
///   await handler.handleCreated(data);
/// }
/// ```
final syncHandlerProvider = Provider.family<SyncHandler?, String>((
  ref,
  modelName,
) {
  return ref.read(syncHandlersMapProvider)[modelName];
});
