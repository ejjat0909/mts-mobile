import 'package:flutter/material.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';

class NumberButtonDialogue extends StatelessWidget {
  final String? number;
  final bool isOkButton;
  final Function()? press;
  final Function()? onLongPress;
  final bool isEnabled;

  const NumberButtonDialogue({
    super.key,
    this.number,
    this.press,
    this.isOkButton = false,
    this.onLongPress,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onPressed: press,
      onLongPress: onLongPress,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 21.65.h),
        decoration: BoxDecoration(
          color:
              isOkButton
                  ? (isEnabled
                      ? canvasColor
                      : canvasColor.withValues(alpha: 0.33))
                  : number == null
                  ? kTextRed
                  : white,
          borderRadius: BorderRadius.circular(10.sp),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 20),
              blurRadius: 25,
              spreadRadius: -5,
              color: Colors.black.withValues(alpha: 0.07),
            ),
            BoxShadow(
              offset: const Offset(0, 10),
              blurRadius: 10,
              spreadRadius: -5,
              color: Colors.black.withValues(alpha: 0.02),
            ),
          ],
        ),
        child: Center(
          child:
              isOkButton
                  ? Text(
                    'OK',
                    style: AppTheme.normalTextStyle(
                      color: white,
                      fontSize: 30.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : number == null
                  ? Icon(Icons.backspace_outlined, color: white, size: 40.sp)
                  : Text(
                    number.toString(),
                    style: AppTheme.normalTextStyle(
                      color: kTextGray,
                      fontSize: 30.sp,
                    ),
                  ),
        ),
      ),
    );
  }
}
