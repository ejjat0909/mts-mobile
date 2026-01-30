import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/staff/staff_model.dart';

part 'staff_state.freezed.dart';

/// Immutable state class for Staff domain using Freezed
@freezed
class StaffState with _$StaffState {
  const factory StaffState({
    @Default([]) List<StaffModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _StaffState;
}
