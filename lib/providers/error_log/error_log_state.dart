import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/error_log/error_log_model.dart';

part 'error_log_state.freezed.dart';

/// Immutable state class for ErrorLog domain using Freezed
@freezed
class ErrorLogState with _$ErrorLogState {
  const factory ErrorLogState({
    @Default([]) List<ErrorLogModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _ErrorLogState;
}
