import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/presentation/common/dialogs/theme_spinner.dart';

class LoadingDialog extends StatelessWidget {
  static void show(BuildContext context, {Key? key, String? text}) =>
      showDialog<void>(
        context: context,
        useRootNavigator: false,
        barrierDismissible: false,
        builder: (_) => LoadingDialog(key: key, text: text ?? 'loading'.tr()),
      ).then((_) => FocusScope.of(context).requestFocus(FocusNode()));

  static void hide(BuildContext context) => NavigationUtils.pop(context);
  final String text;

  // this is for loading indicator
  const LoadingDialog({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Center(
        child: Container(
          height: 100.w,
          width: 100.w,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          // padding: EdgeInsets.all(50),
          // child: Column(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   crossAxisAlignment: CrossAxisAlignment.center,
          //   children: [
          //     ThemeSpinner.spinner(),
          //     // SizedBox(
          //     //   height: 20,
          //     // ),
          //     // Text(
          //     //   text,
          //     //   style: TextStyle(fontSize: 16),
          //     // ),
          //   ],
          // ),
          child: ThemeSpinner.spinner(),
        ),
      ),
    );
  }
}
