# Sync Handler Refactoring Guide

**Date:** 28 December 2025  
**Purpose:** Step-by-step guide to refactor sync handlers to use Riverpod providers and notifier methods

---

## Table of Contents

- [Overview](#overview)
- [Why Refactor?](#why-refactor)
- [Refactoring Checklist](#refactoring-checklist)
- [Step-by-Step Instructions](#step-by-step-instructions)
- [Before & After Examples](#before--after-examples)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

---

## Overview

This guide shows how to refactor sync handlers from the old pattern (repository + manual state updates) to the new pattern (notifier methods that handle both).

### Old Pattern (❌ Don't Use)

```dart
// Sync handler directly calls repository
await _localRepository.upsertBulk([model], isInsertToPending: false);
// Then manually updates state
_notifier.addOrUpdate([model]);
```

### New Pattern (✅ Use This)

```dart
// Sync handler calls notifier method that handles both
await _notifier.insertBulk([model], isInsertToPending: false);
```

---

## Why Refactor?

### Benefits

1. **DRY Principle**: No duplicate state update logic
2. **Single Source of Truth**: Notifier handles all state changes
3. **Consistency**: Same logic for UI and sync operations
4. **Less Error-Prone**: Can't forget to update state
5. **Maintainable**: Changes to update logic in one place
6. **Riverpod-First**: Removes ServiceLocator dependency

### What Changes

- ✅ Use notifier methods instead of repository + manual state update
- ✅ Remove ServiceLocator, use Riverpod providers
- ✅ Add provider export to make handler available
- ✅ Inject dependencies via constructor

---

## Refactoring Checklist

For each sync handler:

- [ ] **Step 1**: Check if notifier has `insertBulk` or similar method
- [ ] **Step 2**: Create provider for sync handler
- [ ] **Step 3**: Remove ServiceLocator from constructor
- [ ] **Step 4**: Update `handleCreated` to use notifier method
- [ ] **Step 5**: Update `handleUpdated` to use notifier method
- [ ] **Step 6**: Update `handleDeleted` to use notifier method
- [ ] **Step 7**: Export provider in `sync_handlers_provider.dart`
- [ ] **Step 8**: Test real-time sync

---

## Step-by-Step Instructions

### Step 1: Check Notifier Methods

Look at the notifier for your model. Check if it has methods like:

- `insertBulk()` / `upsertBulk()`
- `deleteBulk()`
- `addOrUpdate()` (if you need to add a list parameter)

**Example:**

```dart
// Check device_providers.dart
class DeviceNotifier extends StateNotifier<DeviceState> {
  Future<bool> insertBulk(List<PosDeviceModel> list, {
    bool isInsertToPending = true,
  }) async {
    // ✅ This exists, we can use it!
  }
}
```

If the notifier **doesn't have** a bulk method, you may need to:

- Use existing `addOrUpdate()` method (if it accepts a list)
- Or keep using repository + manual state update (document why)

---

### Step 2: Create Provider for Sync Handler

At the top of your sync handler file, add a provider:

```dart
/// Provider for [ModelName]SyncHandler
final modelNameSyncHandlerProvider = Provider<SyncHandler>((ref) {
  return ModelNameSyncHandler(
    localRepository: ref.read(modelNameLocalRepoProvider),
    notifier: ref.read(modelNameProvider.notifier),
    // Add other dependencies as needed
  );
});
```

**Real Example (DeviceSyncHandler):**

```dart
/// Provider for DeviceSyncHandler
final deviceSyncHandlerProvider = Provider<SyncHandler>((ref) {
  return DeviceSyncHandler(
    localRepository: ref.read(deviceLocalRepoProvider),
    deviceNotifier: ref.read(deviceProvider.notifier),
    userNotifier: ref.read(userProvider.notifier),
  );
});
```

---

### Step 3: Remove ServiceLocator from Constructor

**Before:**

```dart
class ItemSyncHandler implements SyncHandler {
  final LocalItemRepository _localRepository;
  final ItemNotifier? _itemNotifier;

  ItemSyncHandler({
    LocalItemRepository? localRepository,
    ItemNotifier? itemNotifier,
  }) : _localRepository = localRepository ?? ServiceLocator.get<LocalItemRepository>(),
       _itemNotifier = itemNotifier ?? ServiceLocator.get<ItemNotifier>();
}
```

**After:**

```dart
class ItemSyncHandler implements SyncHandler {
  final LocalItemRepository _localRepository;
  final ItemNotifier _itemNotifier;

  /// Constructor with dependency injection
  ItemSyncHandler({
    required LocalItemRepository localRepository,
    required ItemNotifier itemNotifier,
  }) : _localRepository = localRepository,
       _itemNotifier = itemNotifier;
}
```

**Changes:**

- ✅ Remove `?` (nullable) from parameters
- ✅ Make all parameters `required`
- ✅ Remove `?? ServiceLocator.get<T>()` fallbacks
- ✅ Remove nullable fields (`?`) in class properties

---

### Step 4: Update handleCreated

**Before:**

```dart
@override
Future<void> handleCreated(Map<String, dynamic> data) async {
  ItemModel model = ItemModel.fromJson(data);

  await _localRepository.upsertBulk([model], isInsertToPending: false);
  _itemNotifier.addOrUpdate([model]); // Manual state update

  MetaModel meta = MetaModel(lastSync: model.updatedAt?.toUtc());
  await SyncService.saveMetaData(ItemModel.modelName, meta);
}
```

**After:**

```dart
@override
Future<void> handleCreated(Map<String, dynamic> data) async {
  ItemModel model = ItemModel.fromJson(data);

  await _itemNotifier.insertBulk([model], isInsertToPending: false);

  MetaModel meta = MetaModel(lastSync: model.updatedAt?.toUtc());
  await SyncService.saveMetaData(ItemModel.modelName, meta);
}
```

**Changes:**

- ✅ Replace `_localRepository.upsertBulk()` with `_notifier.insertBulk()`
- ✅ Remove manual `_notifier.addOrUpdate()` call

---

### Step 5: Update handleUpdated

Same pattern as `handleCreated`:

**Before:**

```dart
@override
Future<void> handleUpdated(Map<String, dynamic> data) async {
  ItemModel model = ItemModel.fromJson(data);
  await _localRepository.upsertBulk([model], isInsertToPending: false);
  _itemNotifier.addOrUpdate([model]);
  // ... rest of code
}
```

**After:**

```dart
@override
Future<void> handleUpdated(Map<String, dynamic> data) async {
  ItemModel model = ItemModel.fromJson(data);
  await _itemNotifier.insertBulk([model], isInsertToPending: false);
  // ... rest of code
}
```

---

### Step 6: Update handleDeleted

For delete operations, check if notifier has `deleteBulk()`:

**If notifier has deleteBulk:**

```dart
@override
Future<void> handleDeleted(Map<String, dynamic> data) async {
  ItemModel model = ItemModel.fromJson(data);
  await _itemNotifier.deleteBulk([model]);
  // ... rest of code
}
```

**If notifier doesn't have deleteBulk:**

```dart
@override
Future<void> handleDeleted(Map<String, dynamic> data) async {
  ItemModel model = ItemModel.fromJson(data);
  await _localRepository.deleteBulk([model], isInsertToPending: false);
  // Keep repository call, but add comment explaining why

  // Note: Notifier doesn't have deleteBulk yet, using repository directly
  // TODO: Add deleteBulk method to notifier
}
```

---

### Step 7: Export Provider in sync_handlers_provider.dart

Add your handler to the central map:

**Location:** `lib/data/services/sync/sync_handlers_provider.dart`

**Find the section:**

```dart
final syncHandlersMapProvider = Provider<Map<String, SyncHandler>>((ref) {
  return {
    // ✅ Handlers with providers (fully migrated - no ServiceLocator)
    ItemModel.modelName: ref.read(itemSyncHandlerProvider),
    CategoryModel.modelName: ref.read(categorySyncHandlerProvider),
    // ... other handlers
```

**Add your handler:**

```dart
    DeviceModel.modelName: ref.read(deviceSyncHandlerProvider),
```

**Move from temporary section (if needed):**

```dart
// ⏳ Handlers without providers yet (temporary - uses ServiceLocator)
// These will be migrated to providers incrementally

// BEFORE - Remove this line:
PosDeviceModel.modelName: DeviceSyncHandler(),

// AFTER - Add to the ✅ section above:
PosDeviceModel.modelName: ref.read(deviceSyncHandlerProvider),
```

---

## Before & After Examples

### Complete Example: DeviceSyncHandler

**Before (device_sync_handler.dart):**

```dart
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/domain/repositories/local/device_repository.dart';
import 'package:mts/providers/device/device_providers.dart';

class DeviceSyncHandler implements SyncHandler {
  final LocalDeviceRepository _localRepository;
  final DeviceNotifier _deviceNotifier;

  DeviceSyncHandler({
    LocalDeviceRepository? localRepository,
    DeviceNotifier? deviceNotifier,
  }) : _localRepository = localRepository ?? ServiceLocator.get<LocalDeviceRepository>(),
       _deviceNotifier = deviceNotifier ?? ServiceLocator.get<DeviceNotifier>();

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    PosDeviceModel deviceModel = PosDeviceModel.fromJson(data);

    await _localRepository.upsertBulk([deviceModel], isInsertToPending: false);
    _deviceNotifier.addOrUpdate([deviceModel]); // ❌ Manual state update

    MetaModel meta = MetaModel(lastSync: deviceModel.updatedAt?.toUtc());
    await SyncService.saveMetaData(PosDeviceModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    PosDeviceModel deviceModel = PosDeviceModel.fromJson(data);
    await _localRepository.upsertBulk([deviceModel], isInsertToPending: false);
    _deviceNotifier.addOrUpdate([deviceModel]); // ❌ Manual state update
    // ... rest of code
  }
}
```

**After (device_sync_handler.dart):**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/repositories/local/local_device_repository_impl.dart';
import 'package:mts/domain/repositories/local/device_repository.dart';
import 'package:mts/providers/device/device_providers.dart';

/// Provider for DeviceSyncHandler
final deviceSyncHandlerProvider = Provider<SyncHandler>((ref) {
  return DeviceSyncHandler(
    localRepository: ref.read(deviceLocalRepoProvider),
    deviceNotifier: ref.read(deviceProvider.notifier),
    userNotifier: ref.read(userProvider.notifier),
  );
});

/// Sync handler for Device model
class DeviceSyncHandler implements SyncHandler {
  final LocalDeviceRepository _localRepository;
  final DeviceNotifier _deviceNotifier;
  final UserNotifier _userNotifier;

  /// Constructor with dependency injection
  DeviceSyncHandler({
    required LocalDeviceRepository localRepository,
    required DeviceNotifier deviceNotifier,
    required UserNotifier userNotifier,
  }) : _localRepository = localRepository,
       _deviceNotifier = deviceNotifier,
       _userNotifier = userNotifier;

  @override
  Future<void> handleCreated(Map<String, dynamic> data) async {
    PosDeviceModel deviceModel = PosDeviceModel.fromJson(data);

    await _deviceNotifier.insertBulk([deviceModel], isInsertToPending: false);

    MetaModel meta = MetaModel(lastSync: deviceModel.updatedAt?.toUtc());
    await SyncService.saveMetaData(PosDeviceModel.modelName, meta);
  }

  @override
  Future<void> handleUpdated(Map<String, dynamic> data) async {
    PosDeviceModel deviceModel = PosDeviceModel.fromJson(data);
    await _deviceNotifier.insertBulk([deviceModel], isInsertToPending: false);
    // ... rest of code
  }
}
```

---

## Special Cases

### Case 1: Notifier Has Only addOrUpdate() Method

If the notifier doesn't have `insertBulk()` but has `addOrUpdate()`:

**Check if it accepts a list:**

```dart
// If addOrUpdate accepts List<T>:
void addOrUpdate(List<ItemModel> models) { ... }

// Then you can use it:
await _localRepository.upsertBulk([model], isInsertToPending: false);
_notifier.addOrUpdate([model]);
```

**If it only accepts single items:**

```dart
// If addOrUpdate accepts single T:
void addOrUpdate(ItemModel model) { ... }

// Keep the repository call, document it:
await _localRepository.upsertBulk([model], isInsertToPending: false);
_notifier.addOrUpdate(model);

// TODO: Refactor addOrUpdate to accept List<T> for consistency
```

---

### Case 2: No State Management Needed

Some models don't need real-time UI updates (e.g., logs, background data):

```dart
@override
Future<void> handleCreated(Map<String, dynamic> data) async {
  LogModel model = LogModel.fromJson(data);

  // Just save to repository, no state update needed
  await _localRepository.upsertBulk([model], isInsertToPending: false);

  MetaModel meta = MetaModel(lastSync: model.updatedAt?.toUtc());
  await SyncService.saveMetaData(LogModel.modelName, meta);
}
```

**Note:** Document why no state update is needed:

```dart
// Note: Log models don't need real-time UI updates
// Data is only read on-demand from repository
```

---

### Case 3: Complex Business Logic in handleUpdated

If `handleUpdated` has complex logic (like logout on device deactivation):

**Keep the logic, just use notifier method for data updates:**

```dart
@override
Future<void> handleUpdated(Map<String, dynamic> data) async {
  PosDeviceModel deviceModel = PosDeviceModel.fromJson(data);

  // Use notifier method for data + state update
  await _deviceNotifier.insertBulk([deviceModel], isInsertToPending: false);

  // Keep complex business logic
  PosDeviceModel? latestDeviceModel = _deviceNotifier.getLatestDeviceModel();
  if (latestDeviceModel.id == deviceModel.id) {
    if (deviceModel.isActive != null && !deviceModel.isActive!) {
      // Complex logout logic...
      await _userNotifier.signOut(...);
    }
  }

  MetaModel meta = MetaModel(lastSync: deviceModel.updatedAt?.toUtc());
  await SyncService.saveMetaData(PosDeviceModel.modelName, meta);
}
```

---

## Testing

### 1. Unit Test the Sync Handler

```dart
test('handleCreated should call notifier.insertBulk', () async {
  // Arrange
  final mockNotifier = MockDeviceNotifier();
  final handler = DeviceSyncHandler(
    localRepository: mockRepository,
    deviceNotifier: mockNotifier,
    userNotifier: mockUserNotifier,
  );

  // Act
  await handler.handleCreated({'id': '123', 'name': 'Device 1'});

  // Assert
  verify(mockNotifier.insertBulk(any, isInsertToPending: false)).called(1);
  verifyNever(mockRepository.upsertBulk(any, isInsertToPending: false));
});
```

### 2. Integration Test Real-Time Sync

1. Run the app
2. Trigger a Pusher event from backend (or use Pusher debug console)
3. Verify:
   - Data is saved to local DB
   - UI updates immediately
   - No errors in logs

### 3. Manual Testing Checklist

- [ ] Create event: New record appears in UI
- [ ] Update event: Existing record updates in UI
- [ ] Delete event: Record disappears from UI
- [ ] No duplicate state updates
- [ ] No ServiceLocator errors

---

## Troubleshooting

### Error: "Provider not found"

**Problem:**

```
Error: Could not find a provider for deviceSyncHandlerProvider
```

**Solution:**
Make sure you added the provider export in `sync_handlers_provider.dart`:

```dart
PosDeviceModel.modelName: ref.read(deviceSyncHandlerProvider),
```

---

### Error: "Required parameter is null"

**Problem:**

```
Error: Required parameter 'deviceNotifier' cannot be null
```

**Solution:**
Check that the provider is reading the correct notifier provider:

```dart
// Make sure this exists and is correct:
deviceNotifier: ref.read(deviceProvider.notifier),
```

---

### State Not Updating in UI

**Problem:** Repository saves data but UI doesn't update

**Check:**

1. Is the notifier method being called?
2. Does the notifier method update the state?
3. Is the widget watching the provider?

**Debug:**

```dart
@override
Future<void> handleCreated(Map<String, dynamic> data) async {
  print('DEBUG: Before notifier call');
  await _deviceNotifier.insertBulk([deviceModel], isInsertToPending: false);
  print('DEBUG: After notifier call');
}
```

---

### Loading State Flashes During Sync

**Problem:** Brief loading indicator during background sync

**This is normal!** The notifier's `insertBulk` sets `isLoading: true/false`. This is harmless and happens so fast users won't notice.

**If it's a problem:** Create a separate sync method without loading state (see Special Cases above).

---

## Migration Priority

Recommend migrating handlers in this order:

### High Priority (User-facing data)

1. ✅ Device
2. Item
3. Category
4. Staff
5. Receipt
6. Sale

### Medium Priority (Configuration)

1. Printer Settings
2. Payment Types
3. Taxes
4. Discounts
5. Modifiers

### Low Priority (Background data)

1. Logs
2. Sync metadata
3. Cache entries

---

## Summary

**Key Takeaways:**

1. ✅ **Use notifier methods** instead of repository + manual state update
2. ✅ **Remove ServiceLocator** - use Riverpod providers
3. ✅ **Add provider export** to sync_handlers_provider.dart
4. ✅ **Make dependencies required** - no nullable fallbacks
5. ✅ **Test real-time sync** after refactoring

**Benefits:**

- Single source of truth
- Less code duplication
- More maintainable
- Consistent behavior
- Riverpod-first architecture

**Questions?** Refer to `device_sync_handler.dart` as the reference implementation.
