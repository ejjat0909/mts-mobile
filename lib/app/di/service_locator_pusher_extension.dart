import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/services/sync/category_sync_handler.dart';
import 'package:mts/data/services/sync/customer_sync_handler.dart';
import 'package:mts/data/services/sync/device_sync_handler.dart';
import 'package:mts/data/services/sync/discount_sync_handler.dart';
import 'package:mts/data/services/sync/item_sync_handler.dart';
import 'package:mts/data/services/sync/modifier_sync_handler.dart';
import 'package:mts/data/services/sync/order_option_sync_handler.dart';
import 'package:mts/data/services/sync/order_option_tax_sync_handler.dart';
import 'package:mts/data/services/sync/outlet_sync_handler.dart';
import 'package:mts/data/services/sync/page_item_sync_handler.dart';
import 'package:mts/data/services/sync/payment_type_sync_handler.dart';
import 'package:mts/data/services/sync/print_receipt_cache_sync_handler.dart';
import 'package:mts/data/services/sync/printer_setting_sync_handler.dart';
import 'package:mts/data/services/sync/receipt_sync_handler.dart';
import 'package:mts/data/services/sync/sale_item_sync_handler.dart';
import 'package:mts/data/services/sync/sale_sync_handler.dart';
import 'package:mts/data/services/sync/shift_sync_handler.dart';
import 'package:mts/data/services/sync/slideshow_sync_handler.dart';
import 'package:mts/data/services/sync/staff_sync_handler.dart';
import 'package:mts/data/services/sync/tax_sync_handler.dart';
import 'package:mts/data/services/sync/user_sync_handler.dart';

/// Extension for ServiceLocator to register Pusher event handling components
extension ServiceLocatorPusherExtension on ServiceLocator {
  /// Register Pusher event handling components
  static void registerPusherEventHandling() {
    // CategorySyncHandler
    ServiceLocator.registerSingleton<CategorySyncHandler>(
      CategorySyncHandler(),
    );
    // CustomerSyncHandler
    ServiceLocator.registerSingleton<CustomerSyncHandler>(
      CustomerSyncHandler(),
    );
    // DeviceSyncHandler
    ServiceLocator.registerSingleton<DeviceSyncHandler>(DeviceSyncHandler());
    // DiscountSyncHandler
    ServiceLocator.registerSingleton<DiscountSyncHandler>(
      DiscountSyncHandler(),
    );
    // ItemSyncHandler
    ServiceLocator.registerSingleton<ItemSyncHandler>(ItemSyncHandler());
    // ModifierSyncHandlerSyncHandler
    ServiceLocator.registerSingleton<ModifierSyncHandler>(
      ModifierSyncHandler(),
    );
    // OrderOptionSyncHandler
    ServiceLocator.registerSingleton<OrderOptionSyncHandler>(
      OrderOptionSyncHandler(),
    );
    // OrderOptionTaxSyncHandler
    ServiceLocator.registerSingleton<OrderOptionTaxSyncHandler>(
      OrderOptionTaxSyncHandler(),
    );
    // OutletSyncHandler
    ServiceLocator.registerSingleton<OutletSyncHandler>(OutletSyncHandler());
    // PageItemSyncHandler
    ServiceLocator.registerSingleton<PageItemSyncHandler>(
      PageItemSyncHandler(),
    );
    // PaymentSyncHandler
    ServiceLocator.registerSingleton<PaymentTypeSyncHandler>(
      PaymentTypeSyncHandler(),
    );
    // PrinterSettingSyncHandler
    ServiceLocator.registerSingleton<PrinterSettingSyncHandler>(
      PrinterSettingSyncHandler(),
    );
    // PrintReceiptCacheSyncHandler
    ServiceLocator.registerSingleton<PrintReceiptCacheSyncHandler>(
      PrintReceiptCacheSyncHandler(),
    );
    // ReceiptSyncHandler
    ServiceLocator.registerSingleton<ReceiptSyncHandler>(ReceiptSyncHandler());

    // SaleItemSyncHandler
    ServiceLocator.registerSingleton<SaleItemSyncHandler>(
      SaleItemSyncHandler(),
    );
    // SaleSyncHandler
    ServiceLocator.registerSingleton<SaleSyncHandler>(SaleSyncHandler());
    // SecondDisplaySyncHandler
    ServiceLocator.registerSingleton<SlideshowSyncHandler>(
      SlideshowSyncHandler(),
    );
    // ShiftSyncHandler
    ServiceLocator.registerSingleton<ShiftSyncHandler>(ShiftSyncHandler());

    // StaffSyncHandler
    ServiceLocator.registerSingleton<StaffSyncHandler>(StaffSyncHandler());

    // TaxSyncHandler
    ServiceLocator.registerSingleton<TaxSyncHandler>(TaxSyncHandler());
    // UserSyncHandler
    ServiceLocator.registerSingleton<UserSyncHandler>(UserSyncHandler());

    // Note: PusherEventHandler and sync handlers are now managed by Riverpod providers
    // See: pusher_event_handler_provider.dart and sync_handlers_provider.dart
  }
}
