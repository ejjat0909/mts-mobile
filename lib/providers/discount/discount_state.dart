import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/discount/discount_model.dart';

part 'discount_state.freezed.dart';

/// Immutable state class for Discount domain using Freezed
@freezed
class DiscountState with _$DiscountState {
  const factory DiscountState({
    @Default([]) List<DiscountModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _DiscountState;
}
