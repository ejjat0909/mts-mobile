# Sync Handler Riverpod Migration Guide

## Goal

Complete migration from ServiceLocator to Riverpod for all sync handlers, following Clean Architecture principles.

## Current State Problems

1. **Singleton Registry Pattern** - Global mutable state
2. **Mixed Dependencies** - Some use ServiceLocator, some use Riverpod
3. **Hybrid Initialization** - Registry.initialize() + provider overrides
4. **Testing Difficulty** - Hard to mock singleton dependencies

## Recommended Clean Architecture Approach

### Option 1: Individual Providers with Map Provider (RECOMMENDED)

**Benefits:**

- ✅ Each handler is independently testable
- ✅ Clear dependency graph
- ✅ No global state
- ✅ Lazy initialization (providers only created when accessed)
- ✅ Easy to add/remove handlers
- ✅ Follows Riverpod best practices

**Structure:**

```dart
// 1. Individual handler providers
final itemSyncHandlerProvider = Provider<ItemSyncHandler>((ref) {
  return ItemSyncHandler(
    localRepository: ref.read(itemLocalRepoProvider),
    notifier: ref.read(itemProvider.notifier),
  );
});

// 2. Map provider that collects all handlers
final syncHandlersMapProvider = Provider<Map<String, SyncHandler>>((ref) {
  return {
    ItemModel.modelName: ref.read(itemSyncHandlerProvider),
    CategoryModel.modelName: ref.read(categorySyncHandlerProvider),
    // ... all other handlers
  };
});

// 3. Helper to get handler by model name
final syncHandlerProvider = Provider.family<SyncHandler?, String>((ref, modelName) {
  return ref.read(syncHandlersMapProvider)[modelName];
});
```

**Usage:**

```dart
// In PusherEventHandler or anywhere with Ref access
final handler = ref.read(syncHandlerProvider(ItemModel.modelName));
await handler?.handleCreated(data);
```

### Option 2: Functional Approach (Alternative)

Instead of handler classes, use functions:

```dart
// Define handler function type
typedef SyncHandlerFunction = Future<void> Function(
  Ref ref,
  String eventType,
  Map<String, dynamic> data,
);

// Individual handler functions
Future<void> handleItemSync(Ref ref, String eventType, Map<String, dynamic> data) async {
  final localRepo = ref.read(itemLocalRepoProvider);
  final notifier = ref.read(itemProvider.notifier);

  switch (eventType) {
    case 'created':
    case 'updated':
      final model = ItemModel.fromJson(data);
      await localRepo.upsert([model]);
      notifier.addOrUpdate([model]);
      break;
    case 'deleted':
      // ...
      break;
  }
}

// Map provider
final syncHandlerFunctionsProvider = Provider<Map<String, SyncHandlerFunction>>((ref) {
  return {
    ItemModel.modelName: handleItemSync,
    CategoryModel.modelName: handleCategorySync,
  };
});
```

## Migration Steps

### Phase 1: Create Individual Handler Providers ✅ Started

For each sync handler:

1. Create a provider file: `[model]_sync_handler_provider.dart`
2. Define provider with all dependencies from other providers
3. Remove ServiceLocator usage

Example template:

```dart
// lib/data/services/sync/item_sync_handler_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/repositories/local/local_item_repository_impl.dart';
import 'package:mts/data/services/sync/item_sync_handler.dart';
import 'package:mts/providers/item/item_providers.dart';

/// Provider for ItemSyncHandler with full Riverpod integration
final itemSyncHandlerProvider = Provider<ItemSyncHandler>((ref) {
  return ItemSyncHandler(
    localRepository: ref.read(itemLocalRepoProvider),
    notifier: ref.read(itemProvider.notifier),
  );
});
```

### Phase 2: Create Centralized Map Provider

```dart
// lib/data/services/sync/sync_handlers_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/services/sync/sync_handler.dart';
import 'package:mts/data/models/item/item_model.dart';
// ... import all models and handler providers

/// Central map of all sync handlers
///
/// This replaces the SyncHandlerRegistry singleton
final syncHandlersMapProvider = Provider<Map<String, SyncHandler>>((ref) {
  return {
    ItemModel.modelName: ref.read(itemSyncHandlerProvider),
    CategoryModel.modelName: ref.read(categorySyncHandlerProvider),
    CustomerModel.modelName: ref.read(customerSyncHandlerProvider),
    // ... all other handlers (90+ total)
  };
});

/// Family provider to get handler by model name
final syncHandlerProvider = Provider.family<SyncHandler?, String>((ref, modelName) {
  return ref.read(syncHandlersMapProvider)[modelName];
});
```

