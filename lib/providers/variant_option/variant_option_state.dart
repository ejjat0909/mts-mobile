import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';

part 'variant_option_state.freezed.dart';

/// Immutable state class for VariantOption domain using Freezed
@freezed
class VariantOptionState with _$VariantOptionState {
  const factory VariantOptionState({
    @Default([]) List<VariantOptionModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _VariantOptionState;
}
