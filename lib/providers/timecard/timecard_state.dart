import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/time_card/timecard_model.dart';

part 'timecard_state.freezed.dart';

/// Immutable state class for Timecard domain using Freezed
@freezed
class TimecardState with _$TimecardState {
  const factory TimecardState({
    @Default([]) List<TimecardModel> items,
    String? error,
    @Default(false) bool isLoading,
    // Old ChangeNotifier fields (UI state)
    TimecardModel? currentTimecard,
  }) = _TimecardState;
}