### Phase 3: Update PusherEventHandler

```dart
// Before (using registry)
final registry = ref.read(syncHandlerRegistryProvider);
final handler = registry.getHandler(modelName);

// After (using map provider)
final handler = ref.read(syncHandlerProvider(modelName));
```

### Phase 4: Update Sync Handlers

Remove ServiceLocator fallbacks from all handlers:

**Before:**

```dart
ItemSyncHandler({
  LocalItemRepository? localRepository,
  ItemNotifier? notifier,
}) : _localRepository = localRepository ?? ServiceLocator.get<LocalItemRepository>(),
     _notifier = notifier ?? ServiceLocator.get<ItemNotifier>();
```

**After:**

```dart
ItemSyncHandler({
  required LocalItemRepository localRepository,
  required ItemNotifier notifier,
}) : _localRepository = localRepository,
     _notifier = notifier;
```

### Phase 5: Delete Old Code

1. Delete `sync_handler_registry.dart` (singleton class)
2. Delete `sync_handler_registry_provider.dart` (hybrid approach)
3. Remove ServiceLocator registrations for sync handlers
4. Update all imports

## Handler Provider Checklist

Create providers for these handlers (organized by category):

**Core Items & Categories:**

- [ ] `item_sync_handler_provider.dart`
- [ ] `category_sync_handler_provider.dart`
- [ ] `item_representation_sync_handler_provider.dart` ✅ Needs AssetDownloadService
- [ ] `page_sync_handler_provider.dart`
- [ ] `page_item_sync_handler_provider.dart`

**Modifiers & Options:**

- [ ] `modifier_sync_handler_provider.dart`
- [ ] `modifier_option_sync_handler_provider.dart`
- [ ] `item_modifier_sync_handler_provider.dart`
- [ ] `order_option_sync_handler_provider.dart`
- [x] `order_option_tax_sync_handler_provider.dart` ✅ Already exists

**Taxes & Discounts:**

- [ ] `tax_sync_handler_provider.dart`
- [ ] `item_tax_sync_handler_provider.dart`
- [x] `category_tax_sync_handler_provider.dart` ✅ Already exists
- [ ] `outlet_tax_sync_handler_provider.dart`
- [ ] `discount_sync_handler_provider.dart`
- [ ] `discount_item_sync_handler_provider.dart`
- [x] `category_discount_sync_handler_provider.dart` ✅ Already exists
- [ ] `discount_outlet_sync_handler_provider.dart`

**Tables & Layout:**

- [ ] `table_layout_sync_handler_provider.dart`
- [ ] `table_sync_handler_provider.dart`
- [ ] `table_section_sync_handler_provider.dart`

**Sales & Receipts:**

- [ ] `sale_sync_handler_provider.dart`
- [ ] `sale_item_sync_handler_provider.dart`
- [ ] `sale_modifier_sync_handler_provider.dart`
- [ ] `sale_modifier_option_sync_handler_provider.dart`
- [ ] `sale_variant_option_sync_handler_provider.dart`
- [ ] `receipt_sync_handler_provider.dart`
- [ ] `receipt_item_sync_handler_provider.dart`
- [ ] `receipt_setting_sync_handler_provider.dart` ✅ Needs AssetDownloadService

**Users & Staff:**

- [ ] `user_sync_handler_provider.dart`
- [ ] `staff_sync_handler_provider.dart`
- [ ] `customer_sync_handler_provider.dart`
- [ ] `permission_sync_handler_provider.dart`

**Outlets & Devices:**

- [ ] `outlet_sync_handler_provider.dart`
- [ ] `device_sync_handler_provider.dart`
- [ ] `printer_setting_sync_handler_provider.dart`
- [ ] `department_printer_sync_handler_provider.dart`

**Payment:**

- [ ] `payment_type_sync_handler_provider.dart`
- [ ] `outlet_payment_type_sync_handler_provider.dart`

**Features & Settings:**

- [ ] `feature_sync_handler_provider.dart`
- [x] `feature_company_sync_handler_provider.dart` ✅ Already exists

**Cash & Shifts:**

- [ ] `cash_management_sync_handler_provider.dart`
- [ ] `shift_sync_handler_provider.dart`
- [ ] `timecard_sync_handler_provider.dart`

**Media:**

- [ ] `slideshow_sync_handler_provider.dart` ✅ Needs AssetDownloadService
- [ ] `downloaded_file_sync_handler_provider.dart`

