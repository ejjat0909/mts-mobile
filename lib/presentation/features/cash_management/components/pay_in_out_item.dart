import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/cash_management_type_enum.dart';
import 'package:mts/data/models/cash_management/cash_management_model.dart';

class PayInOutItem extends StatelessWidget {
  final CashManagementModel cmm;

  const PayInOutItem({super.key, required this.cmm});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          //SizedBox(height: 5.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      cmm.type == CashManagementTypeEnum.payIn
                          ? Text(
                            '+ ${"RM".tr(args: [cmm.amount?.toStringAsFixed(2) ?? "0.00"])}',
                            style: AppTheme.mediumTextStyle(color: kTextGreen),
                          )
                          : Text(
                            '- ${"RM".tr(args: [cmm.amount?.toStringAsFixed(2) ?? "0.00"])}',
                            style: AppTheme.mediumTextStyle(color: kTextRed),
                          ),
                      Text(
                        cmm.comment != '' ? cmm.comment! : 'No comment',
                        style: AppTheme.normalTextStyle(),
                      ),
                    ],
                  ),
                ),
                Text(
                  cmm.createdAt != null
                      ? DateFormat('h:mm a', 'en_US').format(cmm.createdAt!)
                      : 'No time available',
                ),
              ],
            ),
          ),
          const Divider(thickness: 1, height: 0),
        ],
      ),
    );
  }
}
