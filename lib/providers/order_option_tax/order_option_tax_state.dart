import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/order_option_tax/order_option_tax_model.dart';

part 'order_option_tax_state.freezed.dart';

/// Immutable state class for OrderOptionTax domain using Freezed
@freezed
class OrderOptionTaxState with _$OrderOptionTaxState {
  const factory OrderOptionTaxState({
    @Default([]) List<OrderOptionTaxModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _OrderOptionTaxState;
}
