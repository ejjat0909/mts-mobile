import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';

class NoPermissionText extends StatelessWidget {
  final double? width;
  const NoPermissionText({super.key, this.width = double.infinity});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ThemeSnackBar.showSnackBar(
          context,
          'youDontHavePermissionForThisAction'.tr(),
        );
      },
      child: Container(
        width: width,
        height: 20.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: kDisabledText,
        ),
      ),
    );
  }
}
