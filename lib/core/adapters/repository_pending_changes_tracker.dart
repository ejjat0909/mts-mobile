import 'package:mts/core/interfaces/i_pending_changes_tracker.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';
import 'package:mts/domain/repositories/local/pending_changes_repository.dart';

/// Repository-based implementation of IPendingChangesTracker
class RepositoryPendingChangesTracker implements IPendingChangesTracker {
  final LocalPendingChangesRepository _repository;

  RepositoryPendingChangesTracker(this._repository);

  @override
  Future<void> track(PendingChangesModel change) async {
    await _repository.insert(change);
  }

  @override
  Future<void> trackBatch(List<PendingChangesModel> changes) async {
    await Future.wait(changes.map((change) => _repository.insert(change)));
  }
}
