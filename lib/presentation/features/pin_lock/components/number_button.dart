import 'package:flutter/material.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';

class NumberButton extends StatelessWidget {
  final int? number;
  final Function()? press;

  const NumberButton({super.key, this.number, this.press});

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onPressed: press,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 25.h),
        decoration: BoxDecoration(
          color: Colors.white,
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
              number == null
                  ? Icon(
                    Icons.backspace_outlined,
                    color: kTextGray,
                    size: 40.sp,
                  )
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
