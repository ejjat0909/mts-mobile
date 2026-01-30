# Sync System Implementation Guide

## Overview

The new sync system provides reactive, granular sync progress tracking using Riverpod state management. It integrates all critical features from the old `sync_real_time` system while providing better code organization and testability.

## 🎯 Key Features

✅ **Pending Changes Priority** - Syncs local changes first  
✅ **Sync Check API** - Only syncs what the server says has changed  
✅ **Concurrency Control** - Limits to 4 concurrent sync tasks  
✅ **Granular Progress** - Track each entity individually  
✅ **Policy-Based** - Control what syncs for each trigger reason  
✅ **Reactive UI** - Automatic updates via Riverpod  
✅ **Error Tracking** - Know exactly what failed and why  
✅ **License Activation Mode** - Special handling for new licenses

## Architecture

```
lib/core/sync/
├── sync_state.dart           # State models for sync progress
├── sync_policy.dart          # Defines what to sync for each reason
├── sync_reason.dart          # Enum of sync triggers
└── app_sync_service.dart     # Main sync service (StateNotifier)

lib/widgets/
├── sync_indicator.dart       # Compact progress card
├── sync_progress_dialog.dart # Detailed progress dialog
└── sync_loading_overlay.dart # Full-screen blocking overlay
```

## 🚀 Quick Start

### 1. Trigger a Sync

```dart
// In your button or initialization code
await ref.read(appSyncServiceProvider.notifier).syncAll(
  reason: SyncReason.appStart,
);
```

### 2. Show Sync Progress

Choose one of three UI options:

#### Option A: Compact Indicator (Non-blocking)

```dart
import 'package:mts/widgets/sync_indicator.dart';

Scaffold(
  body: Column(
    children: [
      SyncIndicator(), // Shows small card at top
      YourMainContent(),
    ],
  ),
)
```

#### Option B: Detailed Dialog (Modal)

```dart
import 'package:mts/widgets/sync_progress_dialog.dart';

ElevatedButton(
  onPressed: () async {
    // Show dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SyncProgressDialog(),
    );

    // Trigger sync
    await ref.read(appSyncServiceProvider.notifier).syncAll();
  },
  child: Text('Sync Data'),
)
```

#### Option C: Full-Screen Overlay (Blocking)

```dart
import 'package:mts/widgets/sync_loading_overlay.dart';

Stack(
  children: [
    YourContent(),
    SyncLoadingOverlay(), // Covers entire screen when syncing
  ],
)
```

## Advanced Usage

### Watch Sync State Anywhere

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(appSyncServiceProvider);

    return Column(
      children: [
        if (syncState.isSyncing)
          Text('Syncing... ${(syncState.progress * 100).toInt()}%'),

        if (syncState.hasErrors)
          Text('${syncState.failedEntities} entities failed'),

        Text('${syncState.completedEntities}/${syncState.totalEntities}'),
      ],
    );
  }
}
```

### Check Individual Entity Status

```dart
final syncState = ref.watch(appSyncServiceProvider);
final itemsSyncState = syncState.entities['items'];

if (itemsSyncState?.isDone ?? false) {
  print('Items synced successfully!');
} else if (itemsSyncState?.error != null) {
  print('Items sync failed: ${itemsSyncState!.error}');
}
```

### Custom Sync Progress Handler

```dart
ref.listen(appSyncServiceProvider, (previous, next) {
  // React to sync state changes
  if (next.isSyncing && !(previous?.isSyncing ?? false)) {
    print('Sync started');
  }

  if (!next.isSyncing && (previous?.isSyncing ?? false)) {
    if (next.hasErrors) {
      showErrorSnackbar('Sync completed with errors');
    } else {
      showSuccessSnackbar('Sync completed successfully');
    }
  }
});
```

## Sync Reasons

Different sync reasons trigger different policies:

```dart
// Full sync - syncs everything
SyncReason.appStart
SyncReason.manualRefresh

// Minimal sync - only essential data
SyncReason.pinSuccess

// License activation - user, outlet, device setup
SyncReason.licenseKeySuccess
```

## Adding a New Sync Entity

To add a new entity to the sync system:

### 1. Add to SyncPolicy (sync_policy.dart)

```dart
class SyncPolicy {
  final bool myNewEntity;

