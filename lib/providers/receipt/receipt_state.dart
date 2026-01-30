import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:flutter/material.dart';

part 'receipt_state.freezed.dart';

/// Immutable state class for Receipt domain using Freezed
@freezed
class ReceiptState with _$ReceiptState {
  const factory ReceiptState({
    @Default([]) List<ReceiptModel> items,
    @Default([]) List<ReceiptModel> itemsFromHive,
    String? error,
    @Default(false) bool isLoading,
    // Old notifier UI state fields
    @Default([]) List<ReceiptItemModel> incomingRefundReceiptItems,
    @Default([]) List<ReceiptItemModel> receiptItemsForRefund,
    @Default([]) List<ReceiptItemModel> initialListReceiptItems,
    @Default([]) List<ReceiptModel> listReceiptModel,
    String? receiptIdTitle,
    @Default(0) int pageIndex,
    @Default('-1') String tempReceiptId,
    ReceiptModel? tempReceiptModel,
    // Calculation lists and totals
    @Default([]) List<Map<String, dynamic>> listTotalDiscount,
    @Default(0.0) double totalDiscount,
    @Default([]) List<Map<String, dynamic>> listTaxAfterDiscount,
    @Default([]) List<Map<String, dynamic>> listTaxIncludedAfterDiscount,
    @Default(0.0) double taxAfterDiscount,
    @Default(0.0) double taxIncludedAfterDiscount,
    @Default(0.0) double totalAfterDiscountAndTax,
    @Default([]) List<Map<String, dynamic>> listTotalAfterDiscAndTax,
    // Pagination
    PagingController<int, ReceiptModel>? listReceiptPagingController,
    int? selectedReceiptIndex,
    @Default(0) int receiptDialogueNavigator,
    // Filter state
    DateTimeRange? selectedDateRange,
    DateTimeRange? lastSelectedDateRange,
    @Default('') String formattedDateRange,
    // Payment type filter
    String? tempPaymentType,
    String? previousPaymentType,
    String? selectedPaymentType,
    @Default(-1) int tempPaymentTypeIndex,
    @Default(-1) int previousPaymentTypeIndex,
    @Default(-1) int selectedPaymentTypeIndex,
    // Order option filter
    String? tempOrderOption,
    String? previousOrderOption,
    String? selectedOrderOption,
    @Default(-1) int tempOrderOptionIndex,
    @Default(-1) int previousOrderOptionIndex,
    @Default(-1) int selectedOrderOptionIndex,
  }) = _ReceiptState;
}
