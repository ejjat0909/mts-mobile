import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/discount_outlet/discount_outlet_model.dart';

part 'discount_outlet_state.freezed.dart';

/// Immutable state class for DiscountOutlet domain using Freezed
@freezed
class DiscountOutletState with _$DiscountOutletState {
  const factory DiscountOutletState({
    @Default([]) List<DiscountOutletModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _DiscountOutletState;
}
