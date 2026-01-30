import 'package:flutter/material.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/color_utils.dart';
import 'package:mts/data/models/category/category_model.dart';

class CategoryListTile extends StatefulWidget {
  final CategoryModel categoryModel;
  final Function() onTap;

  const CategoryListTile({
    super.key,
    required this.categoryModel,
    required this.onTap,
  });

  @override
  State<CategoryListTile> createState() => _CategoryListTileState();
}

class _CategoryListTileState extends State<CategoryListTile> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: const BoxDecoration(color: white),
          child: InkWell(
            onTap: widget.onTap,
            splashColor: kPrimaryLightColor,
            highlightColor: kPrimaryLightColor,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorUtils.hexToColor(widget.categoryModel.color!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${widget.categoryModel.name}',
                      style: AppTheme.normalTextStyle(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
