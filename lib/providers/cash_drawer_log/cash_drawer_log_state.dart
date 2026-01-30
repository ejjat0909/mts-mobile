import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/cash_drawer_log/cash_drawer_log_model.dart';

part 'cash_drawer_log_state.freezed.dart';

@freezed
class CashDrawerLogState with _$CashDrawerLogState {
  const factory CashDrawerLogState({
    @Default([]) List<CashDrawerLogModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _CashDrawerLogState;
}
