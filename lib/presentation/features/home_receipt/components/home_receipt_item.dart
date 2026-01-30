import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/device_utils.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';

class HomeReceiptItem extends StatelessWidget {
  final ReceiptModel receiptModel;
  final bool isSelected;
  final Function() press;

  const HomeReceiptItem({
    super.key,
    required this.receiptModel,
    required this.isSelected,
    required this.press,
  });

  @override
  Widget build(BuildContext context) {
    // double width = MediaQuery.of(context).size.width;
    // prints(width);
    // prints("width $width")
    return ScaleTap(
      onPressed: press,
      child: Container(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(color: isSelected ? kItemColor : white),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 10, bottom: 10, left: 10.w),
                      child:
                          DeviceUtils.isTablet(context)
                              ? tabletRow()
                              : phoneRow(),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.5,
                      vertical: 34.h,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: isSelected ? kPrimaryColor : white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tabletRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image(image: getImage(receiptModel.paymentType ?? '')),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                FormatUtils.formatNumber(
                  receiptModel.payableAmount!.toStringAsFixed(2),
                ),
                style: textStyleMedium(color: kBlackColor),
              ),
              Text(
                DateTimeUtils.getDateTimeFormat(receiptModel.createdAt),
                style: textStyleNormal(),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              receiptModel.showUUID!.toString(),
              style: textStyleNormal(color: kTextGray),
            ),
            receiptModel.refundedReceiptId != null
                ? Text(
                  "${'refund'.tr()} ${receiptModel.refundedReceiptId!}",
                  style: textStyleNormal(color: kTextRed),
                )
                : const SizedBox.shrink(),
          ],
        ),
        SizedBox(width: 10.w),
      ],
    );
  }

  Widget phoneRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image(image: getImage(receiptModel.paymentType ?? '')),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                FormatUtils.formatNumber(
                  receiptModel.payableAmount!.toStringAsFixed(2),
                ),
                style: textStyleMedium(color: kBlackColor),
              ),
              Text(
                DateTimeUtils.getDateTimeFormat(receiptModel.createdAt),
                style: textStyleNormal(),
              ),
              Text(
                receiptModel.showUUID!.toString(),
                style: textStyleNormal(color: kTextGray),
              ),
              receiptModel.refundedReceiptId != null
                  ? Text(
                    "${'refund'.tr()} ${receiptModel.refundedReceiptId!}",
                    style: textStyleNormal(color: kTextRed),
                  )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
        // Column(
        //   crossAxisAlignment: CrossAxisAlignment.end,
        //   children: [
        //     Text(
        //       receiptModel.showUUID!.toString(),
        //       style: AppTheme.normalTextStyle(color: kTextGray),
        //     ),
        //     receiptModel.refundedReceiptId != null
        //         ? Text(
        //           "${'refund'.tr()} ${receiptModel.refundedReceiptId!}",
        //           style: AppTheme.normalTextStyle(color: kTextRed),
        //         )
        //         : const SizedBox.shrink(),
        //   ],
        // ),
        SizedBox(width: 10.w),
      ],
    );
  }

  AssetImage getImage(String paymentType) {
    if (paymentType.toLowerCase().contains('card')) {
      return const AssetImage('assets/images/credit_card_blue.png');
    } else if (!paymentType.toLowerCase().contains('cash')) {
      return const AssetImage('assets/images/credit_card_orange.png');
    } else {
      return const AssetImage('assets/images/cash_green.png');
    }
  }
}
