import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';

part 'receipt_item_state.freezed.dart';

/// Immutable state class for ReceiptItem domain using Freezed
@freezed
class ReceiptItemState with _$ReceiptItemState {
  const factory ReceiptItemState({
    @Default([]) List<ReceiptItemModel> items,
    @Default([]) List<ReceiptItemModel> itemsFromHive,
    String? error,
    @Default(false) bool isLoading,
  }) = _ReceiptItemState;
}
