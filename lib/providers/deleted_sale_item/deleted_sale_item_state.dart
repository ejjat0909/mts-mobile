import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/deleted_sale_item/deleted_sale_item_model.dart';

part 'deleted_sale_item_state.freezed.dart';

/// Immutable state class for DeletedSaleItem domain using Freezed
@freezed
class DeletedSaleItemState with _$DeletedSaleItemState {
  const factory DeletedSaleItemState({
    @Default([]) List<DeletedSaleItemModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _DeletedSaleItemState;
}
