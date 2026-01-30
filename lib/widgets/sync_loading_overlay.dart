import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/sync/app_sync_service.dart';

/// A full-screen loading overlay that blocks user interaction during sync
///
/// This overlay:
/// - Covers the entire screen with a semi-transparent background
/// - Shows a centered loading indicator
/// - Displays sync progress percentage
/// - Shows entity count (completed/total)
/// - Automatically hides when sync is complete
///
/// Use this when you need to prevent user interaction during critical sync operations.
class SyncLoadingOverlay extends ConsumerWidget {
  const SyncLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(appSyncServiceProvider);

    if (!syncState.isSyncing) return const SizedBox.shrink();

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Syncing ${(syncState.progress * 100).toInt()}%',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${syncState.completedEntities}/${syncState.totalEntities} entities',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
