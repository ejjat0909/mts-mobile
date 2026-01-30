import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/providers/my_navigator/my_navigator_state.dart';
import 'package:mts/providers/page/page_providers.dart';
import 'package:mts/providers/page_item/page_item_providers.dart';

/// StateNotifier for MyNavigator
class MyNavigatorNotifier extends StateNotifier<MyNavigatorState> {
  bool get getIsCloseShiftScreen => state.isCloseShiftScreen;
  int get pageIndex => state.pageIndex;
  int get selectedTab => state.selectedTab;
  String get headerTitle => state.headerTitle;
  String get tabTitle => state.tabTitle;
  dynamic get data => state.data;
  int? get lastPageIndex => state.lastPageIndex;
  String? get lastHeaderTitle => state.lastHeaderTitle;
  int? get lastSelectedTab => state.lastSelectedTab;
  String? get lastTabTitle => state.lastTabTitle;
  int? get lastScreenIndex => state.lastScreenIndex;

  final Ref _ref;

  MyNavigatorNotifier({required Ref ref})
    : _ref = ref,
      super(const MyNavigatorState());

  void setPageIndex(int index, String headerTitle, {dynamic data}) {
    if (state.pageIndex != index) {
      state = state.copyWith(
        pageIndex: index,
        selectedTab: state.selectedTab,
        headerTitle: headerTitle,
        data: data,
      );
    }
  }

  void setLastScreenIndex(int index) {
    state = state.copyWith(lastScreenIndex: index);
  }

  // use to hide drawer icon
  void setIsCloseShiftScreen(bool value) {
    state = state.copyWith(isCloseShiftScreen: value);
  }

  void setSelectedTab(int index, String tabTitle, {dynamic data}) {
    // If not repressed the same tab
    if (state.selectedTab != index) {
      state = state.copyWith(
        selectedTab: index,
        tabTitle: tabTitle,
        data: data,
      );
    }
  }

  void setLastPageIndex(int? index, String? headerTitle) {
    state = state.copyWith(lastPageIndex: index, lastHeaderTitle: headerTitle);
  }

  void setLastSelectedTab(int? index, String? tabTitle) {
    state = state.copyWith(lastSelectedTab: index, lastTabTitle: tabTitle);
  }

  Future<void> setUINavigatorAndIndex() async {
    final pageItemNotifier = _ref.read(pageItemProvider.notifier);
    final pageNotifier = _ref.read(pageProvider.notifier);
    final pageModel = await pageNotifier.getFirstPage();

    if (state.lastPageIndex != null && state.lastSelectedTab != null) {
      prints('ADE LAST INDEX ${state.lastPageIndex}');
      prints('ADE LAST INDEX ${state.lastSelectedTab}');
      setPageIndex(state.lastPageIndex!, state.lastHeaderTitle!);
      // await to get context for the index, then change the tab
      await Future.delayed(const Duration(milliseconds: 100));
      setSelectedTab(state.lastSelectedTab!, state.lastTabTitle!);
      pageItemNotifier.setCurrentPageId(pageModel.id!);
      pageItemNotifier.setLastPageId(pageModel.id!);

      setLastPageIndex(null, null);
      setLastSelectedTab(null, null);
    }
    prints('setUINavigatorAndIndex');
    prints(state.pageIndex);
  }
}

/// Provider for MyNavigator
final myNavigatorProvider =
    StateNotifierProvider<MyNavigatorNotifier, MyNavigatorState>(
      (ref) => MyNavigatorNotifier(ref: ref),
    );
