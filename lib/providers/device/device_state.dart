import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/pos_device/pos_device_model.dart';

part 'device_state.freezed.dart';

/// Immutable state class for Device domain using Freezed
@freezed
class DeviceState with _$DeviceState {
  const factory DeviceState({
    @Default([]) List<PosDeviceModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _DeviceState;
}
