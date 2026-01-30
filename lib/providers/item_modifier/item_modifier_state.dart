import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/item_modifier/item_modifier_model.dart';

part 'item_modifier_state.freezed.dart';

/// Immutable state class for ItemModifier domain using Freezed
@freezed
class ItemModifierState with _$ItemModifierState {
  const factory ItemModifierState({
    @Default([]) List<ItemModifierModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _ItemModifierState;
}
