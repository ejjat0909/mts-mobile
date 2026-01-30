import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/modifier/modifier_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';
import 'package:mts/presentation/common/widgets/space.dart';

// LEFT SIDE
class CancelledRefundOrderItem extends StatefulWidget {
  final ReceiptItemModel receiptItemModel;
  final Function() press;

  const CancelledRefundOrderItem({
    super.key,
    required this.receiptItemModel,
    required this.press,
  });

  @override
  State<CancelledRefundOrderItem> createState() =>
      _CancelledRefundOrderItemState();
}

class _CancelledRefundOrderItemState extends State<CancelledRefundOrderItem> {
  // for modifiers
  List<ModifierModel> modifiers = [];
  List<dynamic> modifierJson = [];
  Map<String, List<ModifierOptionModel>> groupedModifiers = {};

  // for variants
  VariantOptionModel variantOption = VariantOptionModel();

  @override
  void initState() {
    prints('initt cancelled refund item');

    super.initState();
  }

  String getVariantOption() {
    if (widget.receiptItemModel.variants != null) {
      dynamic variantOptionJson = jsonDecode(widget.receiptItemModel.variants!);
      variantOption = VariantOptionModel.fromJson(variantOptionJson);
      return variantOption.name ?? '';
    }
    return '';
  }

  List<String> getListModifiers() {
    List<String> listModifiers = [];
    modifierJson = jsonDecode(widget.receiptItemModel.modifiers ?? '[]');
    // clear for avoid duplication
    modifiers.clear();
    groupedModifiers.clear();
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
        String modifierOptionText = '';
        if (modifierOptionText != '') {
          modifierOptionText = '';
        }
        modifierOptionText = groupedModifiers[modifierId]!
            .map((e) => e.name)
            .join(', ');
        prints(modifierOptionText);

        listModifiers.add('${modifier.name ?? ""}: $modifierOptionText');
      }
    }
    return listModifiers;
  }

  @override
  Widget build(BuildContext context) {
    List<String> listAllModifiers = getListModifiers();
    String variantOptionName = getVariantOption();
    double quantityInDouble = widget.receiptItemModel.quantity ?? 0;

    double totalRefunded = widget.receiptItemModel.totalRefunded;

    prints('ID RECEIPT ITEM ${widget.receiptItemModel.id}');
    prints('NAME ${widget.receiptItemModel.name}');

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: const BoxDecoration(color: white),
          child:
              widget.receiptItemModel.soldBy != null
                  ? (widget.receiptItemModel.soldBy == ItemSoldByEnum.item
                      ? soldByItem(
                        quantityInDouble,
                        totalRefunded,
                        variantOptionName,
                        listAllModifiers,
                      )
                      : soldByMeasurement(
                        quantityInDouble,
                        totalRefunded,
                        variantOptionName,
                        listAllModifiers,
                      ))
                  : soldByItem(
                    quantityInDouble,
                    totalRefunded,
                    variantOptionName,
                    listAllModifiers,
                  ),
        ),
      ),
    );
  }

  Widget soldByItem(
    double quantityInDouble,
    double totalRefunded,
    String variantName,
    List<String> listMOD,
  ) {
    String qty = widget.receiptItemModel.quantity?.toStringAsFixed(0) ?? '0';
    return InkWell(
      onTap:
          quantityInDouble == totalRefunded
              ? null
              : () {
                widget.press();
              },
      splashColor: kPrimaryLightColor,
      highlightColor: kPrimaryLightColor,
      child: Container(
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
                    style: textStyleNormal(
                      fontWeight: FontWeight.bold,
                      color:
                          quantityInDouble == totalRefunded
                              ? kTextGray
                              : kBlackColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  qty.length >= 5
                      ? Text(
                        'x $qty',
                        style: const TextStyle(color: kTextGray, fontSize: 13),
                      )
                      : const SizedBox.shrink(),
                  variantName != ''
                      ? Text(
                        variantName,
                        style: const TextStyle(color: kTextGray, fontSize: 13),
                      )
                      : const SizedBox.shrink(),
                  ...listMOD.map((e) {
                    return Text(
                      e,
                      style: const TextStyle(color: kTextGray, fontSize: 13),
                    );
                  }),
                  Visibility(
                    visible: widget.receiptItemModel.totalRefunded != 0,
                    child: Space(5.h),
                  ),
                  Visibility(
                    visible: widget.receiptItemModel.totalRefunded > 0,
                    child: Text(
                      widget.receiptItemModel.soldBy == ItemSoldByEnum.item
                          ? "${"refunded".tr()} x ${widget.receiptItemModel.totalRefunded.toStringAsFixed(0)}"
                          : "${"refunded".tr()} x ${widget.receiptItemModel.totalRefunded.toStringAsFixed(3)}",
                      style: textStyleMedium(color: kTextRed),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'RM'.tr(args: [getSaleItemPrice()]),
                  style: AppTheme.normalTextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        quantityInDouble == totalRefunded
                            ? kTextGray
                            : kBlackColor,
                  ),
                ),
                // Text("${getTax()}", style: AppTheme.mediumTextStyle()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget soldByMeasurement(
    double quantityInDouble,
    double totalRefunded,
    String variantName,
    List<String> listMOD,
  ) {
    String qty =
        widget.receiptItemModel.quantity?.toStringAsFixed(3) ?? '0.000';
    return InkWell(
      onTap: quantityInDouble == totalRefunded ? null : widget.press,
      splashColor: kPrimaryLightColor,
      highlightColor: kPrimaryLightColor,
      child: Container(
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
                          widget.receiptItemModel.name ??
                              'No Receipt Item Name',
                          style: AppTheme.normalTextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                quantityInDouble == totalRefunded
                                    ? kTextGray
                                    : kBlackColor,
                          ),
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
                  variantName != ''
                      ? Text(
                        variantName,
                        style: const TextStyle(color: kTextGray, fontSize: 13),
                      )
                      : const SizedBox.shrink(),
                  ...listMOD.map((e) {
                    return Text(
                      e,
                      style: const TextStyle(color: kTextGray, fontSize: 13),
                    );
                  }),
                  Visibility(
                    visible: widget.receiptItemModel.totalRefunded != 0,
                    child: Space(5.h),
                  ),
                  Visibility(
                    visible: widget.receiptItemModel.totalRefunded != 0,
                    child: Text(
                      "${"refunded".tr()} x ${widget.receiptItemModel.totalRefunded.toStringAsFixed(3)}",
                      style: AppTheme.mediumTextStyle(color: kTextRed),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 5.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'RM'.tr(args: [getSaleItemPrice()]),
                  style: AppTheme.normalTextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        quantityInDouble == totalRefunded
                            ? kTextGray
                            : kBlackColor,
                  ),
                ),
                // Text("${getTax()}", style: AppTheme.mediumTextStyle()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String getSaleItemPrice() {
    double total = 0;
    double itemPrice = widget.receiptItemModel.price!;

    total = itemPrice;

    return FormatUtils.formatNumber(total.toStringAsFixed(2));
  }

  // String? getTax() {
  //   double? taxPercent =
  //       TaxModel.getRateById(widget.receiptItemModel.taxId!)! * 100;

  //   if (taxPercent == taxPercent.roundToDouble()) {
  //     return "${taxPercent.toStringAsFixed(0)}%";
  //   } else {
  //     return "${taxPercent.toStringAsFixed(2)}%";
  //   }
  // }
}
