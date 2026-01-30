import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/shift/shift_model.dart';

part 'shift_state.freezed.dart';

/// Immutable state class for Shift domain using Freezed
@freezed
class ShiftState with _$ShiftState {
  const factory ShiftState({
    @Default([]) List<ShiftModel> items,
    String? error,
    @Default(false) bool isLoading,
    // UI state properties migrated from old ShiftNotifier
    @Default(false) bool isCloseShift,
    @Default(false) bool isPressCloseShift,
    @Default(true) bool isOpenShift,
    @Default(false) bool isPrintReport,
    @Default(false) bool isPrintItem,
    @Default(0.00) double differenceAmount,
    @Default('') String shiftHistoryTitle,
    ShiftModel? currShiftModel,
  }) = _ShiftState;
}
