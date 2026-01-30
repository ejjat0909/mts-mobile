import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';

part 'printer_setting_state.freezed.dart';

/// Immutable state class for PrinterSetting domain using Freezed
@freezed
class PrinterSettingState with _$PrinterSettingState {
  const factory PrinterSettingState({
    @Default([]) List<PrinterSettingModel> items,
    @Default([]) List<PrinterSettingModel> itemsFromHive,
    String? error,
    @Default(false) bool isLoading,
  }) = _PrinterSettingState;
}