**Geography:**

- [ ] `city_sync_handler_provider.dart`
- [ ] `country_sync_handler_provider.dart`
- [ ] `division_sync_handler_provider.dart`

**Inventory:**

- [ ] `inventory_sync_handler_provider.dart`
- [ ] `inventory_transaction_sync_handler_provider.dart`
- [ ] `supplier_sync_handler_provider.dart`

**Others:**

- [ ] `predefined_order_sync_handler_provider.dart`
- [ ] `print_receipt_cache_sync_handler_provider.dart`

## Special Cases

### Handlers with AssetDownloadService

These handlers need `AssetDownloadService` from Riverpod providers:

- `ItemRepresentationSyncHandler` ✅ Already migrated
- `ReceiptSettingSyncHandler` ✅ Already migrated
- `SlideshowSyncHandler` ✅ Already migrated

**Pattern:**

```dart
final receiptSettingSyncHandlerProvider = Provider<ReceiptSettingSyncHandler>((ref) {
  return ReceiptSettingSyncHandler(
    localRepository: ref.read(receiptSettingsLocalRepoProvider),
    assetDownloadService: ref.read(assetDownloadServiceProvider),
  );
});
```

### Handlers with Complex Dependencies

Some handlers have multiple dependencies (repositories, notifiers, services):

```dart
final staffSyncHandlerProvider = Provider<StaffSyncHandler>((ref) {
  return StaffSyncHandler(
    localRepository: ref.read(staffLocalRepoProvider),
    staffNotifier: ref.read(staffProvider.notifier),
    permissionNotifier: ref.read(permissionProvider.notifier),
  );
});
```

## Benefits After Migration

1. **Testability**: Easy to mock individual handlers in tests
2. **Type Safety**: Compile-time checking of dependencies
3. **Performance**: Lazy initialization - handlers only created when needed
4. **Maintainability**: Clear dependency graph, easy to trace
5. **Debugging**: Better error messages with provider chains
6. **No Global State**: Everything scoped to Riverpod container
7. **Hot Reload**: Works better with Flutter's hot reload

## Example: Complete Handler Migration

### Before (Old Pattern)

```dart
// sync_handler_registry.dart
class SyncHandlerRegistry {
  static final _instance = SyncHandlerRegistry._internal();
  final Map<String, SyncHandler> _handlers = {};

  void initialize() {
    register(ItemModel.modelName, ItemSyncHandler());
  }
}

// item_sync_handler.dart
class ItemSyncHandler implements SyncHandler {
  final LocalItemRepository _localRepository;

  ItemSyncHandler({
    LocalItemRepository? localRepository,
  }) : _localRepository =
         localRepository ?? ServiceLocator.get<LocalItemRepository>();
}

// Usage
final registry = SyncHandlerRegistry();
registry.initialize();
final handler = registry.getHandler(ItemModel.modelName);
```

### After (Riverpod Pattern)

```dart
// item_sync_handler_provider.dart
final itemSyncHandlerProvider = Provider<ItemSyncHandler>((ref) {
  return ItemSyncHandler(
    localRepository: ref.read(itemLocalRepoProvider),
    notifier: ref.read(itemProvider.notifier),
  );
});

// item_sync_handler.dart
class ItemSyncHandler implements SyncHandler {
  final LocalItemRepository _localRepository;
  final ItemNotifier _notifier;

  ItemSyncHandler({
    required LocalItemRepository localRepository,
    required ItemNotifier notifier,
  }) : _localRepository = localRepository,
       _notifier = notifier;
}

// sync_handlers_provider.dart
final syncHandlersMapProvider = Provider<Map<String, SyncHandler>>((ref) {
  return {
    ItemModel.modelName: ref.read(itemSyncHandlerProvider),
  };
});

final syncHandlerProvider = Provider.family<SyncHandler?, String>((ref, modelName) {
  return ref.read(syncHandlersMapProvider)[modelName];
});

// Usage
final handler = ref.read(syncHandlerProvider(ItemModel.modelName));
```

## Next Steps

1. Start with handlers that already have providers (OrderOptionTax, CategoryDiscount, etc.)
2. Create template script to generate provider files
3. Migrate 5-10 handlers at a time
4. Test each batch thoroughly
5. Delete registry once all handlers migrated

---

**Status**: 4/90+ handlers have providers (OrderOptionTax, FeatureCompany, CategoryDiscount, CategoryTax, plus 3 with AssetDownloadService)
**Goal**: 100% Riverpod, 0% ServiceLocator
