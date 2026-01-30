import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/polymorphic_enum.dart';
import 'package:mts/data/models/inventory/inventory_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/page_item/page_item_model.dart';
import 'package:mts/presentation/common/widgets/my_text_form_field.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/sales/components/item_list_tile.dart';
import 'package:mts/providers/inventory/inventory_providers.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/page_item/page_item_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';

class TabListItem extends ConsumerStatefulWidget {
  final int gridViewIndex;
  final String? pageId;
  final PageItemModel? pageItem;

  const TabListItem({
    super.key,
    required this.gridViewIndex,
    required this.pageId,
    required this.pageItem,
  });

  @override
  ConsumerState<TabListItem> createState() => _TabListItemState();
}

class _TabListItemState extends ConsumerState<TabListItem> {
  TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  List<ItemModel> filteredItems = [];
  List<ItemModel> listItem = [];
  List<InventoryModel?> filteredInventoryModels = [];
  List<InventoryModel?> listInventoryModel = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    //  ItemBloc.fetchItemStreamController.close();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final data = await ref.read(itemProvider.notifier).getListItemModel();
    final List<InventoryModel?> inventoryModels = [];

    for (var item in data) {
      final invModel = await ref.read(inventoryProvider.notifier).getInventoryModelById(
        item.inventoryId ?? '',
      );
      inventoryModels.add(invModel);
    }

    setState(() {
      listItem = data;
      listInventoryModel = inventoryModels;
      filteredItems = listItem;
      filteredInventoryModels = listInventoryModel;
    });
  }

  void _onSearchChanged() {
    String query = searchController.text.toLowerCase();
    setState(() {
      final filteredIndices = <int>[];
      for (int i = 0; i < listItem.length; i++) {
        final item = listItem[i];
        if ((item.name?.toLowerCase() ?? '').contains(query) ||
            (item.barcode?.toLowerCase() ?? '').contains(query)) {
          filteredIndices.add(i);
        }
      }

      filteredItems = filteredIndices.map((i) => listItem[i]).toList();
      filteredInventoryModels =
          filteredIndices.map((i) => listInventoryModel[i]).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final saleItemsNotifier = ref.watch(saleItemProvider.notifier);
    return SizedBox(
      width: double.maxFinite,
      child: Column(
        children: [
          const Space(10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MyTextFormField(
              controller: searchController,
              labelText: 'search'.tr(),
              hintText: 'searchNameOrBarcode'.tr(),
              leading: Padding(
                padding: EdgeInsets.only(
                  top: 10.h,
                  left: 10.w,
                  right: 10.w,
                  bottom: 10.h,
                ),
                child: const Icon(FontAwesomeIcons.magnifyingGlass, color: kBg),
              ),
            ),
          ),
          Expanded(
            child:
                filteredItems.isEmpty
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Space(100.h),
                        const Icon(
                          Icons.inventory_2_rounded,
                          size: 75,
                          color: kTextGray,
                        ),
                        Space(20.h),
                        Text('noItem'.tr(), style: AppTheme.mediumTextStyle()),
                      ],
                    )
                    : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return ItemListTile(
                          itemModel: filteredItems[index],
                          inventoryModel:
                              filteredInventoryModels[index] ??
                              InventoryModel(),
                          onPressed: () async {
                            saleItemsNotifier.setSelectedCategory(
                              widget.gridViewIndex,
                              null,
                            );
                            saleItemsNotifier.setSelectedItem(
                              widget.gridViewIndex,
                              filteredItems[index],
                            );

                            await ref.read(pageItemProvider.notifier).setPageItemType(
                              type: PolymorphicEnum.item,
                              pageId: widget.pageId,
                              sort: widget.gridViewIndex,
                              pageItemableId: filteredItems[index].id!,
                            );

                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
