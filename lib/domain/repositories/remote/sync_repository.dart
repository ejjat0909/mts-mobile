import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/pending_changes/pending_changes_sync_request_model.dart';

/// Interface for Remote Sync Repository
abstract class SyncRepository {
  /// Sync user list
  Resource syncPendingChanges(PendingChangesSyncRequestModel requestModel);

  /// Check models to sync
  Resource syncCheck({required Map<String, dynamic> data});
}
