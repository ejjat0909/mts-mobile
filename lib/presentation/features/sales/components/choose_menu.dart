import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/page_enum.dart';
import 'package:mts/core/utils/id_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/downloaded_file/downloaded_file_model.dart';
import 'package:mts/data/models/item_representation/item_representation_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/page/page_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/sales/components/dotted_container.dart';
import 'package:mts/presentation/features/sales/components/menu_item.dart';
import 'package:mts/presentation/features/sales/components/page_search_body.dart';
import 'package:mts/presentation/features/sales/components/tab_item.dart';
import 'package:mts/presentation/features/tables/tables_screen.dart';
import 'package:mts/providers/downloaded_file/downloaded_file_providers.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/page/page_providers.dart';
import 'package:mts/providers/page_item/page_item_providers.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:provider/provider.dart';

class ChooseMenu extends ConsumerStatefulWidget {
  const ChooseMenu({super.key});

  @override
  ConsumerState<ChooseMenu> createState() => _ChooseMenuState();
}

class _ChooseMenuState extends ConsumerState<ChooseMenu>
    with TickerProviderStateMixin {
  Future<void> handleOnPressPage(
    String newSelectedPageId,
    PageItemNotifier pageItemNotifier,
    List<PageModel> listPage,
  ) async {
    OutletModel outletModel = ServiceLocator.get<OutletModel>();
    final pageNotifier = ref.read(pageProvider.notifier);

    // set page id in notifier to handle every content in page tab
    if (newSelectedPageId == PageEnum.pageAddTab) {
      if (listPage.length < 5) {
        newSelectedPageId = IdUtils.generateUUID().toString();
        String pageName = 'Page ${listPage.length + 1}';
        PageModel newPageModel = PageModel(
          id: newSelectedPageId,
          pageName: pageName,
          outletId: outletModel.id,
        );
        setState(() {
          // automatically select new page
          listPage.add(newPageModel);
        });
        // add to local db

        await pageNotifier.insert(newPageModel);
      }
    }

    pageItemNotifier.setCurrentPageId(newSelectedPageId);
    pageItemNotifier.setLastPageId(newSelectedPageId);
  }

  @override
  Widget build(BuildContext context) {
    final pageItemNotifier = context.watch<PageItemNotifier>();
    final pageId = pageItemNotifier.getCurrentPageId;
    final saleItemsState = ref.watch(saleItemProvider);
    final categoryId = saleItemsState.categoryId;
    final isEditMode = saleItemsState.isEditMode;
    final listPage = pageItemNotifier.getListPage;
    return Expanded(
      flex: 5,
      child: Builder(
        builder: (context) {
          return Container(
            color: kPrimaryLightColor,
            padding: const EdgeInsets.all(0),
            child: Column(
              children: [
                getChooseMenuBody(
                  categoryId,
                  pageId,
                  // pageItemModels,
                ),
                pageId != PageEnum.pageSearchItem
                    ? Row(children: [..._getPages(isEditMode, listPage)])
                    : const Row(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget getChooseMenuBody(String categoryId, String? pageId) {
    const int crossAxisCount = 5; // Number of items per row
    const double crossAxisSpacing = 10.0; // Horizontal spacing
    const double mainAxisSpacing = 10.0; // Vertical spacing
    final itemNotifier = ref.read(itemProvider.notifier);
    final downloadedFileNotifier = ref.watch(downloadedFileProvider.notifier);

    if (categoryId != '') {
      // when user press category in choose menu screen
      // this function filter the item by category id and do search query from the filtered item
      final filteredListItem = itemNotifier.getFilteredItemList(categoryId);

      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount, // Number of items per row
              crossAxisSpacing: crossAxisSpacing, // Horizontal spacing
              mainAxisSpacing: mainAxisSpacing, // Vertical spacing
              childAspectRatio:
                  MediaQuery.of(context).size.height *
                  0.15 /
                  100, // dont change this value
            ),
            itemCount: filteredListItem.length,
            itemBuilder: (context, index) {
              if (filteredListItem.isNotEmpty) {
                final itemModel = filteredListItem[index];
                final itemRepresentationModel = itemNotifier
                    .getListItemRepresentations
                    .firstWhere(
                      (element) =>
                          element.id == itemModel.itemRepresentationId!,
                      orElse: () => ItemRepresentationModel(),
                    );

                final downloadedFileModel = downloadedFileNotifier
                    .getListDownloadedFiles
                    .firstWhere(
                      (element) =>
                          element.url == itemRepresentationModel.downloadUrl,
                      orElse: () => DownloadedFileModel(),
                    );

                return MenuItem(
                  itemModel: itemModel,
                  index: index,
                  itemRepresentationModel: itemRepresentationModel,
                  downloadedFileModel: downloadedFileModel,
                );
              } else {
                return Container(
                  decoration: BoxDecoration(
                    color: kPrimaryLightColor,
                    borderRadius: BorderRadius.circular(7.5),
                    border: Border.all(width: 0.5),
                  ),
                );
              }
            },
          ),
        ),
      );
    } else if (pageId == PageEnum.pageTableLayout) {
      return const Expanded(child: Text('New Page to table layout'));
    } else if (pageId == PageEnum.pageSearchItem) {
      return Builder(
        builder: (parentContext) {
          return PageSearchBody(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            context: parentContext,
          );
        },
      );
    } else {
      const int itemsPerRow = 5;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              buildDottedRow(1, itemsPerRow, crossAxisSpacing),
              const Space(mainAxisSpacing),
              buildDottedRow(6, itemsPerRow, crossAxisSpacing),
              const Space(mainAxisSpacing),
              buildDottedRow(11, itemsPerRow, crossAxisSpacing),
              const Space(mainAxisSpacing),
              buildDottedRow(16, itemsPerRow, crossAxisSpacing),
            ],
          ),
        ),
      );
    }
  }

  /// Builds a row of [DottedContainer] widgets with specified starting index, count, and spacing.
  ///
  /// The `startIndex` parameter determines the starting index for the `DottedContainer` widgets.
  /// The `count` parameter specifies the number of `DottedContainer` widgets in the row.
  /// The `spacing` parameter sets the spacing between the `DottedContainer` widgets.
  ///
  /// Each `DottedContainer` is wrapped in an `Expanded` widget to evenly distribute the available space.
  /// A `SizedBox` is used for spacing between the `DottedContainer` widgets, except after the last widget in the row.
  Widget buildDottedRow(int startIndex, int count, double spacing) {
    return Expanded(
      child: Row(
        children: List.generate(count, (index) {
          return Expanded(
            child: Row(
              children: [
                Expanded(child: DottedContainer(index: startIndex + index)),
                if (index < count - 1) SizedBox(width: spacing),
              ],
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _getPages(bool isEditMode, List<PageModel> listPageFromDb) {
    List<Widget> listPages = [];
    final featureCompanyNotifier = ref.read(featureCompanyProvider.notifier);
    final saleItemsNotifier = ref.read(saleItemProvider.notifier);
    final pageItemNotifier = ref.read(pageItemProvider.notifier);

    final isTableLayoutActive = featureCompanyNotifier.isTableLayoutActive();
    for (final (index, element) in listPageFromDb.indexed) {
      listPages.add(
        TabItem(
          totalPages: listPageFromDb.length,
          isEditMode: isEditMode,
          pageModel: element,
          isSelected: pageItemNotifier.getCurrentPageId == element.id,
          onPressed: () {
            handleOnPressPage(element.id!, pageItemNotifier, listPageFromDb);

            saleItemsNotifier.setCategoryId('');
          },
          index: index, // Pass the current index
        ),
      );
    }

    if (isTableLayoutActive) {
      if (!isEditMode) {
        listPages.add(
          TabItem(
            totalPages: listPageFromDb.length,
            isIcon: true,
            isSelected:
                pageItemNotifier.getCurrentPageId == PageEnum.pageTableLayout,
            index: -1,
            onPressed: () async {
              //handleOnPressPage(PageEnum.PAGE_TABLE_LAYOUT, pageItemNotifier);
              final result = await Navigator.push(
                context,
                NavigationUtils.createRoute(newScreen: const TablesScreen()),
              );

              if (result != null && result is TableModel) {
                await _handleTableCallback(result, saleItemsNotifier);
              }
            },
          ),
        );
      }
    }

    // add pages
    if (isEditMode && listPageFromDb.length < 5) {
      listPages.add(
        TabItem(
          totalPages: listPageFromDb.length,
          index: -2,
          isEditMode: isEditMode,
          isIcon: true,
          isSelected: false,
          // always false
          onPressed: () {
            handleOnPressPage(
              PageEnum.pageAddTab,
              pageItemNotifier,
              listPageFromDb,
            );
          },
        ),
      );
    }
    return listPages;
  }

  Future<void> _handleTableCallback(
    TableModel table,
    SaleItemNotifier saleItemsNotifier,
  ) async {
    final predefinedOrderNotifier = ref.read(predefinedOrderProvider.notifier);
    final pom = await predefinedOrderNotifier.getPredefinedOrderById(
      table.predefinedOrderId,
    );
    saleItemsNotifier.setSelectedTable(table);
    if (pom != null && pom.id != null) {
      saleItemsNotifier.setPredefinedOrderModel(pom);
    }
    // reset current sale model so can make new sale
    saleItemsNotifier.setCurrSaleModel(SaleModel());
  }
}