  SyncPolicy({
    // ... existing parameters
    this.myNewEntity = false,
  });

  Map<String, bool> toMap() {
    return {
      // ... existing entries
      'myNewEntity': myNewEntity,
    };
  }
}
```

### 2. Update Sync Reasons

```dart
case SyncReason.appStart:
  return SyncPolicy(
    // ... existing entities
    myNewEntity: true, // Add to relevant reasons
  );
```

### 3. Add to Registry (app_sync_service.dart)

```dart
_syncRegistry = {
  // ... existing entries
  'myNewEntity': () => ref.read(myNewEntityProvider.notifier).syncFromRemote(),
};
```

### 4. Implement syncFromRemote in Provider

```dart
class MyNewEntityNotifier extends StateNotifier<...> {
  Future<void> syncFromRemote() async {
    // Fetch from API
    final data = await _api.getMyNewEntities();

    // Save to local DB
    await _localRepo.saveAll(data);

    // Update state
    state = data;
  }
}
```

## State Properties

### SyncState

- `isSyncing: bool` - Overall sync in progress
- `progress: double` - 0.0 to 1.0
- `entities: Map<String, SyncEntityState>` - Individual entity states
- `errorMessage: String?` - Overall error message
- `totalEntities: int` - Total entities to sync
- `completedEntities: int` - Completed count
- `failedEntities: int` - Failed count
- `hasErrors: bool` - Whether any entity failed

### SyncEntityState

- `isLoading: bool` - Entity currently syncing
- `isDone: bool` - Entity completed successfully
- `error: String?` - Error message if failed
- `startedAt: DateTime?` - When sync started
- `completedAt: DateTime?` - When sync finished
- `duration: Duration?` - Time taken (if completed)

## Best Practices

1. **Always use SyncReason** - Don't hardcode sync policies
2. **Show progress for long syncs** - Use dialog or overlay for initial sync
3. **Handle errors gracefully** - Check `hasErrors` and show user feedback
4. **Use appropriate widget** - Indicator for background, dialog for manual, overlay for blocking
5. **Test with slow networks** - Use network throttling to test UI behavior
6. **Monitor performance** - Check entity durations for optimization opportunities

## 🔧 Migration from Old Sync

If you're migrating from `sync_real_time_providers.dart`:

### Replace Old Sync Calls

**Before:**

```dart
await ref.read(syncRealTimeProvider.notifier).onSyncOrder(
  context: context,
  isAfterActivateLicense: false,
);
```

**After:**

```dart
await ref.read(appSyncServiceProvider.notifier).syncAll(
  reason: SyncReason.manualRefresh,
  context: context,
);
```

### Progress Tracking

**Before:**

```dart
ref.read(appProvider.notifier).updateSyncProgress(percentage, message);
```

**After:**

```dart
// Automatic! Just watch the state:
final syncState = ref.watch(appSyncServiceProvider);
// syncState.progress is 0.0 to 1.0
// syncState.entities contains per-entity progress
```

### Feature Parity

The new sync system includes all features from the old system:

- ✅ Pending changes sync first (with 30s timeout)
- ✅ Sync check API (selective sync based on server changes)
- ✅ Concurrency control (max 4 concurrent tasks)
- ✅ Deleted items handling
- ✅ License activation special mode
- ✅ Comprehensive error collection
- ✅ Progress tracking
- ✅ Policy-based filtering

See [SYNC_MIGRATION_NOTES.md](./SYNC_MIGRATION_NOTES.md) for detailed migration guide.

## Troubleshooting

### Sync not starting

- Check network connection
- Verify provider is initialized
- Ensure syncFromRemote() is implemented

### Progress not updating

- Confirm widget uses `ref.watch(appSyncServiceProvider)`
- Check if entity is in sync registry
- Verify policy includes the entity

### UI not showing

- Make sure widget is in widget tree
- Check if sync is actually running
- Verify state updates (add print statements)

## Example: Complete Integration

```dart
class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My App'),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => SyncProgressDialog(),
              );
              ref.read(appSyncServiceProvider.notifier).syncAll(
                reason: SyncReason.manualRefresh,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              SyncIndicator(), // Always show progress
              Expanded(child: YourContent()),
            ],
          ),
          // Block UI during critical syncs
          // SyncLoadingOverlay(),
        ],
      ),
    );
  }
}
```
