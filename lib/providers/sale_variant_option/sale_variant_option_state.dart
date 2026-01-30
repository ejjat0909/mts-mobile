import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/sale_variant_option/sale_variant_option_model.dart';

part 'sale_variant_option_state.freezed.dart';

/// Immutable state class for SaleVariantOption domain using Freezed
@freezed
class SaleVariantOptionState with _$SaleVariantOptionState {
  const factory SaleVariantOptionState({
    @Default([]) List<SaleVariantOptionModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _SaleVariantOptionState;
}
