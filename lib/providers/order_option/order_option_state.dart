import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';

part 'order_option_state.freezed.dart';

/// Immutable state class for OrderOption domain using Freezed
@freezed
class OrderOptionState with _$OrderOptionState {
  const factory OrderOptionState({
    @Default([]) List<OrderOptionModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _OrderOptionState;
}
