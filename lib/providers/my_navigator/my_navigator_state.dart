import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_navigator_state.freezed.dart';

/// Immutable state class for PaymentType domain using Freezed
@freezed
class MyNavigatorState with _$MyNavigatorState {
  const factory MyNavigatorState({
    @Default(2) int pageIndex,
    @Default(0) int selectedTab,
    @Default('') String headerTitle,
    @Default('') String tabTitle,
    dynamic data,
    @Default(false) bool isCloseShiftScreen,
    int? lastScreenIndex,
    int? lastPageIndex,
    String? lastHeaderTitle,
    int? lastSelectedTab,
    String? lastTabTitle,
  }) = _MyNavigatorState;
}
