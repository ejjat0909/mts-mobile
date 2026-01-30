import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/deleted/deleted_model.dart';

part 'deleted_state.freezed.dart';

/// Immutable state class for Deleted domain using Freezed
@freezed
class DeletedState with _$DeletedState {
  const factory DeletedState({
    @Default([]) List<DeletedModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _DeletedState;
}
