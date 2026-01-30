import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/pending_changes/pending_changes_model.dart';

part 'pending_changes_state.freezed.dart';

/// Immutable state class for PendingChanges domain using Freezed
@freezed
class PendingChangesState with _$PendingChangesState {
  const factory PendingChangesState({
    @Default([]) List<PendingChangesModel> items,
    String? error,
    @Default(false) bool isLoading,
    @Default(false) bool isSyncing,
  }) = _PendingChangesState;
}
