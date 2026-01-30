import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/data/models/inventory/inventory_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/presentation/common/widgets/text_with_badge.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class ItemListTile extends StatefulWidget {
  final ItemModel itemModel;
  final InventoryModel inventoryModel;
  final Function() onPressed;

  const ItemListTile({
    super.key,
    required this.itemModel,
    required this.onPressed,
    required this.inventoryModel,
  });

  @override
  State<ItemListTile> createState() => _ItemListTileState();
}

class _ItemListTileState extends State<ItemListTile> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: const BoxDecoration(color: white),
          child: InkWell(
            onTap: widget.onPressed,
            splashColor: kPrimaryLightColor,
            highlightColor: kPrimaryLightColor,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  10.widthBox,
                  Visibility(
                    visible:
                        widget.inventoryModel.id != null ||
                        widget.itemModel.variantOptionJson != null,
                    child: getBadgePrefix(),
                  ),
                  Visibility(
                    visible:
                        widget.inventoryModel.id != null ||
                        widget.itemModel.variantOptionJson != null,
                    child: 10.widthBox,
                  ),
                  Expanded(
                    child: Text(
                      '${widget.itemModel.name}',
                      style: textStyleNormal(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'RM'.tr(
                      args: [
                        (widget.itemModel.price?.toStringAsFixed(2) ??
                            0.toStringAsFixed(2)),
                      ],
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

  TextWithBadge getBadgePrefix() {
    if (widget.itemModel.variantOptionJson != null) {
      return TextWithBadge(
        text: null,
        isIcon: true,
        icon: FontAwesomeIcons.layerGroup,
        textColor: kBadgeTextYellow,
        backgroundColor: kBadgeBgYellow,
      );
    } else {
      return TextWithBadge(
        text: getInventoryQty(),
        backgroundColor: getColorBackground(getInventoryQty()),
        textColor: getTextColor(getInventoryQty()),
      );
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
