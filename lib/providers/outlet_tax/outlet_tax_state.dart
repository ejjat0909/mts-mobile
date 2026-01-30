import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/outlet_tax/outlet_tax_model.dart';

part 'outlet_tax_state.freezed.dart';

/// Immutable state class for OutletTax domain using Freezed
@freezed
class OutletTaxState with _$OutletTaxState {
  const factory OutletTaxState({
    @Default([]) List<OutletTaxModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _OutletTaxState;
}
