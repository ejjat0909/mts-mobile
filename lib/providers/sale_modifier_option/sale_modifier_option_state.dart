import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';

part 'sale_modifier_option_state.freezed.dart';

/// Immutable state class for SaleModifierOption domain using Freezed
@freezed
class SaleModifierOptionState with _$SaleModifierOptionState {
  const factory SaleModifierOptionState({
    @Default([]) List<SaleModifierOptionModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _SaleModifierOptionState;
}
