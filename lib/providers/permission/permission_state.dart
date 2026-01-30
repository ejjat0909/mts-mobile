import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/permission/permission_model.dart';

part 'permission_state.freezed.dart';

/// Immutable state class for Permission domain using Freezed
@freezed
class PermissionState with _$PermissionState {
  const factory PermissionState({
    @Default([]) List<PermissionModel> items,
    String? error,
    @Default(false) bool isLoading,
    // Old notifier compatibility - staff permission list
    @Default([]) List<PermissionModel> listStaffPM,
  }) = _PermissionState;
}
