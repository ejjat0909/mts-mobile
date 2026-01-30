import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';

part 'refund_state.freezed.dart';

/// Immutable state class for Refund domain using Freezed
/// Tracks refund processing, printing status, and errors in real-time
/// Also manages refund item selection and calculations
@freezed
class RefundState with _$RefundState {
  const factory RefundState({
    String? error,
    @Default(false) bool isLoading,
    @Default(false) bool isPrinting,
    String? currentReceiptId,
    @Default(0) int refundItemsCount,
    @Default([]) List<String> printErrors,
    @Default(0) int printersCompleted,
    @Default(0) int printersTotal,
    // Refund item selection and calculations
    @Default([]) List<ReceiptItemModel> refundItems,
    @Default([]) List<ReceiptItemModel> originRefundItems,
    @Default(0.0) double totalDiscount,
    @Default(0.0) double taxAfterDiscount,
    @Default(0.0) double taxIncludedAfterDiscount,
    @Default(0.0) double totalAfterDiscountAndTax,
    // Old notifier internal calculation lists
    @Default([]) List<Map<String, dynamic>> listTotalDiscount,
    @Default([]) List<Map<String, dynamic>> listTaxAfterDiscount,
    @Default([]) List<Map<String, dynamic>> listTaxIncludedAfterDiscount,
    @Default([]) List<Map<String, dynamic>> listTotalAfterDiscAndTax,
  }) = _RefundState;
}
