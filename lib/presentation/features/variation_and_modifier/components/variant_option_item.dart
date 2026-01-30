import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/data/models/inventory/inventory_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/common/widgets/text_with_badge.dart';

class VariantOptionItem extends StatefulWidget {
  final bool isSelected;
  final bool isSelectedCustom;
  final Function() onPressed;
  final VariantOptionModel variantOptionModel;
  final InventoryModel inventoryModel;
  final ItemModel itemModel;
  final bool isAtTheTop;

  const VariantOptionItem({
    super.key,
    required this.variantOptionModel,
    required this.isSelected,
    required this.onPressed,
    required this.isAtTheTop,
    required this.isSelectedCustom,
    required this.inventoryModel,
    required this.itemModel,
  });

  @override
  State<VariantOptionItem> createState() => _VariantOptionItemState();
}

class _VariantOptionItemState extends State<VariantOptionItem>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onPressed: widget.onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        height: 70.h,
        decoration: BoxDecoration(
          color: getBgColor(),
          borderRadius: BorderRadius.circular(7.5),
          border: Border.all(
            width: widget.isSelected ? 2 : 1,
            color: getColorBorder(),
          ),
        ),
        child: Row(
          children: [
            if (widget.inventoryModel.id != null &&
                widget.inventoryModel.currentQuantity != null) ...[
              TextWithBadge(
                text: getInventoryQty(),
                backgroundColor: getColorBackground(getInventoryQty()),
                textColor: getTextColor(getInventoryQty()),
              ),
              5.widthBox,
            ],

            Expanded(
              child: Text(
                widget.variantOptionModel.name!,
                style: AppTheme.normalTextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            widget.variantOptionModel.price != null
                ? Text(
                  'RM'.tr(
                    args: [widget.variantOptionModel.price!.toStringAsFixed(2)],
                  ),
                  style: AppTheme.mediumTextStyle(color: kBlackColor),
                )
                : Text(
                  'setPrice'.tr(),
                  style: AppTheme.mediumTextStyle(color: kBlackColor),
                ),
          ],
        ),
      ),
    );
  }

  Color getBgColor() {
    if (widget.variantOptionModel.price == null) {
      // check is selected custom
      if (widget.isSelectedCustom) {
        return kBgYellow;
      }
    }

    if (widget.isSelected) {
      return kPrimaryColor.withValues(alpha: 0.2);
    } else {
      return white;
    }
  }

  Color getColorBorder() {
    if (widget.isAtTheTop) {
      return Colors.red;
    } else {
      if (widget.variantOptionModel.price == null) {
        // check is selected custom
        if (widget.isSelectedCustom) {
          return kTextYellow;
        }
      }

      if (widget.isSelected) {
        return kPrimaryColor;
      } else {
        return kTextGray;
      }
    }
  }

  String getInventoryQty() {
    if (widget.inventoryModel.id != null &&
        widget.inventoryModel.currentQuantity != null) {
      if (widget.itemModel.soldBy == ItemSoldByEnum.item) {
        return widget.inventoryModel.currentQuantity?.toStringAsFixed(0) ?? "0";
      } else {
        return widget.inventoryModel.currentQuantity?.toStringAsFixed(3) ??
            "0.000";
      }
    } else {}
    return '';
  }

  Color getColorBackground(String inventoryQty) {
    double? qty = double.tryParse(inventoryQty);
    if (qty != null) {
      bool isPositive = qty > 0;
      if (isPositive) {
        return kBadgeBgGreen;
      } else {
        return kBadgeBgRed;
      }
    } else {
      return Colors.transparent;
    }
  }

  Color getTextColor(String inventoryQty) {
    double? qty = double.tryParse(inventoryQty);
    if (qty != null) {
      bool isPositive = qty > 0;
      if (isPositive) {
        return kBadgeTextGreen;
      } else {
        return kBadgeTextRed;
      }
    } else {
      return Colors.transparent;
    }
  }
}
