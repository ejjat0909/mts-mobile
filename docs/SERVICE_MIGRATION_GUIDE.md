# Service Architecture Migration Guide

## Overview

This guide documents the migration from `GeneralService` / `GeneralServiceImpl` to focused domain services following Clean Architecture and Riverpod best practices.

## Problem Statement

The old `GeneralService` was handling too many responsibilities:

- Image/file downloads
- Local data cache loading
- Pusher/WebSocket initialization
- Mixed with sync logic in various places

This created confusion about where functionality lived and violated Single Responsibility Principle.

## New Architecture

### 1. **AssetDownloadService** (`/lib/domain/services/media/asset_download_service.dart`)

**Purpose:** Handles concurrent downloads of images and files with progress tracking

**Key Methods:**

- `downloadPendingAssets()` - Downloads all pending files with progress callbacks
- Uses internal `_AsyncDownloadQueue` for concurrency control (default 3 simultaneous downloads)

**Provider:** `assetDownloadServiceProvider`

**Usage Example:**

```dart
final assetService = ref.read(assetDownloadServiceProvider);
await assetService.downloadPendingAssets(
  progressNotifier: downloadProgress,
  speedNotifier: downloadSpeed,
);
```

**Replaces:**

- `GeneralService.downloadImages()`
- Image download logic scattered across sync handlers

---

### 2. **AppSyncService** (`/lib/core/sync/app_sync_service.dart`) - ALREADY EXISTS

**Purpose:** Central sync orchestrator that handles all data synchronization with policy-based control

**Key Methods:**

- `syncAll(reason:)` - Syncs data based on SyncReason (appStart, pinSuccess, manualRefresh, licenseKeySuccess)
- Uses `SyncPolicy` to determine what to sync for each reason
- Handles pending changes, deleted items, and entity syncing

**Provider:** `appSyncServiceProvider`

**Usage Example:**

```dart
// For PIN unlock (loads from local DB based on policy)
await ref.read(appSyncServiceProvider.notifier).syncAll(
  reason: SyncReason.pinSuccess,
  needToDownloadImage: false,
);
```

**Replaces:**

- `GeneralService.getAllDataFromLocalDb()` - Use `syncAll(reason: SyncReason.pinSuccess)` instead
- The `SyncPolicy.forReason(SyncReason.pinSuccess)` already defines what data to load

---

### 3. **WebSocketService** (`/lib/domain/services/realtime/websocket_service.dart`)

**Purpose:** Manages Pusher/WebSocket connections for real-time sync

**Key Methods:**

- `initializeForShift(shiftId)` - Initialize Pusher with shift-specific channel
- `subscribeToLatestShift()` - Subscribe to most recent shift's channel
- `disconnect()` / `reconnect()` - Connection lifecycle management

**Provider:** `webSocketServiceProvider`

**Usage Example:**

```dart
final wsService = ref.read(webSocketServiceProvider);
await wsService.initializeForShift(shiftModel.id.toString());
```

**Replaces:**

- Pusher initialization code in `GeneralService`
- Direct PusherDatasource usage scattered in codebase

---

## Migration Strategy

### Phase 1: Create New Services ✅ COMPLETED

- [x] Create AssetDownloadService
- [x] Recognize AppSyncService already handles local data loading via SyncPolicy
- [x] Create WebSocketService
- [x] Add Riverpod providers for new services
- [x] Delete redundant CacheService (AppSyncService handles this)

### Phase 2: Migrate Existing Usages 🔄 IN PROGRESS

#### Files Using GeneralService (20+ locations):

**UI Components:**

1. ✅ `/lib/presentation/features/pin_lock/components/pin_input_field.dart` - MIGRATED

   - Changed from `_generalFacade.getAllDataFromLocalDb()`
   - To `ref.read(appSyncServiceProvider.notifier).syncAll(reason: SyncReason.pinSuccess)`

2. `/lib/presentation/features/login/components/login_form.dart`

   - Uses `getAllDataFromLocalDb()` after successful login
   - Migration: Replace with `AppSyncService.syncAll(reason: SyncReason.pinSuccess)`

