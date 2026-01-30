import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/printing_log/printing_log_model.dart';

part 'printing_log_state.freezed.dart';

/// Immutable state class for PrintingLog domain using Freezed
@freezed
class PrintingLogState with _$PrintingLogState {
  const factory PrintingLogState({
    @Default([]) List<PrintingLogModel> items,
    @Default([]) List<PrintingLogModel> itemsFromHive,
    String? error,
    @Default(false) bool isLoading,
  }) = _PrintingLogState;
}
