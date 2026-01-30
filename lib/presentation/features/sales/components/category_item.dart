import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/color_utils.dart';
import 'package:mts/core/utils/ui_utils.dart';
import 'package:mts/data/models/category/category_model.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';

class CategoryItem extends ConsumerStatefulWidget {
  final CategoryModel categoryModel;

  const CategoryItem({super.key, required this.categoryModel});

  @override
  ConsumerState<CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends ConsumerState<CategoryItem> {
  @override
  Widget build(BuildContext context) {
    final saleItemsState = ref.watch(saleItemProvider);
    final saleItemsNotifier = ref.watch(saleItemProvider.notifier);
    bool isEditMode = saleItemsState.isEditMode;
    bool isDarkColor = false;
    if (widget.categoryModel.color != null) {
      isDarkColor = ColorUtils.isColorDark(widget.categoryModel.color!);
    }
    return ScaleTap(
      onPressed: () {
        if (!isEditMode) {
          saleItemsNotifier.setCategoryId(widget.categoryModel.id ?? '');
        }
      },
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ColorUtils.hexToColor(widget.categoryModel.color!),
              borderRadius: BorderRadius.circular(7.5),
              boxShadow: UIUtils.itemShadows,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.categoryModel.name ?? 'No Name',
                  style: AppTheme.normalTextStyle(
                    color: isDarkColor ? white : kBlackColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: Icon(
              FontAwesomeIcons.copy,
              color: isDarkColor ? white : kBlackColor,
            ),
          ),
        ],
      ),
    );
  }
}
