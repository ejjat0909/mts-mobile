import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';

part 'dialog_navigator_state.freezed.dart';

/// Immutable state class for DialogueNavigator using Freezed
@freezed
class DialogNavigatorState with _$DialogNavigatorState {
  const factory DialogNavigatorState({
    @Default(DialogNavigatorEnum.reset) int pageIndex,
  }) = _DialogNavigatorState;
}
