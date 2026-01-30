import 'package:mts/data/models/pending_changes/pending_changes_model.dart';

/// Abstraction for tracking pending changes for synchronization
abstract class IPendingChangesTracker {
  /// Record a pending change
  Future<void> track(PendingChangesModel change);

  /// Record multiple pending changes
  Future<void> trackBatch(List<PendingChangesModel> changes);
}
