import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';

part 'predefined_order_state.freezed.dart';

/// Immutable state class for PredefinedOrder domain using Freezed
@freezed
class PredefinedOrderState with _$PredefinedOrderState {
  const factory PredefinedOrderState({
    @Default([]) List<PredefinedOrderModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _PredefinedOrderState;
}
