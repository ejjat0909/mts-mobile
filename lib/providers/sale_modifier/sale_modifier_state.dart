import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';

part 'sale_modifier_state.freezed.dart';

/// Immutable state class for SaleModifier domain using Freezed
@freezed
class SaleModifierState with _$SaleModifierState {
  const factory SaleModifierState({
    @Default([]) List<SaleModifierModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _SaleModifierState;
}
