import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';

part 'modifier_option_state.freezed.dart';

/// Immutable state class for ModifierOption domain using Freezed
@freezed
class ModifierOptionState with _$ModifierOptionState {
  const factory ModifierOptionState({
    @Default([]) List<ModifierOptionModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _ModifierOptionState;
}
