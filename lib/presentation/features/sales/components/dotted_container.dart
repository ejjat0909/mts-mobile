import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/polymorphic_enum.dart';
import 'package:mts/data/models/downloaded_file/downloaded_file_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/item_representation/item_representation_model.dart';
import 'package:mts/data/models/page_item/page_item_model.dart';
import 'package:mts/presentation/common/widgets/empty_dotted_container.dart';
import 'package:mts/presentation/features/sales/components/category_item.dart';
import 'package:mts/presentation/features/sales/components/item_and_category_selection_dialog.dart';
import 'package:mts/presentation/features/sales/components/menu_item.dart';
import 'package:mts/providers/page_item/page_item_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/downloaded_file/downloaded_file_providers.dart';
import 'package:mts/providers/category/category_providers.dart';

class DottedContainer extends ConsumerStatefulWidget {
  final int index;

  const DottedContainer({super.key, required this.index});

  @override
  ConsumerState<DottedContainer> createState() => _DottedContainerState();
}

class _DottedContainerState extends ConsumerState<DottedContainer> {
  void _showItemSelectionDialog(
    BuildContext context,

    PageItemModel? pageItem,
    String? pageId,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return ItemAndCategorySelectionDialogue(
          gridViewIndex: widget.index,

          pageId: pageId,
          pageItem: pageItem,
        );
      },
    );
  }

  // remove selected item or category
  Future<void> _removeSelectedItem(
    PageItemNotifier pageItemNotifier,
    SaleItemNotifier saleItemNotifier,
    PageItemModel pageItemModel,
  ) async {
    saleItemNotifier.setSelectedItem(widget.index, null);
    await pageItemNotifier.removePageItem(pageItemModel: pageItemModel);
  }

  @override
  Widget build(BuildContext context) {
    final saleItemsNotifier = ref.watch(saleItemProvider.notifier);
    final saleItemsState = ref.watch(saleItemProvider);
    return Consumer(
      builder: (context, ref, child) {
        final pageItemNotifier = ref.watch(pageItemProvider.notifier);
        final itemNotifier = ref.watch(itemProvider.notifier);
        final downloadedFileNotifier = ref.watch(
          downloadedFileProvider.notifier,
        );
        bool isEditMode = saleItemsState.isEditMode;

        String? pageId = pageItemNotifier.getCurrentPageId;

        PageItemModel pageItemModel = pageItemNotifier.getPageItemModelBySort(
          widget.index,
        );

        return Material(
          color: Colors.transparent,
          child: Ink(
            decoration: const BoxDecoration(color: Colors.transparent),
            child: InkWell(
              onLongPress: () {
                saleItemsNotifier.setModeEdit(true);
              },
              onTap: () {
                if (isEditMode) {
                  _showItemSelectionDialog(context, pageItemModel, pageId);
                }
              },
              splashColor: kPrimaryLightColor,
              highlightColor: white,
              child: FutureBuilder(
                future: getItemOrCategoryOrDotted(
                  pageItemNotifier,
                  saleItemsNotifier,
                  pageItemModel,
                  itemNotifier,
                  isEditMode,
                  downloadedFileNotifier,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  }
                  if (snapshot.hasData) {
                    return snapshot.data!;
                  }

                  return EmptyDottedContainer(isEditMode: isEditMode);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Widget> getItemOrCategoryOrDotted(
    PageItemNotifier pageItemNotifier,
    SaleItemNotifier saleItemNotifier,
    PageItemModel pageItemModel,
    ItemNotifier itemNotifier,
    bool isEditMode,
    DownloadedFileNotifier downloadFileNotifier,
  ) async {
    if (pageItemModel.id != null) {
      if (pageItemModel.pageItemableType == PolymorphicEnum.item) {
        ItemModel? itemModel = itemNotifier.getItemById(
          pageItemModel.pageItemableId!,
        );

        final itemRepresentationModel = itemNotifier.getListItemRepresentations
            .firstWhere(
              (element) => element.id == itemModel.itemRepresentationId,
              orElse: () => ItemRepresentationModel(),
            );

        final downloadedFileModel = downloadFileNotifier.getListDownloadedFiles
            .firstWhere(
              (element) => element.url == itemRepresentationModel.downloadUrl,
              orElse: () => DownloadedFileModel(),
            );

        if (itemModel.id != null) {
          //  prints('Item Name ${itemModel.name}');
          if (isEditMode) {
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: MenuItem(
                    itemModel: itemModel,
                    index: widget.index,
                    itemRepresentationModel: itemRepresentationModel,
                    downloadedFileModel: downloadedFileModel,
                  ),
                ),
                // ada pangkah button
                Positioned(
                  top: 0,
                  left: 0,
                  child: ScaleTap(
                    onPressed: () async {
                      await _removeSelectedItem(
                        pageItemNotifier,
                        saleItemNotifier,
                        pageItemModel,
                      );
                    },
                    child: const Icon(
                      FontAwesomeIcons.solidCircleXmark,
                      size: 26,
                      color: kTextRed,
                    ),
                  ),
                ),
              ],
            );
          } else {
            //  prints('Index ${widget.index}');
            return MenuItem(
              itemModel: itemModel,
              index: widget.index,
              itemRepresentationModel: itemRepresentationModel,
              downloadedFileModel: downloadedFileModel,
            );
          }
        } else {}
      } else if (pageItemModel.pageItemableType == PolymorphicEnum.category) {
        final categoryModel = await ref
            .read(categoryProvider.notifier)
            .getCategoryModelById(pageItemModel.pageItemableId!);
        if (categoryModel?.id != null) {
          if (isEditMode) {
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: CategoryItem(categoryModel: categoryModel!),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: ScaleTap(
                    onPressed: () async {
                      await _removeSelectedItem(
                        pageItemNotifier,
                        saleItemNotifier,
                        pageItemModel,
                      );
                    },
                    child: const Icon(
                      FontAwesomeIcons.solidCircleXmark,
                      size: 26,
                      color: kTextRed,
                    ),
                  ),
                ),
              ],
            );
          } else {
            return CategoryItem(categoryModel: categoryModel!);
          }
        }
      }
    }

    return EmptyDottedContainer(isEditMode: isEditMode);
  }
}
