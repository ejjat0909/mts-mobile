import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';

part 'split_order_state.freezed.dart';

/// Immutable state class for SplitOrder domain using Freezed
@freezed
class SplitOrderState with _$SplitOrderState {
  const factory SplitOrderState({
    @Default([[], []]) List<List<SaleItemModel>> cards,
    @Default({}) Map<int, List<SaleItemModel>> selectedItems,
    String? error,
    @Default(false) bool isLoading,
  }) = _SplitOrderState;
}
