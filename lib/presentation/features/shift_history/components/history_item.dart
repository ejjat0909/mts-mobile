import 'package:flutter/material.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/data/models/shift/shift_model.dart';

class HistoryItem extends StatelessWidget {
  final ShiftModel shiftModel;
  final bool isSelected;
  final Function() press;

  const HistoryItem({
    super.key,
    required this.shiftModel,
    required this.isSelected,
    required this.press,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onPressed: press,
      child: Container(
        child: Column(
          children: [
            //SizedBox(height: 5.h),
            Padding(
              padding: EdgeInsets.only(
                left: 10.w,
                right: 10.w,

                //top: 10.h,
              ),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isSelected ? kItemColor : white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getRangeDate(),
                            style: AppTheme.mediumTextStyle(color: kTextGreen),
                          ),
                          Text(
                            getRangeTime(),
                            style: AppTheme.normalTextStyle(),
                          ),
                        ],
                      ),
                    ),
                    // isSynced property removed
                    Text(''),
                  ],
                ),
              ),
            ),
            const Divider(thickness: 1),
          ],
        ),
      ),
    );
  }

  String getRangeTime() {
    String timeOpen = DateTimeUtils.getTimeFormat(shiftModel.createdAt);
    String timeClose = DateTimeUtils.getTimeFormat(shiftModel.closedAt);
    return '$timeOpen - $timeClose';
  }

  String getRangeDate() {
    String dateOpen = DateTimeUtils.getDateFormat(shiftModel.createdAt);
    String dateClose = DateTimeUtils.getDateFormat(shiftModel.closedAt);
    return dateOpen == dateClose ? dateOpen : '$dateOpen - $dateClose';
  }
}
