import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/modifier/modifier_model.dart';

part 'modifier_state.freezed.dart';

/// Immutable state class for Modifier domain using Freezed
@freezed
class ModifierState with _$ModifierState {
  const factory ModifierState({
    @Default([]) List<ModifierModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _ModifierState;
}
