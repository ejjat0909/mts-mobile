import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/models/page_item/page_item_model.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/sales/components/tab_list_category.dart';
import 'package:mts/presentation/features/sales/components/tab_list_item.dart';
import 'package:mts/providers/page_item/page_item_providers.dart';

class ItemAndCategorySelectionDialogue extends ConsumerStatefulWidget {
  const ItemAndCategorySelectionDialogue({
    super.key,
    required this.gridViewIndex,

    required this.pageId,
    required this.pageItem,
  });

  final int gridViewIndex;

  final String? pageId;
  final PageItemModel? pageItem;

  @override
  ConsumerState<ItemAndCategorySelectionDialogue> createState() =>
      _ItemAndCategorySelectionDialogueState();
}

class _ItemAndCategorySelectionDialogueState
    extends ConsumerState<ItemAndCategorySelectionDialogue>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabSubIndex = 0;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabSubIndex = _tabController.index;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double availableHeight = MediaQuery.of(context).size.height;
    double availableWidth = MediaQuery.of(context).size.width;
    final pageItemNotifier = ref.watch(pageItemProvider.notifier);

    // ItemModel? selectedItem =
    //     widget.saleItemNotifier.selectedItems[widget.indexx];
    // CategoryModel? selectedCategory =
    //     widget.saleItemNotifier.selectedCategories[widget.indexx];

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: availableHeight,
          minHeight: availableHeight,
          maxWidth: availableWidth / 2,
        ),
        child: Column(
          children: [
            const Space(15),
            AppBar(
              elevation: 0,
              backgroundColor: white,
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedTabSubIndex == 0
                          ? 'selectItem'.tr()
                          : 'selectCategories'.tr(),
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.h1TextStyle(),
                    ),
                  ),
                ],
              ),
              leading: IconButton(
                icon: const Icon(Icons.close, color: canvasColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  // margin: EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(vertical: 7.5),
                  decoration: BoxDecoration(
                    color: kPrimaryLightColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: TabBar(
                      padding: const EdgeInsets.symmetric(horizontal: 7.5),
                      onTap: (value) {
                        setState(() {
                          _selectedTabSubIndex = value;
                        });
                      },
                      tabAlignment: TabAlignment.center,
                      physics: const BouncingScrollPhysics(),
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: kPrimaryBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      splashFactory: InkSplash.splashFactory,
                      splashBorderRadius: BorderRadius.circular(10),
                      overlayColor: WidgetStateProperty.resolveWith<Color?>((
                        Set<WidgetState> states,
                      ) {
                        return states.contains(WidgetState.focused)
                            ? null
                            : kPrimaryColor;
                      }),
                      isScrollable: true,
                      enableFeedback: true,
                      tabs: [
                        Tab(
                          child: Text(
                            'items'.tr(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: canvasColor,
                            ),
                          ),
                        ),
                        Tab(
                          child: Text(
                            'categories'.tr(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: canvasColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  listItem(
                    pageItemNotifier,

                    widget.gridViewIndex,
                    widget.pageId,
                    widget.pageItem,
                  ),
                  listCategory(
                    pageItemNotifier,

                    widget.gridViewIndex,
                    widget.pageId,
                    widget.pageItem,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget listCategory(
    PageItemNotifier pageItemNotifier,

    int gridViewIndex,
    String? pageId,
    PageItemModel? pageItemModel,
  ) {
    return TabListCategory(
      gridViewIndex: gridViewIndex,
      pageId: pageId,
      pageItem: pageItemModel,
    );
  }

  Widget listItem(
    PageItemNotifier pageItemNotifier,

    int gridViewIndex,
    String? pageId,
    PageItemModel? pageItem,
  ) {
    return TabListItem(
      gridViewIndex: gridViewIndex,
      pageId: pageId,
      pageItem: pageItem,
    );
  }
}
