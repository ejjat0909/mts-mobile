import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_real_time_state.freezed.dart';

/// Immutable state class for Table domain using Freezed
@freezed
class SyncRealTimeState with _$SyncRealTimeState {
  const factory SyncRealTimeState() = _SyncRealTimeState;
}
