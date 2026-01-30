import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/page_item/page_item_model.dart';

part 'page_item_state.freezed.dart';

/// Immutable state class for PageItem domain using Freezed
@freezed
class PageItemState with _$PageItemState {
  const factory PageItemState({
    @Default([]) List<PageItemModel> items,
    String? error,
    @Default(false) bool isLoading,
    // Old ChangeNotifier fields (UI state)
    @Default('') String type,
    String? lastPageId,
    String? currentPageId,
  }) = _PageItemState;
}
