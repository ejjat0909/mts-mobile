import 'package:mts/data/models/pending_changes/pending_changes_model.dart';

abstract class LocalPendingChangesRepository {
  // ==================== CRUD Operations ====================

  /// Inserts a single pending changes record
  Future<int> insert(PendingChangesModel pendingChangesModel);

  /// Deletes a pending changes record by ID
  Future<int> delete(String id);

  // ==================== Bulk Operations ====================

  /// Inserts multiple pending changes records at once
  Future<bool> upsertBulk(List<PendingChangesModel> list);

  // ==================== Query Operations ====================

  /// Retrieves all pending changes records
  Future<List<PendingChangesModel>> getListPendingChanges();

  // ==================== Delete Operations ====================

  /// Deletes all pending changes records
  Future<void> deleteAll();

  /// Deletes records where model ID is null
  Future<int> deleteWhereModelIdIsNull();
}