3. `/lib/presentation/features/activate_license/components/license_form.dart`

   - Uses `getAllDataFromLocalDb()` after license activation
   - Migration: Replace with `AppSyncService.syncAll(reason: SyncReason.licenseKeySuccess)`

4. `/lib/presentation/features/shift_screen/components/open_shift_dialogue.dart`

   - Uses `downloadImages()` after opening shift
   - Migration: Replace with `AssetDownloadService.downloadPendingAssets()`

5. `/lib/presentation/features/setting_receipt/components/receipt_logo.dart`
   - Uses `downloadImages()` for receipt logo
   - Migration: Replace with `AssetDownloadService.downloadPendingAssets()`

**Sync Handlers:** 6. `/lib/data/services/sync/receipt_setting_sync_handler.dart`

- Injects `GeneralService` for image downloads
- Migration: Inject `AssetDownloadService` instead

7. `/lib/data/services/sync/device_sync_handler.dart`

   - Uses `downloadImages()` after device sync
   - Migration: Replace with `AssetDownloadService.downloadPendingAssets()`

8. `/lib/data/services/sync/user_sync_handler.dart`

   - Uses `downloadImages()` after user sync
   - Migration: Replace with `AssetDownloadService.downloadPendingAssets()`

9. `/lib/data/services/sync/slideshow_sync_handler.dart`

   - Injects `GeneralService` for slideshow images
   - Migration: Inject `AssetDownloadService` instead

10. `/lib/data/services/sync/item_representation_sync_handler.dart`
    - Injects `GeneralService` for item images
    - Migration: Inject `AssetDownloadService` instead

**Other Files:** 11. `/lib/main.dart` - Creates `GeneralService` instance - Migration: Remove after all usages migrated

12. `/lib/providers/sync_real_time/sync_real_time_providers.dart`
    - Uses `downloadImages()` in real-time sync
    - Migration: Replace with `AssetDownloadService.downloadPendingAssets()`

### Phase 3: Cleanup & Deprecation

- [ ] Mark `GeneralService` interface as `@Deprecated`
- [ ] Mark `GeneralServiceImpl` as `@Deprecated`
- [ ] Update all tests to use new services
- [ ] Remove deprecated services after verification
- [ ] Update service locator registration

---

## Migration Patterns

### Pattern 1: Cache Loading (getAllDataFromLocalDb → AppSyncService)

**Before:**

```dart
final GeneralService _generalFacade = ServiceLocator.get<GeneralService>();

await _generalFacade.getAllDataFromLocalDb(
  ref,
  null,
  (loading) {},
  isDownloadData: (isDownloading) {
    if (isDownloading) {
      LoadingDialog.show(context);
    } else {
      LoadingDialog.hide(context);
    }
  },
  needDownloadImages: false,
);
```

**After:**

```dart
// Use AppSyncService with pinSuccess reason
// The SyncPolicy for pinSuccess already defines what to load
await ref.read(appSyncServiceProvider.notifier).syncAll(
  reason: SyncReason.pinSuccess,
  context: context,
  needToDownloadImage: false,
);
```

**Why This Works:**

- `SyncPolicy.forReason(SyncReason.pinSuccess)` already defines the same models that `getAllDataFromLocalDb()` loaded
- AppSyncService loads from local DB when no internet or uses cached data
- Progress tracking is built-in via `appSyncServiceProvider` state

### Pattern 2: Image Downloads (downloadImages → AssetDownloadService)

**Before:**

```dart
final GeneralService _generalFacade = ServiceLocator.get<GeneralService>();

await _generalFacade.downloadImages(
  _downloadProgressNotifier,
  (speed) => _downloadSpeedNotifier.value = speed,
);
```

**After:**

```dart
final assetService = ref.read(assetDownloadServiceProvider);

await assetService.downloadPendingAssets(
  progressNotifier: _downloadProgressNotifier,
  speedNotifier: _downloadSpeedNotifier,
);
```

### Pattern 3: Pusher Initialization (Direct → WebSocketService)

**Before:**

```dart
final pusherDatasource = ServiceLocator.get<PusherDatasource>();
await pusherDatasource.initialize(shiftId);
await pusherDatasource.subscribeToChannel(channelName);
```

