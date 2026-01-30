import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/providers/dialog_navigator/dialog_navigator_state.dart';

/// StateNotifier for DialogueNavigator
///
/// Migrated from: dialogue_navigator.dart (ChangeNotifier)
class DialogNavigatorNotifier extends StateNotifier<DialogNavigatorState> {
  DialogNavigatorNotifier() : super(const DialogNavigatorState());

  /// Get current page index
  int get getPageIndex => state.pageIndex;

  /// Set page index
  void setPageIndex(int index) {
    state = state.copyWith(pageIndex: index);
  }

  /// Reset to initial state
  void reset() {
    state = state.copyWith(pageIndex: DialogNavigatorEnum.reset);
  }
}

/// Provider for DialogueNavigator
final dialogNavigatorProvider =
    StateNotifierProvider<DialogNavigatorNotifier, DialogNavigatorState>((ref) {
      return DialogNavigatorNotifier();
    });
