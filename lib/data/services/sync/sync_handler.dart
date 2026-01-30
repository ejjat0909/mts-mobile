/// Base interface for model-specific sync handlers
abstract class SyncHandler {
  /// Handle created event with direct data
  Future<void> handleCreated(Map<String, dynamic> data);

  /// Handle updated event with direct data
  Future<void> handleUpdated(Map<String, dynamic> data);

  /// Handle deleted event with direct data
  Future<void> handleDeleted(Map<String, dynamic> data);
}
