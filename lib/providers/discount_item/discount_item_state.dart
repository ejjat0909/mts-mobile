import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/discount_item/discount_item_model.dart';

part 'discount_item_state.freezed.dart';

/// Immutable state class for DiscountItem domain using Freezed
@freezed
class DiscountItemState with _$DiscountItemState {
  const factory DiscountItemState({
    @Default([]) List<DiscountItemModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _DiscountItemState;
}
