import 'package:mts/core/sync/sync_reason.dart';

class SyncPolicy {
  // Core data
  final bool items;
  final bool categories;
  final bool pages;
  final bool pageItems;
  final bool itemRepresentation;

  // Modifiers
  final bool modifiers;
  final bool itemModifiers;
  final bool modifierOptions;

  // Taxes & Discounts
  final bool taxes;
  final bool itemTaxes;
  final bool categoryTaxes;
  final bool orderOptionTaxes;
  final bool outletTaxes;
  final bool discounts;
  final bool discountItems;
  final bool categoryDiscounts;
  final bool discountOutlets;

  // Tables & Layout
  final bool tableLayout;
  final bool tables;
  final bool tableSections;

  // Orders & Sales
  final bool orderOptions;
  final bool predefinedOrders;
  final bool sales;
  final bool saleItems;
  final bool saleModifiers;
  final bool saleModifierOptions;
  final bool saleVariantOptions;

  // Receipts
  final bool receipts;
  final bool receiptItems;
  final bool receiptSettings;

  // Users & Staff
  final bool users;
  final bool staff;
  final bool customers;
  final bool permissions;

  // Outlets & Devices
  final bool outlets;
  final bool devices;
  final bool printers;
  final bool departmentPrinters;

  // Payment
  final bool paymentTypes;
  final bool outletPaymentTypes;

  // Features & Settings
  final bool features;
  final bool featureCompanies;

  // Cash & Shifts
  final bool cashManagement;
  final bool shifts;
  final bool timecards;

  // Media
  final bool slideshow;
  final bool downloadedFiles;

  // Geography
  final bool cities;
  final bool countries;
  final bool divisions;

  // Inventory
  final bool inventory;
  final bool inventoryTransactions;
  final bool suppliers;

  // Print cache
  final bool printReceiptCache;

  // Deleted items tracking
  final bool deleted;

  // Sync tracking
  final bool pendingChanges;

  SyncPolicy({
    this.items = false,
    this.categories = false,
    this.pages = false,
    this.pageItems = false,
    this.itemRepresentation = false,
    this.modifiers = false,
    this.itemModifiers = false,
    this.modifierOptions = false,
    this.taxes = false,
    this.itemTaxes = false,
    this.categoryTaxes = false,
    this.orderOptionTaxes = false,
    this.outletTaxes = false,
    this.discounts = false,
    this.discountItems = false,
    this.categoryDiscounts = false,
    this.discountOutlets = false,
    this.tableLayout = false,
    this.tables = false,
    this.tableSections = false,
    this.orderOptions = false,
    this.predefinedOrders = false,
    this.sales = false,
    this.saleItems = false,
    this.saleModifiers = false,
    this.saleModifierOptions = false,
    this.saleVariantOptions = false,
    this.receipts = false,
    this.receiptItems = false,
    this.receiptSettings = false,
    this.users = false,
    this.staff = false,
    this.customers = false,
    this.permissions = false,
    this.outlets = false,
    this.devices = false,
    this.printers = false,
    this.departmentPrinters = false,
    this.paymentTypes = false,
    this.outletPaymentTypes = false,
    this.features = false,
    this.featureCompanies = false,
    this.cashManagement = false,
    this.shifts = false,
    this.timecards = false,
    this.slideshow = false,
    this.downloadedFiles = false,
    this.cities = false,
    this.countries = false,
    this.divisions = false,
    this.inventory = false,
    this.inventoryTransactions = false,
    this.suppliers = false,
    this.printReceiptCache = false,
    this.deleted = false,
    this.pendingChanges = false,
  });

