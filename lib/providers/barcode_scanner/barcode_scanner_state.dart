import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/item/item_model.dart';

part 'barcode_scanner_state.freezed.dart';

/// Immutable state class for BarcodeScanner domain using Freezed
@freezed
class BarcodeScannerState with _$BarcodeScannerState {
  const factory BarcodeScannerState({
    ItemModel? scannedItem,
    @Default(false) bool isProcessing,
    String? errorMessage,
    String? currentActiveScreen,
    String? salesScreenBarcode,
    String? openOrderBodyBarcode,
    String? saveOrderDialogueBarcode,
    String? saveOrderCustomBarcode,
    String? editTableDetailDialogueBarcode,
    String? tablesBarcode,
    String? editTablesBarcode,
  }) = _BarcodeScannerState;
}
