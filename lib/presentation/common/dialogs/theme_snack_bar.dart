import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/log_utils.dart';

class ThemeSnackBar {
  ThemeSnackBar();

  static SnackBar getSnackBar(String text) {
    return SnackBar(
      content: Row(
        children: [
          Image.asset('assets/images/playstore.png', height: 30, width: 30),
          SizedBox(width: 10.w),
          Flexible(
            child: Text(text, style: AppTheme.normalTextStyle(color: white)),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
    );
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
  showSnackBar(BuildContext context, String text) {
    try {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      return ScaffoldMessenger.of(
        context,
      ).showSnackBar(ThemeSnackBar.getSnackBar(text));
    } catch (e) {
      // Context might be disposed or invalid, log and return null
      prints('⚠️ Failed to show snackbar (context disposed): $e');
      return null;
    }
  }
}
