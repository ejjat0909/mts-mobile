/// Constants for pending change operations
/// Used for tracking data modifications that need to be synced
class PendingChangeOperation {
  /// Record was created locally
  static const String created = 'created';

  /// Record was updated locally
  static const String updated = 'updated';

  /// Record was deleted locally
  static const String deleted = 'deleted';
}
