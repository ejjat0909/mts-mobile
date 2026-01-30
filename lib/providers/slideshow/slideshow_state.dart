import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';

part 'slideshow_state.freezed.dart';

/// Immutable state class for Slideshow domain using Freezed
@freezed
class SlideshowState with _$SlideshowState {
  const factory SlideshowState({
    @Default([]) List<SlideshowModel> items,
    @Default([]) List<SlideshowModel> itemsFromHive,
    String? error,
    @Default(false) bool isLoading,
    // Old ChangeNotifier fields (UI state)
    SlideshowModel? currentSlideshow,
    @Default(false) bool isPlaying,
    @Default(0) int currentSlideIndex,
  }) = _SlideshowState;
}
