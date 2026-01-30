import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/cash_management/cash_management_model.dart';

part 'cash_management_state.freezed.dart';

/// Immutable state class for CashManagement domain using Freezed
@freezed
class CashManagementState with _$CashManagementState {
  const factory CashManagementState({
    @Default([]) List<CashManagementModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _CashManagementState;
}
