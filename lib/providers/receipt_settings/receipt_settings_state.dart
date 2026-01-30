import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/receipt_setting/receipt_settings_model.dart';

part 'receipt_settings_state.freezed.dart';

/// Immutable state class for ReceiptSettings domain using Freezed
@freezed
class ReceiptSettingsState with _$ReceiptSettingsState {
  const factory ReceiptSettingsState({
    @Default([]) List<ReceiptSettingsModel> items,
    @Default([]) List<ReceiptSettingsModel> itemsFromHive,
    String? error,
    @Default(false) bool isLoading,
  }) = _ReceiptSettingsState;
}
