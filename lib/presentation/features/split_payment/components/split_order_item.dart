import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/modifier_option/modifier_option_providers.dart';

class SplitOrderItem extends ConsumerStatefulWidget {
  final Map<String, dynamic> orderData;

  final Function() press;

  const SplitOrderItem({
    super.key,
    required this.orderData,
    required this.press,
  });

  @override
  ConsumerState<SplitOrderItem> createState() => _SplitOrderItemState();
}

class _SplitOrderItemState extends ConsumerState<SplitOrderItem> {
  SaleItemModel saleItemModel = SaleItemModel();
  ItemModel itemModel = ItemModel();
  SaleItemModel usedSaleItemModel = SaleItemModel();
  String allModifierOptionName = '';
  String? variantOptionName;
  Future<Map<String, dynamic>> getOrderData(
    String itemId,
    List<String> modifierOptionIds,
    String? variantOptionId,
  ) async {
    ItemModel? itemModel = await ref
        .read(itemProvider.notifier)
        .getItemModelById(itemId);
    String allModifierOptionName = ref
        .read(modifierOptionProvider.notifier)
        .getModifierOptionNameFromListIds(modifierOptionIds);

    VariantOptionModel? variantOptionModel = ref
        .read(itemProvider.notifier)
        .getVariantOptionModelById(variantOptionId, itemId);

    return {
      'itemModel': itemModel,
      'allModifierOptionName': allModifierOptionName,
      'variantOptionName': variantOptionModel?.name,
    };
  }

  @override
  Widget build(BuildContext context) {
    /// [to get modifier option name] follow this step
    // get sale modifier models from splitPaymentNotifier

    saleItemModel = widget.orderData[DataEnum.saleItemModel];
    itemModel = widget.orderData[DataEnum.itemModel];
    usedSaleItemModel = widget.orderData[DataEnum.usedSaleItemModel];
    allModifierOptionName = widget.orderData[DataEnum.allModifierOptionNames];
    variantOptionName = widget.orderData[DataEnum.variantOptionNames];

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: const BoxDecoration(color: white),
          child: InkWell(
            onTap: widget.press,
            splashColor: kPrimaryLightColor,
            highlightColor: kPrimaryLightColor,
            child:
                itemModel.soldBy == ItemSoldByEnum.item
                    ? soldByItem(
                      saleItemModel,
                      itemModel,
                      variantOptionName,
                      allModifierOptionName,
                    )
                    : soldByMeasurement(
                      saleItemModel,
                      itemModel,
                      variantOptionName,
                      allModifierOptionName,
                    ),
          ),
        ),
      ),
    );
  }

  Widget soldByItem(
    SaleItemModel saleItemModel,
    ItemModel itemModel,
    String? variantOptionName,
    String allModifierOptionName,
  ) {
    String qty = saleItemModel.quantity?.toStringAsFixed(0) ?? '0';
    //String qty = '123456789';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Container(
        //   height: 50.h,
        //   width: 50.w,
        //   decoration: BoxDecoration(
        //     shape: BoxShape.circle,
        //     border: Border.all(
        //       width: 0.9,
        //       color: kBlackColor,
        //     ),
        //   ),
        //   // child: Center(
        //   //   child:
        //   //       Text(widget.saleItemModel.quantity?.toStringAsFixed(0) ?? '0'),
        //   // ),
        //   child: const Center(
        //     child: Text('0123456789012'),
        //   ),
        // ),
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
                qty.length >= 9 ? 'I' : qty,
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
                itemModel.name!,
                style: AppTheme.normalTextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              qty.length >= 9
                  ? Text(
                    'x $qty',
                    style: const TextStyle(color: kTextGray, fontSize: 13),
                  )
                  : const SizedBox.shrink(),
              variantOptionName != null
                  ? Text(
                    variantOptionName,
                    style: const TextStyle(color: kTextGray, fontSize: 13),
                  )
                  : const SizedBox.shrink(),
              allModifierOptionName != ''
                  ? Text(
                    allModifierOptionName,
                    style: const TextStyle(color: kTextGray, fontSize: 13),
                  )
                  : const SizedBox.shrink(),
              saleItemModel.comments!.trim() != ''
                  ? Text(
                    saleItemModel.comments!,
                    style: AppTheme.italicTextStyle(),
                  )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'RM'.tr(args: [getSaleItemPrice(saleItemModel)]),
              style: AppTheme.normalTextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget soldByMeasurement(
    SaleItemModel saleItemModel,
    ItemModel itemModel,
    String? variantOptionName,
    String allModifierOptionName,
  ) {
    return Row(
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
                      itemModel.name!,
                      style: AppTheme.normalTextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    'x ${saleItemModel.quantity!.toStringAsFixed(3)}',
                    style: AppTheme.normalTextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 12,
                      color: kTextGray,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              variantOptionName != null
                  ? Text(
                    variantOptionName,
                    style: const TextStyle(color: kTextGray, fontSize: 13),
                  )
                  : const SizedBox.shrink(),
              allModifierOptionName != ''
                  ? Text(
                    allModifierOptionName,
                    style: const TextStyle(color: kTextGray, fontSize: 13),
                  )
                  : const SizedBox.shrink(),
              saleItemModel.comments!.trim() != ''
                  ? Text(
                    saleItemModel.comments!,
                    style: AppTheme.italicTextStyle(),
                  )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'RM'.tr(args: [getSaleItemPrice(saleItemModel)]),
              style: AppTheme.normalTextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  String getSaleItemPrice(SaleItemModel saleItemModel) {
    double saleItemPrice = saleItemModel.price ?? 0;
    return saleItemPrice.toStringAsFixed(2);
  }

  // String? getTax(SaleItemModel saleItemModel) {
  //   double? taxPercent =
  //       TaxBloc.getRateById(context, saleItemModel.taxId!) * 100;

  //   if (taxPercent == taxPercent.roundToDouble()) {
  //     return '${taxPercent.toStringAsFixed(0)}%';
  //   } else {
  //     return '${taxPercent.toStringAsFixed(2)}%';
  //   }
  // }
}
