import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/polymorphic_enum.dart';
import 'package:mts/data/models/category/category_model.dart';
import 'package:mts/data/models/page_item/page_item_model.dart';
import 'package:mts/presentation/common/widgets/my_text_form_field.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/sales/components/category_list_tile.dart';
import 'package:mts/providers/category/category_providers.dart';
import 'package:mts/providers/page_item/page_item_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';

class TabListCategory extends ConsumerStatefulWidget {

  final int gridViewIndex;
  final String? pageId;
  final PageItemModel? pageItem;

  const TabListCategory({
    super.key,
    required this.gridViewIndex,
    required this.pageId,
    this.pageItem,
  });

  @override
  ConsumerState<TabListCategory> createState() => _TabListCategoryState();
}

class _TabListCategoryState extends ConsumerState<TabListCategory> {
  TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  List<CategoryModel> filteredCategories = [];
  List<CategoryModel> listCategories = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final data = await ref.read(categoryProvider.notifier).getListCategoryModel();
    setState(() {
      listCategories = data;
      filteredCategories = listCategories; // Default: show all items
    });
  }

  void _onSearchChanged() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredCategories =
          listCategories
              .where((cat) => (cat.name?.toLowerCase() ?? '').contains(query))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final saleItemsNotifier = ref.watch(saleItemProvider.notifier);
    return SizedBox(
      width: double.maxFinite,
      child: Builder(
        builder: (context) {
          return Column(
            children: [
              const Space(10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MyTextFormField(
                  controller: searchController,
                  labelText: 'search'.tr(),
                  hintText: 'searchCategory'.tr(),
                  leading: Padding(
                    padding: EdgeInsets.only(
                      top: 10.h,
                      left: 10.w,
                      right: 10.w,
                      bottom: 10.h,
                    ),
                    child: const Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: kBg,
                    ),
                  ),
                ),
              ),
              Expanded(
                child:
                    filteredCategories.isEmpty
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Space(100.h),
                            const Icon(
                              FontAwesomeIcons.bowlFood,
                              size: 75,
                              color: kTextGray,
                            ),
                            Space(20.h),
                            Text(
                              'noCategory'.tr(),
                              style: AppTheme.mediumTextStyle(),
                            ),
                          ],
                        )
                        : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: filteredCategories.length,
                          itemBuilder: (context, index) {
                            return CategoryListTile(
                              categoryModel: filteredCategories[index],
                              onTap: () {
                                saleItemsNotifier.setSelectedItem(
                                  widget.gridViewIndex,
                                  null,
                                );
                                saleItemsNotifier.setSelectedCategory(
                                  widget.gridViewIndex,
                                  filteredCategories[index],
                                );

                                ref.read(pageItemProvider.notifier).setPageItemType(
                                  type: PolymorphicEnum.category,
                                  pageId: widget.pageId,
                                  sort: widget.gridViewIndex,
                                  pageItemableId: filteredCategories[index].id!,
                                );
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}
