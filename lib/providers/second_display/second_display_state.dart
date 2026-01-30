import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';

part 'second_display_state.freezed.dart';

/// Immutable state class for SecondDisplay domain using Freezed
@freezed
class SecondDisplayState with _$SecondDisplayState {
  const factory SecondDisplayState({
    @Default('') String currentRouteName,
    SlideshowModel? currentSdModel,
  }) = _SecondDisplayState;
}
