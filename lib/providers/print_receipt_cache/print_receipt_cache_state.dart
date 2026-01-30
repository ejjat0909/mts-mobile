import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/print_receipt_cache/print_receipt_cache_model.dart';

part 'print_receipt_cache_state.freezed.dart';

/// Immutable state class for PrintReceiptCache domain using Freezed
@freezed
class PrintReceiptCacheState with _$PrintReceiptCacheState {
  const factory PrintReceiptCacheState({
    @Default([]) List<PrintReceiptCacheModel> items,
    @Default([]) List<PrintReceiptCacheModel> itemsFromHive,
    String? error,
    @Default(false) bool isLoading,
  }) = _PrintReceiptCacheState;
}
