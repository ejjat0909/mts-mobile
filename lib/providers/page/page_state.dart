import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mts/data/models/page/page_model.dart';

part 'page_state.freezed.dart';

/// Immutable state class for Page domain using Freezed
@freezed
class PageState with _$PageState {
  const factory PageState({
    @Default([]) List<PageModel> items,
    String? error,
    @Default(false) bool isLoading,
  }) = _PageState;
}