  factory SyncPolicy.forReason(SyncReason reason) {
    switch (reason) {
      case SyncReason.appStart:
        // Full sync on app start - syncs everything
        // Based on seedingProcess in sync_real_time_providers.dart
        return SyncPolicy(
          items: true,
          categories: true,
          pages: true,
          pageItems: true,
          itemRepresentation: true,
          modifiers: true,
          itemModifiers: true,
          modifierOptions: true,
          taxes: true,
          itemTaxes: true,
          categoryTaxes: true,
          orderOptionTaxes: true,
          outletTaxes: true,
          discounts: true,
          discountItems: true,
          categoryDiscounts: true,
          discountOutlets: true,
          tableLayout: true,
          tables: true,
          tableSections: true,
          orderOptions: true,
          predefinedOrders: true,
          sales: true,
          saleItems: true,
          saleModifiers: true,
          saleModifierOptions: true,
          saleVariantOptions: true,
          receipts: true,
          receiptItems: true,
          receiptSettings: true,
          users: true,
          staff: true,
          customers: true,
          permissions: true,
          outlets: true,
          devices: true,
          printers: true,
          departmentPrinters: true,
          paymentTypes: true,
          outletPaymentTypes: true,
          features: true,
          featureCompanies: true,
          cashManagement: true,
          shifts: true,
          timecards: true,
          slideshow: true,
          downloadedFiles: true,
          cities: true,
          countries: true,
          divisions: true,
          inventory: true,
          inventoryTransactions: true,
          suppliers: true,
          printReceiptCache: true,
          deleted: true,
          pendingChanges: true,
        );

      case SyncReason.pinSuccess:
        // Minimal sync on pin unlock - just load from local DB
        // Based on getAllDataFromLocalDb in general_service_impl.dart
        return SyncPolicy(
          items: true,
          categories: true,
          pages: true,
          pageItems: true,
          modifiers: true,
          itemModifiers: true,
          modifierOptions: true,
          taxes: true,
          itemTaxes: true,
          categoryTaxes: true,
          orderOptionTaxes: true,
          outletTaxes: true,
          discounts: true,
          discountItems: true,
          categoryDiscounts: true,
          discountOutlets: true,
          tableLayout: true,
          tables: true,
          tableSections: true,
          orderOptions: true,
          predefinedOrders: true,
          receiptSettings: true,
          permissions: true,
          printers: true,
          departmentPrinters: true,
          paymentTypes: true,
          outletPaymentTypes: true,
          features: true,
          featureCompanies: true,
          cashManagement: true,
          shifts: true,
          timecards: true,
          slideshow: true,
          downloadedFiles: true,
        );

      case SyncReason.manualRefresh:
        // Full sync on manual refresh - same as app start
        // User explicitly requested refresh, sync everything
        return SyncPolicy(
          items: true,
          categories: true,
          pages: true,
          pageItems: true,
          itemRepresentation: true,
          modifiers: true,
          itemModifiers: true,
          modifierOptions: true,
          taxes: true,
          itemTaxes: true,
          categoryTaxes: true,
          orderOptionTaxes: true,
          outletTaxes: true,
          discounts: true,
          discountItems: true,
          categoryDiscounts: true,
          discountOutlets: true,
          tableLayout: true,
          tables: true,
          tableSections: true,
          orderOptions: true,
          predefinedOrders: true,
          sales: true,
          saleItems: true,
          saleModifiers: true,
          saleModifierOptions: true,
          saleVariantOptions: true,
          receipts: true,
          receiptItems: true,
          receiptSettings: true,
          users: true,
          staff: true,
          customers: true,
          permissions: true,
          outlets: true,
          devices: true,
          printers: true,
          departmentPrinters: true,
          paymentTypes: true,
          outletPaymentTypes: true,
          features: true,
          featureCompanies: true,
          cashManagement: true,
          shifts: true,
          timecards: true,
          slideshow: true,
          downloadedFiles: true,
          cities: true,
          countries: true,
          divisions: true,
          inventory: true,
          inventoryTransactions: true,
          suppliers: true,
          printReceiptCache: true,
          deleted: true,
          pendingChanges: true,
        );

      case SyncReason.licenseKeySuccess:
        // Minimal sync after license activation
        // Based on isAfterActivateLicense logic in onSyncOrder
        return SyncPolicy(
          users: true,
          staff: true,
          permissions: true,
          outlets: true,
          devices: true,
          features: true,
          featureCompanies: true,
          shifts: true,
          timecards: true,
          cities: true,
          countries: true,
          divisions: true,
        );
    }
  }

  /// Convert policy to map for dynamic iteration
  Map<String, bool> toMap() {
    return {
      'items': items,
      'categories': categories,
      'pages': pages,
      'pageItems': pageItems,
      'itemRepresentation': itemRepresentation,
      'modifiers': modifiers,
      'itemModifiers': itemModifiers,
      'modifierOptions': modifierOptions,
      'taxes': taxes,
      'itemTaxes': itemTaxes,
      'categoryTaxes': categoryTaxes,
      'orderOptionTaxes': orderOptionTaxes,
      'outletTaxes': outletTaxes,
      'discounts': discounts,
      'discountItems': discountItems,
      'categoryDiscounts': categoryDiscounts,
      'discountOutlets': discountOutlets,
      'tableLayout': tableLayout,
      'tables': tables,
      'tableSections': tableSections,
      'orderOptions': orderOptions,
      'predefinedOrders': predefinedOrders,
      'sales': sales,
      'saleItems': saleItems,
      'saleModifiers': saleModifiers,
      'saleModifierOptions': saleModifierOptions,
      'saleVariantOptions': saleVariantOptions,
      'receipts': receipts,
      'receiptItems': receiptItems,
      'receiptSettings': receiptSettings,
      'users': users,
      'staff': staff,
      'customers': customers,
      'permissions': permissions,
      'outlets': outlets,
      'devices': devices,
      'printers': printers,
      'departmentPrinters': departmentPrinters,
      'paymentTypes': paymentTypes,
      'outletPaymentTypes': outletPaymentTypes,
      'features': features,
      'featureCompanies': featureCompanies,
      'cashManagement': cashManagement,
      'shifts': shifts,
      'timecards': timecards,
      'slideshow': slideshow,
      'downloadedFiles': downloadedFiles,
      'cities': cities,
      'countries': countries,
      'divisions': divisions,
      'inventory': inventory,
      'inventoryTransactions': inventoryTransactions,
      'suppliers': suppliers,
      'printReceiptCache': printReceiptCache,
      'deleted': deleted,
      'pendingChanges': pendingChanges,
    };
  }
}
