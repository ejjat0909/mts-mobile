import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/sync/app_sync_service.dart';

/// A compact widget that shows the current sync progress as a card
///
/// This widget automatically shows/hides based on sync state.
/// Use this in your main layout to show non-intrusive sync progress.
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(appSyncServiceProvider);

    if (!syncState.isSyncing && syncState.completedEntities == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (syncState.isSyncing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (syncState.hasErrors)
                  const Icon(Icons.error, color: Colors.red, size: 16)
                else
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  syncState.isSyncing
                      ? 'Syncing...'
                      : syncState.hasErrors
                      ? 'Sync completed with errors'
                      : 'Sync completed',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: syncState.progress),
            const SizedBox(height: 4),
            Text(
              '${syncState.completedEntities}/${syncState.totalEntities} entities synced',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (syncState.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                syncState.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