**After:**

```dart
final wsService = ref.read(webSocketServiceProvider);
await wsService.initializeForShift(shiftId);
```

### Pattern 4: Dependency Injection in Sync Handlers

**Before:**

```dart
class ReceiptSettingSyncHandler {
  final GeneralService _generalFacade;

  ReceiptSettingSyncHandler({
    GeneralService? generalFacade,
  }) : _generalFacade = generalFacade ?? GeneralServiceImpl.fromServiceLocator();
}
```

**After:**

```dart
class ReceiptSettingSyncHandler {
  final AssetDownloadService _assetDownloadService;

  ReceiptSettingSyncHandler({
    AssetDownloadService? assetDownloadService,
  }) : _assetDownloadService = assetDownloadService ??
         ServiceLocator.get<AssetDownloadService>();
}
```

---

## Benefits of New Architecture

1. **Single Responsibility:** Each service has one clear purpose
2. **Discoverability:** Service names clearly indicate their function
3. **No Redundancy:** AppSyncService already handles local data loading via SyncPolicy
4. **Policy-Based:** SyncReason determines what to load/sync (no duplicate logic)
5. **Testability:** Easier to mock and test isolated services
6. **Maintainability:** Changes to one feature don't affect others
7. **Riverpod Integration:** Direct provider access, no service locator needed in UI
8. **Performance:** Services can be optimized for their specific use case
9. **Type Safety:** Stronger typing with focused interfaces

---

## Key Insight: Why We Removed CacheService

Initially, we created `CacheService.loadAllToMemory()` to replace `GeneralService.getAllDataFromLocalDb()`. However, this was **redundant** because:

1. **AppSyncService already handles this** via `SyncReason.pinSuccess`
2. **SyncPolicy already defines** what data to load for each scenario
3. **Maintaining two lists** of what to load creates inconsistency risk
4. **AppSyncService provides better features:**
   - Progress tracking built-in
   - Handles both local and remote sync
   - Policy-based configuration
   - Already integrated throughout the app

**The Right Approach:**

- Use `AppSyncService.syncAll(reason: SyncReason.pinSuccess)` for PIN unlock
- Use `AppSyncService.syncAll(reason: SyncReason.appStart)` for app startup
- Use `AppSyncService.syncAll(reason: SyncReason.licenseKeySuccess)` for license activation
- Each reason has its own SyncPolicy that defines what to load

---

## Next Steps

1. Continue migrating files one by one using the patterns above
2. Run tests after each migration to ensure correctness
3. Update documentation as services are deprecated
4. Consider adding service-level unit tests
5. Eventually remove `GeneralService` and `GeneralServiceImpl`

---

## Questions & Considerations

### Q: Should sync handlers use Riverpod or ServiceLocator?

**A:** For now, sync handlers can continue using ServiceLocator for backward compatibility. Future refactoring can convert them to Riverpod.

### Q: What about error handling in the new services?

**A:** Each service throws exceptions that should be caught by callers. Consider adding custom exception types in future iteration.

### Q: Why not create a CacheService?

**A:** AppSyncService already handles local data loading via `SyncReason.pinSuccess`. Creating a separate CacheService would duplicate this logic and create maintenance burden. The SyncPolicy already defines what data to load for each scenario.

### Q: How does AppSyncService know to load from local vs remote?

**A:** AppSyncService checks internet connection and uses cached data when offline. The sync flow always prioritizes local data first, then syncs with remote when available. For PIN unlock scenarios, it loads the local data as defined in the `pinSuccess` policy.

### Q: Performance impact of parallel loading in AppSyncService?

**A:** AppSyncService uses concurrency limiting (max concurrent tasks) and loads data in parallel where possible, similar to the old `getAllDataFromLocalDb()` implementation.

### Q: Can I still use old GeneralService during migration?

**A:** Yes, old service remains functional during migration. Complete one file at a time to minimize risk.

---

_Last Updated: Migration in progress. Removed CacheService (redundant with AppSyncService). pin_input_field.dart completed as reference implementation using AppSyncService._
