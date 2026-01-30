import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/data/models/modifier/modifier_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';

class InitialReceiptOrderItem extends StatefulWidget {
  final ReceiptItemModel receiptItemModel;

  const InitialReceiptOrderItem({super.key, required this.receiptItemModel});

  @override
  State<InitialReceiptOrderItem> createState() =>
      _InitialReceiptOrderItemState();
}

class _InitialReceiptOrderItemState extends State<InitialReceiptOrderItem> {
  // for modifiers
  List<ModifierModel> modifiers = [];
  List<dynamic> modifierJson = [];
  Map<String, List<ModifierOptionModel>> groupedModifiers = {};
  List<Widget> modifierWidgets = [];

  // for variants
  VariantOptionModel variantOption = VariantOptionModel();
  List<Widget> variantWidgets = [];

  @override
  void initState() {
    getListModifiers();
    getVariantOption();
    super.initState();
  }

  void getVariantOption() {
    if (widget.receiptItemModel.variants != null) {
      dynamic variantOptionJson = jsonDecode(widget.receiptItemModel.variants!);
      variantOption = VariantOptionModel.fromJson(variantOptionJson);
    }

    if (variantOption.id != null) {
      variantWidgets.add(
        Row(
          children: [
            Expanded(
              child: Text(
                variantOption.name ?? '',
                style: AppTheme.italicTextStyle(),
              ),
            ),
          ],
        ),
      );
    }
  }

  void getListModifiers() {
    modifierJson = jsonDecode(widget.receiptItemModel.modifiers ?? '[]');
    if (modifierJson.isNotEmpty) {
      modifiers = List.generate(
        modifierJson.length,
        (index) => ModifierModel.fromJsonReceiptItem(modifierJson[index]),
      );

      for (ModifierModel modifier in modifiers) {
        if (modifier.id != null) {
          groupedModifiers.putIfAbsent(modifier.id!, () => []);
          groupedModifiers[modifier.id!]!.addAll(
            modifier.modifierOptions ?? [],
          );
        }
      }

      for (String modifierId in groupedModifiers.keys) {
        ModifierModel? modifier = modifiers.firstWhere(
          (element) => element.id == modifierId,
        );
        String modifierOptionText = groupedModifiers[modifierId]!
            .map((e) => e.name)
            .join(', ');

        // Add the modifier widget to the list
        modifierWidgets.add(
          Row(
            children: [
              Expanded(
                child: Text(
                  '${modifier.name ?? ""}: $modifierOptionText',
                  style: AppTheme.italicTextStyle(),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: const BoxDecoration(color: white),
          child:
              widget.receiptItemModel.soldBy != null
                  ? (widget.receiptItemModel.soldBy == ItemSoldByEnum.item
                      ? soldByItem()
                      : soldByMeasurement())
                  : soldByItem(),
        ),
      ),
    );
  }

  Widget soldByItem() {
    // String qty = '12345';
    String qty = widget.receiptItemModel.quantity?.toStringAsFixed(0) ?? '0';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 0.9),
            ),
            child: CircleAvatar(
              backgroundColor: kWhiteColor,
              radius: 22.5,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Text(
                  qty.length >= 5 ? 'I' : qty,
                  style: AppTheme.normalTextStyle(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiptItemModel.name ?? 'No Receipt Item Name',
                  style: AppTheme.normalTextStyle(),
                  overflow: TextOverflow.ellipsis,
                ),
                qty.length >= 5
                    ? Text(
                      'x $qty',
                      style: const TextStyle(color: kTextGray, fontSize: 13),
                    )
                    : const SizedBox.shrink(),
                ...variantWidgets,
                ...modifierWidgets,
                widget.receiptItemModel.comment != ''
                    ? Text(
                      widget.receiptItemModel.comment ?? '',
                      style: AppTheme.italicTextStyle(),
                    )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('RM'.tr(args: [getSaleItemPrice()])),
              // Text("${getTax()}", style: AppTheme.mediumTextStyle()),
            ],
          ),
        ],
      ),
    );
  }

  Widget soldByMeasurement() {
    // String qty = '12345';
    String qty =
        widget.receiptItemModel.quantity?.toStringAsFixed(3) ?? '0.000';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 0.9),
            ),
            child: CircleAvatar(
              backgroundColor: kWhiteColor,
              radius: 22.5,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Text('M', style: AppTheme.normalTextStyle()),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: Text(
                        widget.receiptItemModel.name ?? 'No Receipt Item Name',
                        style: AppTheme.normalTextStyle(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'x $qty',
                      style: AppTheme.normalTextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 12,
                        color: kTextGray,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                ...variantWidgets,
                ...modifierWidgets,
                widget.receiptItemModel.comment != ''
                    ? Text(
                      widget.receiptItemModel.comment ?? '',
                      style: AppTheme.italicTextStyle(),
                    )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('RM'.tr(args: [getSaleItemPrice()])),
              // Text("${getTax()}", style: AppTheme.mediumTextStyle()),
            ],
          ),
        ],
      ),
    );
  }

  String getSaleItemPrice() {
    double total = 0;
    double itemPrice = widget.receiptItemModel.grossAmount ?? 0;

    total = itemPrice;

    return FormatUtils.formatNumber(total.toStringAsFixed(2));
  }
}
