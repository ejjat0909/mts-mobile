/// Represents the overall sync state
class SyncState {
  final bool isSyncing;
  final Map<String, SyncEntityState> entities;
  final double progress; // 0.0 to 1.0
  final String? errorMessage;

  const SyncState({
    this.isSyncing = false,
    this.entities = const {},
    this.progress = 0.0,
    this.errorMessage,
  });

  SyncState copyWith({
    bool? isSyncing,
    Map<String, SyncEntityState>? entities,
    double? progress,
    String? errorMessage,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      entities: entities ?? this.entities,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  int get totalEntities => entities.length;
  int get completedEntities =>
      entities.values.where((e) => e.isDone || e.error != null).length;
  int get failedEntities =>
      entities.values.where((e) => e.error != null).length;
  bool get hasErrors => failedEntities > 0;
}

/// Represents the state of a single sync entity
class SyncEntityState {
  final bool isLoading;
  final bool isDone;
  final String? error;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const SyncEntityState({
    this.isLoading = false,
    this.isDone = false,
    this.error,
    this.startedAt,
    this.completedAt,
  });

  SyncEntityState copyWith({
    bool? isLoading,
    bool? isDone,
    String? error,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return SyncEntityState(
      isLoading: isLoading ?? this.isLoading,
      isDone: isDone ?? this.isDone,
      error: error ?? this.error,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Duration? get duration {
    if (startedAt != null && completedAt != null) {
      return completedAt!.difference(startedAt!);
    }
    return null;
  }
}
