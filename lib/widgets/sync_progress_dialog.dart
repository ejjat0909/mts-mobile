import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/sync/app_sync_service.dart';

/// A detailed dialog that shows sync progress for each entity
///
/// This dialog displays:
/// - Overall progress percentage
/// - Individual status for each syncing entity
/// - Error messages if any entity fails
/// - Duration for completed entities
///
/// Use this when you want to show detailed sync information to the user.
class SyncProgressDialog extends ConsumerWidget {
  const SyncProgressDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(appSyncServiceProvider);

    return AlertDialog(
      title: const Text('Sync Progress'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: syncState.progress),
            const SizedBox(height: 16),
            Text(
              '${(syncState.progress * 100).toInt()}% Complete',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: syncState.entities.length,
                itemBuilder: (context, index) {
                  final entry = syncState.entities.entries.elementAt(index);
                  final entityName = entry.key;
                  final entityState = entry.value;

                  IconData icon;
                  Color color;
                  String status;

                  if (entityState.isDone) {
                    icon = Icons.check_circle;
                    color = Colors.green;
                    status = 'Done';
                  } else if (entityState.error != null) {
                    icon = Icons.error;
                    color = Colors.red;
                    status = 'Failed';
                  } else if (entityState.isLoading) {
                    icon = Icons.sync;
                    color = Colors.blue;
                    status = 'Syncing...';
                  } else {
                    icon = Icons.pending;
                    color = Colors.grey;
                    status = 'Pending';
                  }

                  return ListTile(
                    dense: true,
                    leading: Icon(icon, color: color, size: 20),
                    title: Text(
                      entityName,
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: Text(
                      status,
                      style: TextStyle(fontSize: 12, color: color),
                    ),
                    subtitle:
                        entityState.error != null
                            ? Text(
                              entityState.error!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                            : entityState.duration != null
                            ? Text(
                              '${entityState.duration!.inMilliseconds}ms',
                              style: const TextStyle(fontSize: 10),
                            )
                            : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!syncState.isSyncing)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
      ],
    );
  }
}
